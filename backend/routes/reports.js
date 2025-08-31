const express = require('express');
const { body, query, param } = require('express-validator');
const { PrismaClient } = require('@prisma/client');
const validate = require('../middleware/validation');
const { requireAdmin, authenticateToken } = require('../middleware/auth');

const router = express.Router();
const prisma = new PrismaClient();

// Função para gerar prefixo automático do relatório
async function generateReportPrefix(terminalId, clientId, endDateTime) {
  try {
    // 1. Buscar o terminal para obter o prefixo
    const terminal = await prisma.terminal.findUnique({
      where: { id: terminalId },
      select: { prefix: true, name: true }
    });

    if (!terminal) {
      throw new Error('Terminal não encontrado');
    }

    if (!terminal.prefix) {
      throw new Error(`Prefixo não configurado para o terminal ${terminal.name}`);
    }

    const basePrefix = terminal.prefix;

    // 2. Obter a data de término e calcular os dígitos finais
    const endDate = new Date(endDateTime);
    const day = endDate.getDate();
    const dayDouble = (day * 2).toString().padStart(2, '0'); // Garante 2 dígitos

    // 3. Calcular o sequencial do dia para o cliente no mesmo terminal
    const startOfDay = new Date(endDate);
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(endDate);
    endOfDay.setHours(23, 59, 59, 999);

    // Contar relatórios do cliente no mesmo terminal no mesmo dia
    const dailyReportsCount = await prisma.report.count({
      where: {
        clientId: clientId,
        terminalId: terminalId,
        endDateTime: {
          gte: startOfDay,
          lte: endOfDay
        }
      }
    });

    const dailySequential = dailyReportsCount + 1; // Próximo número sequencial

    // 4. Montar o prefixo final: AAA-XYZ (onde Z é sequencial + dígitos do dia)
    const prefix = `${basePrefix}${dailySequential}${dayDouble}`;
    

    
    return prefix;
  } catch (error) {
    console.error('Erro ao gerar prefixo:', error);
    throw error;
  }
}

// Validações
const createReportValidation = [
  body('prefix')
    .optional()
    .trim()
    .custom((value) => {
      // Permite string vazia (será gerada automaticamente) ou string entre 1-50 caracteres
      if (value === '' || value === undefined || value === null) return true;
      return value.length >= 1 && value.length <= 50;
    })
    .withMessage('Prefixo deve estar vazio (para geração automática) ou ter entre 1 e 50 caracteres'),
  body('terminalId')
    .optional({ nullable: true })
    .custom((value) => {
      if (value === null || value === undefined) return true;
      return Number.isInteger(value) && value > 0;
    })
    .withMessage('ID do terminal deve ser um número inteiro positivo ou null'),
  body('productIds')
    .optional()
    .isArray()
    .withMessage('productIds deve ser um array')
    .custom((value) => {
      if (!value || value.length === 0) return true;
      return value.every(id => Number.isInteger(id) && id > 0);
    })
    .withMessage('Todos os IDs de produtos devem ser números inteiros positivos'),
  body('supplierIds')
    .optional()
    .isArray()
    .withMessage('supplierIds deve ser um array')
    .custom((value) => {
      if (!value || value.length === 0) return true;
      return value.every(id => Number.isInteger(id) && id > 0);
    })
    .withMessage('Todos os IDs de fornecedores devem ser números inteiros positivos'),
  body('clientId')
    .optional({ nullable: true })
    .custom((value) => {
      if (value === null || value === undefined) return true;
      return Number.isInteger(value) && value > 0;
    })
    .withMessage('ID do cliente deve ser um número inteiro positivo ou null'),
  body('employeeUserId')
    .optional({ nullable: true })
    .custom((value) => {
      if (value === null || value === undefined) return true;
      return Number.isInteger(value) && value > 0;
    })
    .withMessage('ID do colaborador deve ser um número inteiro positivo ou null'),
  body('startDateTime')
    .notEmpty()
    .withMessage('Data/hora de início é obrigatória')
    .isISO8601()
    .withMessage('Data/hora de início deve estar no formato ISO8601'),
  body('endDateTime')
    .notEmpty()
    .withMessage('Data/hora de término é obrigatória')
    .isISO8601()
    .withMessage('Data/hora de término deve estar no formato ISO8601')
    .custom((endDateTime, { req }) => {
      const startDateTime = req.body.startDateTime;
      if (startDateTime && new Date(endDateTime) <= new Date(startDateTime)) {
        throw new Error('Data/hora de término deve ser posterior à de início');
      }
      return true;
    }),
  body('arrivalDateTime')
    .optional()
    .isISO8601()
    .withMessage('Data/hora de chegada deve estar no formato ISO8601'),
  body('departureDateTime')
    .optional()
    .isISO8601()
    .withMessage('Data/hora de saída deve estar no formato ISO8601'),
  body('startTime')
    .optional()
    .isISO8601()
    .withMessage('Horário de início deve estar no formato ISO8601'),
  body('endTime')
    .optional()
    .isISO8601()
    .withMessage('Horário de término deve estar no formato ISO8601'),
  body('status')
    .optional()
    .isInt({ min: 0, max: 2 })
    .withMessage('Status deve ser 0 (rascunho), 1 (em revisão) ou 2 (concluído)'),
  body('wagonType')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('Tipo de vagão deve ter no máximo 100 caracteres'),
  body('hasContamination')
    .optional()
    .isBoolean()
    .withMessage('Campo de contaminação deve ser boolean'),
  body('contaminationDescription')
    .optional()
    .trim()
    .isLength({ max: 1000 })
    .withMessage('Descrição da contaminação deve ter no máximo 1000 caracteres'),
  body('homogeneousMaterial')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('Material homogêneo deve ter no máximo 100 caracteres'),
  body('visibleMoisture')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('Umidade visível deve ter no máximo 100 caracteres'),
  body('rainOccurred')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('Ocorrência de chuva deve ter no máximo 100 caracteres'),
  body('supplierAccompanied')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('Acompanhamento do fornecedor deve ter no máximo 100 caracteres'),
  body('observations')
    .optional()
    .trim()
    .isLength({ max: 2000 })
    .withMessage('Observações devem ter no máximo 2000 caracteres')
];

const updateReportValidation = [
  param('id')
    .notEmpty()
    .withMessage('ID do relatório é obrigatório')
    .isUUID()
    .withMessage('ID do relatório deve ser um UUID válido'),
  ...createReportValidation.map(validation => validation.optional())
];

const listReportsValidation = [
  query('page')
    .optional()
    .isInt({ min: 1 })
    .withMessage('Página deve ser um número inteiro positivo'),
  query('limit')
    .optional()
    .isInt({ min: 1, max: 100 })
    .withMessage('Limite deve ser um número entre 1 e 100'),
  query('status')
    .optional()
    .isInt({ min: 0, max: 2 })
    .withMessage('Status deve ser 0 (rascunho), 1 (em revisão) ou 2 (concluído)'),
  query('terminalId')
    .optional()
    .isInt({ min: 1 })
    .withMessage('ID do terminal deve ser um número inteiro positivo'),
  query('productId')
    .optional()
    .isInt({ min: 1 })
    .withMessage('ID do produto deve ser um número inteiro positivo'),
  query('startDateTime')
    .optional()
    .isISO8601()
    .withMessage('Data de início deve estar no formato ISO8601'),
  query('endDateTime')
    .optional()
    .isISO8601()
    .withMessage('Data de término deve estar no formato ISO8601')
];

// GET /api/reports - Listar relatórios
router.get('/', listReportsValidation, validate, async (req, res) => {
  try {
    const {
      page = 1,
      limit = 20,
      status,
      terminalId,
      productId,
      startDateTime,
      endDateTime
    } = req.query;

    const skip = (parseInt(page) - 1) * parseInt(limit);

    // Filtros
    const where = {};

    // Se não for admin, só mostra relatórios do próprio usuário
    if (req.user.role !== 'ADMIN') {
      where.userId = req.user.id;
    }

    if (status !== undefined) {
      where.status = parseInt(status);
    }

    if (terminalId) {
      where.terminalId = parseInt(terminalId);
    }

    if (productId) {
      where.productId = parseInt(productId);
    }

    if (startDateTime || endDateTime) {
      where.startDateTime = {};
      if (startDateTime) {
        where.startDateTime.gte = new Date(startDateTime);
      }
      if (endDateTime) {
        where.startDateTime.lte = new Date(endDateTime);
      }
    }

    // Buscar relatórios
    const [reports, total] = await Promise.all([
      prisma.report.findMany({
        where,
        skip,
        take: parseInt(limit),
        orderBy: { createdAt: 'desc' },
        include: {
          terminal: {
            select: { id: true, name: true, code: true }
          },
          client: {
            select: { id: true, name: true, contact: true }
          },
          user: {
            select: { id: true, name: true, username: true, email: true, role: true }
          }
        }
      }),
      prisma.report.count({ where })
    ]);

    const totalPages = Math.ceil(total / parseInt(limit));

    // Buscar produtos e fornecedores para cada relatório
    const reportsWithDetails = await Promise.all(reports.map(async (report) => {
      const products = report.productIds && report.productIds.length > 0 
        ? await prisma.product.findMany({
            where: { id: { in: report.productIds } },
            select: { id: true, name: true, code: true, description: true, category: true }
          })
        : [];

      const suppliers = report.supplierIds && report.supplierIds.length > 0 
        ? await prisma.supplier.findMany({
            where: { id: { in: report.supplierIds } },
            select: { id: true, name: true, code: true, contact: true, email: true, phone: true }
          })
        : [];

      return {
        ...report,
        products,
        suppliers
      };
    }));

    res.json({
      success: true,
      data: reportsWithDetails,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        totalPages,
        hasNext: parseInt(page) < totalPages,
        hasPrev: parseInt(page) > 1
      }
    });

  } catch (error) {
    console.error('Erro ao listar relatórios:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// GET /api/reports/products-by-suppliers - Buscar produtos por fornecedores
router.get('/products-by-suppliers', authenticateToken, async (req, res) => {
  try {
    const { supplierIds } = req.query;
    
    if (!supplierIds) {
      return res.json({
        success: true,
        data: []
      });
    }

    // Converter string de IDs para array de números
    const supplierIdArray = supplierIds.split(',').map(id => parseInt(id)).filter(id => !isNaN(id));
    
    if (supplierIdArray.length === 0) {
      return res.json({
        success: true,
        data: []
      });
    }

    // Buscar produtos dos fornecedores selecionados
    const products = await prisma.product.findMany({
      where: {
        suppliers: {
          some: {
            supplierId: { in: supplierIdArray }
          }
        },
        active: true
      },
      include: {
        suppliers: {
          include: {
            supplier: {
              select: { id: true, name: true }
            }
          },
          where: {
            supplierId: { in: supplierIdArray }
          }
        }
      },
      orderBy: { name: 'asc' }
    });

    res.json({
      success: true,
      data: products
    });

  } catch (error) {
    console.error('Erro ao buscar produtos por fornecedores:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// GET /api/reports/:id - Buscar relatório específico
router.get('/:id', [
  param('id')
    .notEmpty()
    .withMessage('ID do relatório é obrigatório')
    .isUUID()
    .withMessage('ID do relatório deve ser um UUID válido')
], validate, async (req, res) => {
  try {
    const { id } = req.params;

    // Construir condição where baseada na role do usuário
    const whereCondition = { id };
    
    // Se não for admin, adicionar filtro por userId
    if (req.user.role !== 'ADMIN') {
      whereCondition.userId = req.user.id;
    }

    const report = await prisma.report.findFirst({
      where: whereCondition,
      include: {
        terminal: {
          select: { id: true, name: true, code: true, location: true }
        },
        client: {
          select: { id: true, name: true, contact: true, emails: true }
        },
        user: {
          select: { id: true, name: true, username: true, email: true, role: true }
        }
      }
    });

    if (!report) {
      return res.status(404).json({
        success: false,
        message: 'Relatório não encontrado'
      });
    }

    // Buscar produtos e fornecedores do relatório
    const products = report.productIds && report.productIds.length > 0 
      ? await prisma.product.findMany({
          where: { id: { in: report.productIds } },
          select: { id: true, name: true, code: true, description: true, category: true }
        })
      : [];

    const suppliers = report.supplierIds && report.supplierIds.length > 0 
      ? await prisma.supplier.findMany({
          where: { id: { in: report.supplierIds } },
          select: { id: true, name: true, code: true, contact: true, email: true, phone: true }
        })
      : [];

    const reportWithDetails = {
      ...report,
      products,
      suppliers
    };

    res.json({
      success: true,
      data: reportWithDetails
    });

  } catch (error) {
    console.error('Erro ao buscar relatório:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// POST /api/reports - Criar novo relatório
router.post('/', createReportValidation, validate, async (req, res) => {
  try {
    
    const {
      prefix,
      terminalId,
      productIds = [], // Array de IDs de produtos
      supplierIds = [], // Array de IDs de fornecedores
      clientId,
      employeeUserId, // ID do colaborador selecionado
      startDateTime,
      endDateTime,
      arrivalDateTime,
      departureDateTime,
      status = 0,
      wagonType,
      hasContamination,
      contaminationDescription,
      homogeneousMaterial,
      visibleMoisture,
      rainOccurred,
      supplierAccompanied,
      observations
    } = req.body;

    // Validar se as referências existem
    const validationPromises = [];

    if (terminalId) {
      validationPromises.push(
        prisma.terminal.findUnique({ where: { id: terminalId } })
          .then(terminal => {
            return !terminal ? Promise.reject(new Error('Terminal não encontrado')) : null;
          })
      );
    }

    // Validar produtos (array)
    if (productIds && productIds.length > 0) {
      validationPromises.push(
        prisma.product.findMany({ where: { id: { in: productIds } } })
          .then(products => {
            if (products.length !== productIds.length) {
              const foundIds = products.map(p => p.id);
              const missingIds = productIds.filter(id => !foundIds.includes(id));
              return Promise.reject(new Error(`Produtos não encontrados: ${missingIds.join(', ')}`));
            }
            return null;
          })
      );
    }

    // Validar fornecedores (array)
    if (supplierIds && supplierIds.length > 0) {
      validationPromises.push(
        prisma.supplier.findMany({ where: { id: { in: supplierIds } } })
          .then(suppliers => {
            if (suppliers.length !== supplierIds.length) {
              const foundIds = suppliers.map(s => s.id);
              const missingIds = supplierIds.filter(id => !foundIds.includes(id));
              return Promise.reject(new Error(`Fornecedores não encontrados: ${missingIds.join(', ')}`));
            }
            return null;
          })
      );
    }

    // Validar colaborador (se fornecido)
    if (employeeUserId) {
      validationPromises.push(
        prisma.user.findUnique({ where: { id: employeeUserId } })
          .then(user => {
            return !user ? Promise.reject(new Error('Colaborador não encontrado')) : null;
          })
      );
    }

    try {
      await Promise.all(validationPromises);
    } catch (validationError) {
      return res.status(400).json({
        success: false,
        message: validationError.message
      });
    }

    // Gerar prefixo se não fornecido
    let finalPrefix = prefix;
    if (!finalPrefix && terminalId && clientId) {
      try {
        finalPrefix = await generateReportPrefix(terminalId, clientId, endDateTime);
      } catch (prefixError) {
        console.error('Erro ao gerar prefixo:', prefixError);
        return res.status(400).json({
          success: false,
          message: `Erro ao gerar prefixo: ${prefixError.message}`
        });
      }
    } else if (!finalPrefix) {
      return res.status(400).json({
        success: false,
        message: 'Prefixo é obrigatório quando não fornecidos terminalId e clientId para geração automática'
      });
    }

    // Criar relatório com arrays de IDs
    
    const report = await prisma.report.create({
      data: {
        prefix: finalPrefix,
        terminalId,
        clientId,
        userId: employeeUserId || req.user.id, // Usar o colaborador selecionado ou o usuário logado
        createdBy: req.user.id, // Manter sempre quem criou o relatório
        productIds: productIds || [],
        supplierIds: supplierIds || [],
        startDateTime: new Date(startDateTime),
        endDateTime: new Date(endDateTime),
        arrivalDateTime: arrivalDateTime ? new Date(arrivalDateTime) : null,
        departureDateTime: departureDateTime ? new Date(departureDateTime) : null,
        status,
        hasContamination,
        contaminationDescription,
        homogeneousMaterial,
        visibleMoisture,
        rainOccurred,
        supplierAccompanied,
        observations
      },
      include: {
        terminal: {
          select: { id: true, name: true, code: true, location: true }
        },
        client: {
          select: { id: true, name: true, contact: true, emails: true }
        },
        user: {
          select: { id: true, name: true, username: true, email: true, role: true }
        }
      }
    });


    
    // Buscar produtos e fornecedores para incluir na resposta
    const products = report.productIds && report.productIds.length > 0 
      ? await prisma.product.findMany({
          where: { id: { in: report.productIds } },
          select: { id: true, name: true, code: true, description: true, category: true }
        })
      : [];

    const suppliers = report.supplierIds && report.supplierIds.length > 0 
      ? await prisma.supplier.findMany({
          where: { id: { in: report.supplierIds } },
          select: { id: true, name: true, code: true, contact: true, email: true, phone: true }
        })
      : [];

    // Adicionar produtos e fornecedores na resposta
    const reportWithDetails = {
      ...report,
      products,
      suppliers
    };
    
    res.status(201).json({
      success: true,
      message: 'Relatório criado com sucesso',
      data: reportWithDetails
    });

  } catch (error) {
    console.error('❌ Erro ao criar relatório:', error);
    console.error('Error details:', {
      message: error.message,
      code: error.code,
      meta: error.meta
    });
    
    // Se for erro do Prisma com código específico
    if (error.code === 'P2002') {
      return res.status(400).json({
        success: false,
        message: 'Dados inválidos: violação de restrição única'
      });
    }
    
    if (error.code === 'P2003') {
      return res.status(400).json({
        success: false,
        message: 'Dados inválidos: referência não encontrada'
      });
    }
    
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      details: error.message
    });
  }
});

// PUT /api/reports/:id - Atualizar relatório
router.put('/:id', updateReportValidation, validate, async (req, res) => {
  try {
    const { id } = req.params;

    // Verificar se o relatório existe
    // Admins podem editar qualquer relatório, usuários comuns só os próprios
    const whereCondition = {
      id
    };
    
    // Se não for admin, adicionar filtro por userId
    if (req.user.role !== 'ADMIN') {
      whereCondition.userId = req.user.id;
    }

    const existingReport = await prisma.report.findFirst({
      where: whereCondition
    });

    if (!existingReport) {
      return res.status(404).json({
        success: false,
        message: 'Relatório não encontrado'
      });
    }

    // Preparar dados para atualização
    const updateData = {};
    const {
      prefix,
      terminalId,
      productId,
      supplierId,
      productIds,
      supplierIds,
      clientId,
      employeeUserId, // ID do colaborador selecionado
      startDateTime,
      endDateTime,
      arrivalDateTime,
      departureDateTime,
      status,
      wagonType,
      hasContamination,
      contaminationDescription,
      homogeneousMaterial,
      visibleMoisture,
      rainOccurred,
      supplierAccompanied,
      observations,
      pdf_url,
      pdfUrl,
      image_urls,
      imageUrls
    } = req.body;

    // Verificar se devemos regenerar o prefixo automaticamente
    const terminalChanged = terminalId !== undefined && terminalId !== existingReport.terminalId;
    const clientChanged = clientId !== undefined && clientId !== existingReport.clientId;
    const endDateChanged = endDateTime !== undefined && 
      new Date(endDateTime).toDateString() !== new Date(existingReport.endDateTime).toDateString();
    
    // Verificar se o prefixo foi alterado manualmente pelo usuário
    const prefixManuallyChanged = prefix !== undefined && prefix !== existingReport.prefix;
    
    // Regenerar automaticamente se:
    // 1. Terminal, cliente ou data mudaram E
    // 2. O prefixo não foi alterado manualmente pelo usuário
    const shouldRegeneratePrefix = (terminalChanged || clientChanged || endDateChanged) && !prefixManuallyChanged;
    
    let finalPrefix = prefix;
    if (shouldRegeneratePrefix) {
      const finalTerminalId = terminalId !== undefined ? terminalId : existingReport.terminalId;
      const finalClientId = clientId !== undefined ? clientId : existingReport.clientId;
      const finalEndDateTime = endDateTime !== undefined ? endDateTime : existingReport.endDateTime;
      
      try {
        finalPrefix = await generateReportPrefix(finalTerminalId, finalClientId, finalEndDateTime);
      } catch (error) {
        console.error('Erro ao regenerar prefixo na edição:', error);
        // Continua com o prefix original se houver erro
        finalPrefix = prefix;
      }
    }    if (finalPrefix !== undefined) updateData.prefix = finalPrefix;
    if (terminalId !== undefined) updateData.terminalId = terminalId;
    if (productId !== undefined) updateData.productId = productId;
    if (supplierId !== undefined) updateData.supplierId = supplierId;
    if (productIds !== undefined) updateData.productIds = productIds;
    if (supplierIds !== undefined) updateData.supplierIds = supplierIds;
    if (clientId !== undefined) updateData.clientId = clientId;
    if (employeeUserId !== undefined) {
      console.log('🔍 employeeUserId recebido:', employeeUserId, 'type:', typeof employeeUserId);
      // Garantir que é um número inteiro
      const parsedEmployeeUserId = parseInt(employeeUserId, 10);
      if (!isNaN(parsedEmployeeUserId) && parsedEmployeeUserId > 0) {
        updateData.userId = parsedEmployeeUserId;
        console.log('✅ userId será atualizado para:', parsedEmployeeUserId);
      } else {
        console.log('❌ employeeUserId inválido, mantendo userId original');
      }
    }
    if (startDateTime !== undefined) updateData.startDateTime = new Date(startDateTime);
    if (endDateTime !== undefined) updateData.endDateTime = new Date(endDateTime);
    if (arrivalDateTime !== undefined) updateData.arrivalDateTime = arrivalDateTime ? new Date(arrivalDateTime) : null;
    if (departureDateTime !== undefined) updateData.departureDateTime = departureDateTime ? new Date(departureDateTime) : null;
    if (status !== undefined) updateData.status = status;
    if (wagonType !== undefined) updateData.wagonType = wagonType;
    if (hasContamination !== undefined) updateData.hasContamination = hasContamination;
    if (contaminationDescription !== undefined) updateData.contaminationDescription = contaminationDescription;
    if (homogeneousMaterial !== undefined) updateData.homogeneousMaterial = homogeneousMaterial;
    if (visibleMoisture !== undefined) updateData.visibleMoisture = visibleMoisture;
    if (rainOccurred !== undefined) updateData.rainOccurred = rainOccurred;
    if (supplierAccompanied !== undefined) updateData.supplierAccompanied = supplierAccompanied;
    if (observations !== undefined) updateData.observations = observations;
    
    // Campos para PDF e imagens
    if (pdf_url !== undefined) updateData.pdfUrl = pdf_url;
    if (pdfUrl !== undefined) updateData.pdfUrl = pdfUrl;
    if (image_urls !== undefined) updateData.imageUrls = image_urls;
    if (imageUrls !== undefined) updateData.imageUrls = imageUrls;

    console.log('📋 updateData final:', JSON.stringify(updateData, null, 2));

    // Atualizar relatório
    const report = await prisma.report.update({
      where: { id },
      data: updateData,
      include: {
        terminal: {
          select: { id: true, name: true, code: true }
        },
        user: {
          select: { id: true, name: true, username: true, email: true, role: true }
        }
      }
    });

    res.json({
      success: true,
      message: 'Relatório atualizado com sucesso',
      data: report
    });

  } catch (error) {
    console.error('Erro ao atualizar relatório:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// DELETE /api/reports/:id - Excluir relatório
router.delete('/:id', [
  param('id')
    .notEmpty()
    .withMessage('ID do relatório é obrigatório')
    .isUUID()
    .withMessage('ID do relatório deve ser um UUID válido')
], validate, async (req, res) => {
  try {
    const { id } = req.params;

    // Verificar se o relatório existe
    // Admins podem excluir qualquer relatório, usuários comuns só os próprios
    const whereCondition = {
      id
    };
    
    // Se não for admin, adicionar filtro por userId
    if (req.user.role !== 'ADMIN') {
      whereCondition.userId = req.user.id;
    }

    const report = await prisma.report.findFirst({
      where: whereCondition
    });

    if (!report) {
      return res.status(404).json({
        success: false,
        message: 'Relatório não encontrado'
      });
    }

    // Excluir relatório (as imagens são excluídas automaticamente devido ao onDelete: Cascade)
    await prisma.report.delete({
      where: { id }
    });

    // TODO: Excluir arquivos físicos das imagens se necessário
    // for (const image of report.images) {
    //   // Excluir arquivo físico
    // }

    res.json({
      success: true,
      message: 'Relatório excluído com sucesso'
    });

  } catch (error) {
    console.error('Erro ao excluir relatório:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

module.exports = router;
