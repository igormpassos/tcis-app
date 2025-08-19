const express = require('express');
const { body, query, param } = require('express-validator');
const { PrismaClient } = require('@prisma/client');
const validate = require('../middleware/validation');
const { requireRole } = require('../middleware/auth');

const router = express.Router();
const prisma = new PrismaClient();

// Validação para criação de terminal
const createTerminalValidation = [
  body('name')
    .notEmpty()
    .withMessage('Nome é obrigatório')
    .isLength({ min: 2, max: 100 })
    .withMessage('Nome deve ter entre 2 e 100 caracteres'),
  
  body('code')
    .optional()
    .isLength({ min: 2, max: 50 })
    .withMessage('Código deve ter entre 2 e 50 caracteres'),
  
  body('prefix')
    .optional()
    .isLength({ max: 20 })
    .withMessage('Prefix deve ter no máximo 20 caracteres'),
  
  body('location')
    .optional()
    .isLength({ max: 255 })
    .withMessage('Localização deve ter no máximo 255 caracteres')
];

// GET /api/terminals - Listar terminais
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
        { location: { contains: search, mode: 'insensitive' } }
      ];
    }

    // Buscar terminais
    const [terminals, total] = await Promise.all([
      prisma.terminal.findMany({
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
      prisma.terminal.count({ where })
    ]);

    const totalPages = Math.ceil(total / parseInt(limit));

    res.json({
      success: true,
      data: terminals,
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
    console.error('Erro ao listar terminais:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// GET /api/terminals/:id - Buscar terminal específico
router.get('/:id', [
  param('id')
    .notEmpty()
    .withMessage('ID do terminal é obrigatório')
    .isInt({ min: 1 })
    .withMessage('ID do terminal deve ser um número inteiro positivo')
], validate, async (req, res) => {
  try {
    const { id } = req.params;

    const terminal = await prisma.terminal.findUnique({
      where: { id: parseInt(id) },
      include: {
        _count: {
          select: { reports: true }
        }
      }
    });

    if (!terminal) {
      return res.status(404).json({
        success: false,
        message: 'Terminal não encontrado'
      });
    }

    res.json({
      success: true,
      data: terminal
    });

  } catch (error) {
    console.error('Erro ao buscar terminal:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// POST /api/terminals - Criar novo terminal (apenas admin)
router.post('/', requireRole('ADMIN'), createTerminalValidation, validate, async (req, res) => {
  try {
    const { name, code, prefix, location } = req.body;

    // Verificar se já existe terminal com mesmo nome ou código
    const existingTerminal = await prisma.terminal.findFirst({
      where: {
        OR: [
          { name },
          ...(code ? [{ code }] : [])
        ]
      }
    });

    if (existingTerminal) {
      return res.status(409).json({
        success: false,
        message: 'Terminal com este nome ou código já existe'
      });
    }

    const terminal = await prisma.terminal.create({
      data: {
        name,
        code,
        prefix,
        location
      }
    });

    res.status(201).json({
      success: true,
      message: 'Terminal criado com sucesso',
      data: terminal
    });

  } catch (error) {
    console.error('Erro ao criar terminal:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// PUT /api/terminals/:id - Atualizar terminal (apenas admin)
router.put('/:id', requireRole('ADMIN'), [
  param('id')
    .notEmpty()
    .withMessage('ID do terminal é obrigatório')
    .isInt({ min: 1 })
    .withMessage('ID do terminal deve ser um número inteiro positivo'),
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
  body('prefix')
    .optional()
    .trim()
    .isLength({ max: 20 })
    .withMessage('Prefix deve ter no máximo 20 caracteres'),
  body('location')
    .optional()
    .trim()
    .isLength({ max: 200 })
    .withMessage('Localização deve ter no máximo 200 caracteres'),
  body('active')
    .optional()
    .isBoolean()
    .withMessage('Campo ativo deve ser boolean')
], validate, async (req, res) => {
  try {
    const { id } = req.params;
    const { name, code, prefix, location, active } = req.body;

    // Verificar se o terminal existe
    const existingTerminal = await prisma.terminal.findUnique({
      where: { id: parseInt(id) }
    });

    if (!existingTerminal) {
      return res.status(404).json({
        success: false,
        message: 'Terminal não encontrado'
      });
    }

    // Verificar se há conflito com nome ou código
    if (name || code) {
      const conflictingTerminal = await prisma.terminal.findFirst({
        where: {
          id: { not: parseInt(id) },
          OR: [
            ...(name ? [{ name }] : []),
            ...(code ? [{ code }] : [])
          ]
        }
      });

      if (conflictingTerminal) {
        return res.status(409).json({
          success: false,
          message: 'Terminal com este nome ou código já existe'
        });
      }
    }

    // Preparar dados para atualização
    const updateData = {};
    if (name !== undefined) updateData.name = name;
    if (code !== undefined) updateData.code = code;
    if (prefix !== undefined) updateData.prefix = prefix;
    if (location !== undefined) updateData.location = location;
    if (active !== undefined) updateData.active = active;

    const terminal = await prisma.terminal.update({
      where: { id: parseInt(id) },
      data: updateData
    });

    res.json({
      success: true,
      message: 'Terminal atualizado com sucesso',
      data: terminal
    });

  } catch (error) {
    console.error('Erro ao atualizar terminal:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// DELETE /api/terminals/:id - Excluir terminal (apenas admin)
router.delete('/:id', requireRole('ADMIN'), [
  param('id')
    .notEmpty()
    .withMessage('ID do terminal é obrigatório')
    .isInt({ min: 1 })
    .withMessage('ID do terminal deve ser um número inteiro positivo')
], validate, async (req, res) => {
  try {
    const { id } = req.params;

    // Verificar se o terminal existe
    const terminal = await prisma.terminal.findUnique({
      where: { id: parseInt(id) },
      include: {
        _count: {
          select: { reports: true }
        }
      }
    });

    if (!terminal) {
      return res.status(404).json({
        success: false,
        message: 'Terminal não encontrado'
      });
    }

    // Verificar se há relatórios associados
    if (terminal._count.reports > 0) {
      return res.status(409).json({
        success: false,
        message: 'Não é possível excluir terminal que possui relatórios associados'
      });
    }

    await prisma.terminal.delete({
      where: { id: parseInt(id) }
    });

    res.json({
      success: true,
      message: 'Terminal excluído com sucesso'
    });

  } catch (error) {
    console.error('Erro ao excluir terminal:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

module.exports = router;
