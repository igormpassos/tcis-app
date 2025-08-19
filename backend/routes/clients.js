const express = require('express');
const { PrismaClient } = require('@prisma/client');
const { body, query, validationResult } = require('express-validator');

const router = express.Router();
const prisma = new PrismaClient();

// Listar todos os clientes
router.get('/', [
  query('page')
    .optional()
    .isInt({ min: 1 })
    .withMessage('Página deve ser um número inteiro positivo'),
  query('limit')
    .optional()
    .isInt({ min: 1, max: 100 })
    .withMessage('Limite deve ser um número entre 1 e 100'),
  query('search')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('Busca deve ter no máximo 100 caracteres')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Parâmetros inválidos',
        errors: errors.array()
      });
    }

    const {
      page = 1,
      limit = 20,
      search
    } = req.query;

    const skip = (parseInt(page) - 1) * parseInt(limit);

    // Filtros
    const where = {};

    if (search) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { contact: { contains: search, mode: 'insensitive' } },
      ];
    }

    // Buscar clientes
    const [clients, total] = await Promise.all([
      prisma.client.findMany({
        where,
        skip,
        take: parseInt(limit),
        orderBy: { name: 'asc' }
      }),
      prisma.client.count({ where })
    ]);

    const totalPages = Math.ceil(total / parseInt(limit));
    
    res.json({
      success: true,
      data: clients,
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
    console.error('Erro ao listar clientes:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// Criar novo cliente
router.post('/', [
  body('name')
    .trim()
    .isLength({ min: 1, max: 100 })
    .withMessage('Nome é obrigatório e deve ter no máximo 100 caracteres'),
  body('contact')
    .optional()
    .trim()
    .isLength({ max: 50 })
    .withMessage('Contato deve ter no máximo 50 caracteres'),
  body('emails')
    .optional()
    .isArray()
    .withMessage('Emails deve ser um array')
    .custom((emails) => {
      if (emails && emails.length > 0) {
        for (const email of emails) {
          if (typeof email !== 'string' || !/\S+@\S+\.\S+/.test(email)) {
            throw new Error('Todos os emails devem ter formato válido');
          }
        }
      }
      return true;
    })
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Dados inválidos',
        errors: errors.array()
      });
    }

    const { name, contact, emails = [] } = req.body;

    const client = await prisma.client.create({
      data: {
        name,
        contact,
        emails
      }
    });

    res.status(201).json({
      success: true,
      message: 'Cliente criado com sucesso',
      data: client
    });
  } catch (error) {
    console.error('Erro ao criar cliente:', error);
    if (error.code === 'P2002') {
      return res.status(400).json({
        success: false,
        message: 'Já existe um cliente com este nome'
      });
    }
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// Atualizar cliente
router.put('/:id', [
  body('name')
    .optional()
    .trim()
    .isLength({ min: 1, max: 100 })
    .withMessage('Nome deve ter no máximo 100 caracteres'),
  body('contact')
    .optional()
    .trim()
    .isLength({ max: 50 })
    .withMessage('Contato deve ter no máximo 50 caracteres'),
  body('emails')
    .optional()
    .isArray()
    .withMessage('Emails deve ser um array')
    .custom((emails) => {
      if (emails && emails.length > 0) {
        for (const email of emails) {
          if (typeof email !== 'string' || !/\S+@\S+\.\S+/.test(email)) {
            throw new Error('Todos os emails devem ter formato válido');
          }
        }
      }
      return true;
    })
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Dados inválidos',
        errors: errors.array()
      });
    }

    const { id } = req.params;
    const { name, contact, emails } = req.body;

    const updateData = {};
    if (name !== undefined) updateData.name = name;
    if (contact !== undefined) updateData.contact = contact;
    if (emails !== undefined) updateData.emails = emails;

    const client = await prisma.client.update({
      where: { id: parseInt(id) },
      data: updateData
    });

    res.json({
      success: true,
      message: 'Cliente atualizado com sucesso',
      data: client
    });
  } catch (error) {
    console.error('Erro ao atualizar cliente:', error);
    if (error.code === 'P2025') {
      return res.status(404).json({
        success: false,
        message: 'Cliente não encontrado'
      });
    }
    if (error.code === 'P2002') {
      return res.status(400).json({
        success: false,
        message: 'Já existe um cliente com este nome'
      });
    }
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// Deletar cliente
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    // Verificar se o cliente tem relatórios associados
    const reportsCount = await prisma.report.count({
      where: { clientId: parseInt(id) }
    });

    if (reportsCount > 0) {
      return res.status(400).json({
        success: false,
        message: `Não é possível excluir este cliente pois ele possui ${reportsCount} relatório(s) associado(s)`
      });
    }

    await prisma.client.delete({
      where: { id: parseInt(id) }
    });

    res.json({
      success: true,
      message: 'Cliente excluído com sucesso'
    });
  } catch (error) {
    console.error('Erro ao excluir cliente:', error);
    if (error.code === 'P2025') {
      return res.status(404).json({
        success: false,
        message: 'Cliente não encontrado'
      });
    }
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

module.exports = router;
