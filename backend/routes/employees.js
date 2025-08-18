const express = require('express');
const { body, query, param } = require('express-validator');
const { PrismaClient } = require('@prisma/client');
const validate = require('../middleware/validation');
const { requireRole } = require('../middleware/auth');

const router = express.Router();
const prisma = new PrismaClient();

// Validações
const createEmployeeValidation = [
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
  body('position')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('Cargo deve ter no máximo 100 caracteres'),
  body('email')
    .optional()
    .isEmail()
    .withMessage('Email deve ter um formato válido')
    .normalizeEmail(),
  body('phone')
    .optional()
    .trim()
    .isLength({ max: 20 })
    .withMessage('Telefone deve ter no máximo 20 caracteres')
];

// GET /api/employees - Listar funcionários
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
  query('position')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('Cargo deve ter no máximo 100 caracteres'),
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
      position,
      search
    } = req.query;

    const skip = (parseInt(page) - 1) * parseInt(limit);

    // Filtros
    const where = {};

    if (active !== undefined) {
      where.active = active === 'true';
    }

    if (position) {
      where.position = { contains: position, mode: 'insensitive' };
    }

    if (search) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { code: { contains: search, mode: 'insensitive' } },
        { position: { contains: search, mode: 'insensitive' } },
        { email: { contains: search, mode: 'insensitive' } }
      ];
    }

    // Buscar funcionários
    const [employees, total] = await Promise.all([
      prisma.employee.findMany({
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
      prisma.employee.count({ where })
    ]);

    const totalPages = Math.ceil(total / parseInt(limit));

    res.json({
      success: true,
      data: employees,
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
    console.error('Erro ao listar funcionários:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// GET /api/employees/positions - Listar cargos de funcionários
router.get('/positions', async (req, res) => {
  try {
    const positions = await prisma.employee.findMany({
      where: {
        position: { not: null },
        active: true
      },
      select: { position: true },
      distinct: ['position']
    });

    const positionList = positions
      .map(e => e.position)
      .filter(Boolean)
      .sort();

    res.json({
      success: true,
      data: positionList
    });

  } catch (error) {
    console.error('Erro ao listar cargos:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// GET /api/employees/:id - Buscar funcionário específico
router.get('/:id', [
  param('id')
    .notEmpty()
    .withMessage('ID do funcionário é obrigatório')
    .isInt({ min: 1 })
    .withMessage('ID do funcionário deve ser um número inteiro positivo')
], validate, async (req, res) => {
  try {
    const { id } = req.params;

    const employee = await prisma.employee.findUnique({
      where: { id: parseInt(id) },
      include: {
        _count: {
          select: { reports: true }
        }
      }
    });

    if (!employee) {
      return res.status(404).json({
        success: false,
        message: 'Funcionário não encontrado'
      });
    }

    res.json({
      success: true,
      data: employee
    });

  } catch (error) {
    console.error('Erro ao buscar funcionário:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// POST /api/employees - Criar novo funcionário (apenas admin)
router.post('/', requireRole('ADMIN'), createEmployeeValidation, validate, async (req, res) => {
  try {
    const { name, code, position, email, phone } = req.body;

    // Verificar se já existe funcionário com mesmo código ou email
    const existingEmployee = await prisma.employee.findFirst({
      where: {
        OR: [
          ...(code ? [{ code }] : []),
          ...(email ? [{ email }] : [])
        ]
      }
    });

    if (existingEmployee) {
      return res.status(409).json({
        success: false,
        message: 'Funcionário com este código ou email já existe'
      });
    }

    const employee = await prisma.employee.create({
      data: {
        name,
        code,
        position,
        email,
        phone
      }
    });

    res.status(201).json({
      success: true,
      message: 'Funcionário criado com sucesso',
      data: employee
    });

  } catch (error) {
    console.error('Erro ao criar funcionário:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// PUT /api/employees/:id - Atualizar funcionário (apenas admin)
router.put('/:id', requireRole('ADMIN'), [
  param('id')
    .notEmpty()
    .withMessage('ID do funcionário é obrigatório')
    .isInt({ min: 1 })
    .withMessage('ID do funcionário deve ser um número inteiro positivo'),
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
  body('position')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('Cargo deve ter no máximo 100 caracteres'),
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
  body('active')
    .optional()
    .isBoolean()
    .withMessage('Campo ativo deve ser boolean')
], validate, async (req, res) => {
  try {
    const { id } = req.params;
    const { name, code, position, email, phone, active } = req.body;

    // Verificar se o funcionário existe
    const existingEmployee = await prisma.employee.findUnique({
      where: { id: parseInt(id) }
    });

    if (!existingEmployee) {
      return res.status(404).json({
        success: false,
        message: 'Funcionário não encontrado'
      });
    }

    // Verificar se há conflito com código ou email
    if (code || email) {
      const conflictingEmployee = await prisma.employee.findFirst({
        where: {
          id: { not: parseInt(id) },
          OR: [
            ...(code ? [{ code }] : []),
            ...(email ? [{ email }] : [])
          ]
        }
      });

      if (conflictingEmployee) {
        return res.status(409).json({
          success: false,
          message: 'Funcionário com este código ou email já existe'
        });
      }
    }

    // Preparar dados para atualização
    const updateData = {};
    if (name !== undefined) updateData.name = name;
    if (code !== undefined) updateData.code = code;
    if (position !== undefined) updateData.position = position;
    if (email !== undefined) updateData.email = email;
    if (phone !== undefined) updateData.phone = phone;
    if (active !== undefined) updateData.active = active;

    const employee = await prisma.employee.update({
      where: { id: parseInt(id) },
      data: updateData
    });

    res.json({
      success: true,
      message: 'Funcionário atualizado com sucesso',
      data: employee
    });

  } catch (error) {
    console.error('Erro ao atualizar funcionário:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// DELETE /api/employees/:id - Excluir funcionário (apenas admin)
router.delete('/:id', requireRole('ADMIN'), [
  param('id')
    .notEmpty()
    .withMessage('ID do funcionário é obrigatório')
    .isInt({ min: 1 })
    .withMessage('ID do funcionário deve ser um número inteiro positivo')
], validate, async (req, res) => {
  try {
    const { id } = req.params;

    // Verificar se o funcionário existe
    const employee = await prisma.employee.findUnique({
      where: { id: parseInt(id) },
      include: {
        _count: {
          select: { reports: true }
        }
      }
    });

    if (!employee) {
      return res.status(404).json({
        success: false,
        message: 'Funcionário não encontrado'
      });
    }

    // Verificar se há relatórios associados
    if (employee._count.reports > 0) {
      return res.status(409).json({
        success: false,
        message: 'Não é possível excluir funcionário que possui relatórios associados'
      });
    }

    await prisma.employee.delete({
      where: { id: parseInt(id) }
    });

    res.json({
      success: true,
      message: 'Funcionário excluído com sucesso'
    });

  } catch (error) {
    console.error('Erro ao excluir funcionário:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

module.exports = router;
