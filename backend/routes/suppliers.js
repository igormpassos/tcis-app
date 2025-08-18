const express = require('express');
const { body, query, param } = require('express-validator');
const { PrismaClient } = require('@prisma/client');
const validate = require('../middleware/validation');
const { requireRole } = require('../middleware/auth');

const router = express.Router();
const prisma = new PrismaClient();

// Validações
const createSupplierValidation = [
  body('name')
    .notEmpty()
    .withMessage('Nome é obrigatório')
    .trim()
    .isLength({ min: 1, max: 100 })
    .withMessage('Nome deve ter entre 1 e 100 caracteres'),
  body('code')
    .optional()
    .trim()
    .isLength({ max: 50 })
    .withMessage('Código deve ter no máximo 50 caracteres'),
  body('contact')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('Contato deve ter no máximo 100 caracteres'),
  body('email')
    .optional()
    .isEmail()
    .withMessage('Email deve ter um formato válido')
    .normalizeEmail(),
  body('phone')
    .optional()
    .trim()
    .isLength({ max: 20 })
    .withMessage('Telefone deve ter no máximo 20 caracteres'),
  body('address')
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage('Endereço deve ter no máximo 500 caracteres')
];

// GET /api/suppliers - Listar fornecedores
router.get('/', [
  query('page')
    .optional()
    .isInt({ min: 1 })
    .withMessage('Página deve ser um número inteiro positivo'),
  query('limit')
    .optional()
    .isInt({ min: 1, max: 100 })
    .withMessage('Limite deve ser um número entre 1 e 100'),
  query('active')
    .optional()
    .isBoolean()
    .withMessage('Campo ativo deve ser boolean'),
  query('search')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('Busca deve ter no máximo 100 caracteres')
], validate, async (req, res) => {
  try {
    const {
      page = 1,
      limit = 20,
      active,
      search
    } = req.query;

    const skip = (parseInt(page) - 1) * parseInt(limit);

    // Filtros
    const where = {};

    if (active !== undefined) {
      where.active = active === 'true';
    }

    if (search) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { code: { contains: search, mode: 'insensitive' } },
        { contact: { contains: search, mode: 'insensitive' } },
        { email: { contains: search, mode: 'insensitive' } }
      ];
    }

    // Buscar fornecedores
    const [suppliers, total] = await Promise.all([
      prisma.supplier.findMany({
        where,
        skip,
        take: parseInt(limit),
        orderBy: { name: 'asc' },
        include: {
          _count: {
            select: { reports: true }
          }
        }
      }),
      prisma.supplier.count({ where })
    ]);

    const totalPages = Math.ceil(total / parseInt(limit));

    res.json({
      success: true,
      data: suppliers,
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
    console.error('Erro ao listar fornecedores:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// GET /api/suppliers/:id - Buscar fornecedor específico
router.get('/:id', [
  param('id')
    .notEmpty()
    .withMessage('ID do fornecedor é obrigatório')
    .isInt({ min: 1 })
    .withMessage('ID do fornecedor deve ser um número inteiro positivo')
], validate, async (req, res) => {
  try {
    const { id } = req.params;

    const supplier = await prisma.supplier.findUnique({
      where: { id: parseInt(id) },
      include: {
        _count: {
          select: { reports: true }
        }
      }
    });

    if (!supplier) {
      return res.status(404).json({
        success: false,
        message: 'Fornecedor não encontrado'
      });
    }

    res.json({
      success: true,
      data: supplier
    });

  } catch (error) {
    console.error('Erro ao buscar fornecedor:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// POST /api/suppliers - Criar novo fornecedor (apenas admin)
router.post('/', requireRole('ADMIN'), createSupplierValidation, validate, async (req, res) => {
  try {
    const { name, code, contact, email, phone, address } = req.body;

    // Verificar se já existe fornecedor com mesmo nome, código ou email
    const existingSupplier = await prisma.supplier.findFirst({
      where: {
        OR: [
          { name },
          ...(code ? [{ code }] : []),
          ...(email ? [{ email }] : [])
        ]
      }
    });

    if (existingSupplier) {
      return res.status(409).json({
        success: false,
        message: 'Fornecedor com este nome, código ou email já existe'
      });
    }

    const supplier = await prisma.supplier.create({
      data: {
        name,
        code,
        contact,
        email,
        phone,
        address
      }
    });

    res.status(201).json({
      success: true,
      message: 'Fornecedor criado com sucesso',
      data: supplier
    });

  } catch (error) {
    console.error('Erro ao criar fornecedor:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// PUT /api/suppliers/:id - Atualizar fornecedor (apenas admin)
router.put('/:id', requireRole('ADMIN'), [
  param('id')
    .notEmpty()
    .withMessage('ID do fornecedor é obrigatório')
    .isInt({ min: 1 })
    .withMessage('ID do fornecedor deve ser um número inteiro positivo'),
  body('name')
    .optional()
    .trim()
    .isLength({ min: 1, max: 100 })
    .withMessage('Nome deve ter entre 1 e 100 caracteres'),
  body('code')
    .optional()
    .trim()
    .isLength({ max: 50 })
    .withMessage('Código deve ter no máximo 50 caracteres'),
  body('contact')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('Contato deve ter no máximo 100 caracteres'),
  body('email')
    .optional()
    .isEmail()
    .withMessage('Email deve ter um formato válido')
    .normalizeEmail(),
  body('phone')
    .optional()
    .trim()
    .isLength({ max: 20 })
    .withMessage('Telefone deve ter no máximo 20 caracteres'),
  body('address')
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage('Endereço deve ter no máximo 500 caracteres'),
  body('active')
    .optional()
    .isBoolean()
    .withMessage('Campo ativo deve ser boolean')
], validate, async (req, res) => {
  try {
    const { id } = req.params;
    const { name, code, contact, email, phone, address, active } = req.body;

    // Verificar se o fornecedor existe
    const existingSupplier = await prisma.supplier.findUnique({
      where: { id: parseInt(id) }
    });

    if (!existingSupplier) {
      return res.status(404).json({
        success: false,
        message: 'Fornecedor não encontrado'
      });
    }

    // Verificar se há conflito com nome, código ou email
    if (name || code || email) {
      const conflictingSupplier = await prisma.supplier.findFirst({
        where: {
          id: { not: parseInt(id) },
          OR: [
            ...(name ? [{ name }] : []),
            ...(code ? [{ code }] : []),
            ...(email ? [{ email }] : [])
          ]
        }
      });

      if (conflictingSupplier) {
        return res.status(409).json({
          success: false,
          message: 'Fornecedor com este nome, código ou email já existe'
        });
      }
    }

    // Preparar dados para atualização
    const updateData = {};
    if (name !== undefined) updateData.name = name;
    if (code !== undefined) updateData.code = code;
    if (contact !== undefined) updateData.contact = contact;
    if (email !== undefined) updateData.email = email;
    if (phone !== undefined) updateData.phone = phone;
    if (address !== undefined) updateData.address = address;
    if (active !== undefined) updateData.active = active;

    const supplier = await prisma.supplier.update({
      where: { id: parseInt(id) },
      data: updateData
    });

    res.json({
      success: true,
      message: 'Fornecedor atualizado com sucesso',
      data: supplier
    });

  } catch (error) {
    console.error('Erro ao atualizar fornecedor:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// DELETE /api/suppliers/:id - Excluir fornecedor (apenas admin)
router.delete('/:id', requireRole('ADMIN'), [
  param('id')
    .notEmpty()
    .withMessage('ID do fornecedor é obrigatório')
    .isInt({ min: 1 })
    .withMessage('ID do fornecedor deve ser um número inteiro positivo')
], validate, async (req, res) => {
  try {
    const { id } = req.params;

    // Verificar se o fornecedor existe
    const supplier = await prisma.supplier.findUnique({
      where: { id: parseInt(id) },
      include: {
        _count: {
          select: { reports: true }
        }
      }
    });

    if (!supplier) {
      return res.status(404).json({
        success: false,
        message: 'Fornecedor não encontrado'
      });
    }

    // Verificar se há relatórios associados
    if (supplier._count.reports > 0) {
      return res.status(409).json({
        success: false,
        message: 'Não é possível excluir fornecedor que possui relatórios associados'
      });
    }

    await prisma.supplier.delete({
      where: { id: parseInt(id) }
    });

    res.json({
      success: true,
      message: 'Fornecedor excluído com sucesso'
    });

  } catch (error) {
    console.error('Erro ao excluir fornecedor:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

module.exports = router;
