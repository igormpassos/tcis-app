const express = require('express');
const { body, query, param } = require('express-validator');
const { PrismaClient } = require('@prisma/client');
const validate = require('../middleware/validation');

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
    
    console.log(`🔖 Prefixo gerado: ${prefix} (Terminal: ${terminal.name}, Cliente: ${clientId}, Dia: ${day}, Sequencial no terminal: ${dailySequential})`);
    
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
  body('productId')
    .optional({ nullable: true })
    .custom((value) => {
      if (value === null || value === undefined) return true;
      return Number.isInteger(value) && value > 0;
    })
    .withMessage('ID do produto deve ser um número inteiro positivo ou null'),
  body('supplierId')
    .optional({ nullable: true })
    .custom((value) => {
      if (value === null || value === undefined) return true;
      return Number.isInteger(value) && value > 0;
    })
    .withMessage('ID do fornecedor deve ser um número inteiro positivo ou null'),
  body('clientId')
    .optional({ nullable: true })
    .custom((value) => {
      if (value === null || value === undefined) return true;
      return Number.isInteger(value) && value > 0;
    })
    .withMessage('ID do cliente deve ser um número inteiro positivo ou null'),
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
    const where = {
      userId: req.user.id // Usuários só veem seus próprios relatórios
    };

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
          product: {
            select: { id: true, name: true, code: true }
          },
          supplier: {
            select: { id: true, name: true, code: true }
          },
          user: {
            select: { id: true, name: true, username: true, email: true, role: true }
          },
          images: {
            select: {
              id: true,
              filename: true,
              originalName: true,
              path: true,
              size: true,
              createdAt: true
            }
          },
          _count: {
            select: { images: true }
          }
        }
      }),
      prisma.report.count({ where })
    ]);

    const totalPages = Math.ceil(total / parseInt(limit));

    res.json({
      success: true,
      data: reports,
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

    const report = await prisma.report.findFirst({
      where: {
        id,
        userId: req.user.id // Usuários só veem seus próprios relatórios
      },
      include: {
        terminal: {
          select: { id: true, name: true, code: true, location: true }
        },
        product: {
          select: { id: true, name: true, code: true, category: true, description: true }
        },
        supplier: {
          select: { id: true, name: true, code: true, contact: true, email: true, phone: true }
        },
        user: {
          select: { id: true, name: true, username: true, email: true, role: true }
        },
        images: {
          select: {
            id: true,
            filename: true,
            originalName: true,
            path: true,
            size: true,
            mimetype: true,
            createdAt: true
          },
          orderBy: { createdAt: 'asc' }
        }
      }
    });

    if (!report) {
      return res.status(404).json({
        success: false,
        message: 'Relatório não encontrado'
      });
    }

    res.json({
      success: true,
      data: report
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
    console.log('=== BACKEND DEBUG ===');
    console.log('Request body received:', JSON.stringify(req.body, null, 2));
    console.log('User ID:', req.user?.id);
    console.log('===================');
    
    const {
      prefix,
      terminalId,
      productId,
      supplierId,
      clientId,
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
    console.log('=== VALIDAÇÃO DE REFERÊNCIAS ===');
    const validationPromises = [];

    if (terminalId) {
      console.log(`Validando terminalId: ${terminalId}`);
      validationPromises.push(
        prisma.terminal.findUnique({ where: { id: terminalId } })
          .then(terminal => {
            console.log(`Terminal encontrado:`, terminal ? `ID ${terminal.id} - ${terminal.name}` : 'NÃO ENCONTRADO');
            return !terminal ? Promise.reject(new Error('Terminal não encontrado')) : null;
          })
      );
    }

    if (productId) {
      console.log(`Validando productId: ${productId}`);
      validationPromises.push(
        prisma.product.findUnique({ where: { id: productId } })
          .then(product => {
            console.log(`Produto encontrado:`, product ? `ID ${product.id} - ${product.name}` : 'NÃO ENCONTRADO');
            return !product ? Promise.reject(new Error('Produto não encontrado')) : null;
          })
      );
    }

    if (supplierId) {
      console.log(`Validando supplierId: ${supplierId}`);
      validationPromises.push(
        prisma.supplier.findUnique({ where: { id: supplierId } })
          .then(supplier => {
            console.log(`Fornecedor encontrado:`, supplier ? `ID ${supplier.id} - ${supplier.name}` : 'NÃO ENCONTRADO');
            return !supplier ? Promise.reject(new Error('Fornecedor não encontrado')) : null;
          })
      );
    }

    try {
      await Promise.all(validationPromises);
      console.log('✅ Todas as referências validadas com sucesso');
    } catch (validationError) {
      console.log('❌ Erro de validação:', validationError.message);
      return res.status(400).json({
        success: false,
        message: validationError.message
      });
    }
    console.log('===============================');

    // Gerar prefixo se não fornecido
    let finalPrefix = prefix;
    if (!finalPrefix && terminalId && clientId) {
      console.log('=== GERANDO PREFIXO AUTOMÁTICO ===');
      try {
        finalPrefix = await generateReportPrefix(terminalId, clientId, endDateTime);
        console.log('Prefixo gerado automaticamente:', finalPrefix);
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

    // Criar relatório
    console.log('=== CRIANDO RELATÓRIO NO BANCO ===');
    console.log('Dados para inserção:', {
      prefix: finalPrefix,
      terminalId,
      productId,
      supplierId,
      clientId,
      userId: req.user.id,
      startDateTime: new Date(startDateTime),
      endDateTime: new Date(endDateTime),
      arrivalDateTime: arrivalDateTime ? new Date(arrivalDateTime) : null,
      departureDateTime: departureDateTime ? new Date(departureDateTime) : null,
    });
    
    const report = await prisma.report.create({
      data: {
        prefix: finalPrefix,
        terminalId,
        productId,
        supplierId,
        clientId,
        userId: req.user.id,
        createdBy: req.user.id,
        startDateTime: new Date(startDateTime),
        endDateTime: new Date(endDateTime),
        arrivalDateTime: arrivalDateTime ? new Date(arrivalDateTime) : null,
        departureDateTime: departureDateTime ? new Date(departureDateTime) : null,
        status,
        wagonType,
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
          select: { id: true, name: true, code: true }
        },
        product: {
          select: { id: true, name: true, code: true }
        },
        supplier: {
          select: { id: true, name: true, code: true }
        },
        user: {
          select: { id: true, name: true, username: true, email: true, role: true }
        }
      }
    });

    console.log('✅ Relatório criado com sucesso:', report.id);
    
    res.status(201).json({
      success: true,
      message: 'Relatório criado com sucesso',
      data: report
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

    // Verificar se o relatório existe e pertence ao usuário
    const existingReport = await prisma.report.findFirst({
      where: {
        id,
        userId: req.user.id
      }
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
      clientId,
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
    
    console.log('🔍 Debug regeneração:', {
      terminalChanged,
      clientChanged,
      endDateChanged,
      prefixManuallyChanged,
      shouldRegeneratePrefix,
      currentPrefix: existingReport.prefix,
      receivedPrefix: prefix,
      terminalId,
      existingTerminalId: existingReport.terminalId,
      existingEndDate: existingReport.endDateTime,
      newEndDate: endDateTime
    });
    
    let finalPrefix = prefix;
    if (shouldRegeneratePrefix) {
      const finalTerminalId = terminalId !== undefined ? terminalId : existingReport.terminalId;
      const finalClientId = clientId !== undefined ? clientId : existingReport.clientId;
      const finalEndDateTime = endDateTime !== undefined ? endDateTime : existingReport.endDateTime;
      
      try {
        finalPrefix = await generateReportPrefix(finalTerminalId, finalClientId, finalEndDateTime);
        console.log(`🔄 Prefixo regenerado automaticamente: ${finalPrefix} (Terminal: ${terminalChanged}, Cliente: ${clientChanged}, Data: ${endDateChanged})`);
      } catch (error) {
        console.error('Erro ao regenerar prefixo na edição:', error);
        // Continua com o prefix original se houver erro
        finalPrefix = prefix;
      }
    } else if (prefixManuallyChanged) {
      console.log(`✏️ Prefixo alterado manualmente pelo usuário: ${prefix}`);
    }    if (finalPrefix !== undefined) updateData.prefix = finalPrefix;
    if (terminalId !== undefined) updateData.terminalId = terminalId;
    if (productId !== undefined) updateData.productId = productId;
    if (supplierId !== undefined) updateData.supplierId = supplierId;
    if (clientId !== undefined) updateData.clientId = clientId;
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

    // Atualizar relatório
    const report = await prisma.report.update({
      where: { id },
      data: updateData,
      include: {
        terminal: {
          select: { id: true, name: true, code: true }
        },
        product: {
          select: { id: true, name: true, code: true }
        },
        supplier: {
          select: { id: true, name: true, code: true }
        },
        user: {
          select: { id: true, name: true, username: true, email: true, role: true }
        },
        images: {
          select: {
            id: true,
            filename: true,
            originalName: true,
            path: true,
            size: true,
            createdAt: true
          }
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

    // Verificar se o relatório existe e pertence ao usuário
    const report = await prisma.report.findFirst({
      where: {
        id,
        userId: req.user.id
      },
      include: {
        images: true
      }
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
