const express = require('express');
const router = express.Router();
const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
const { body, validationResult } = require('express-validator');
const { requireAdmin } = require('../middleware/auth');

const prisma = new PrismaClient();

// Middleware para validar se o usuário é admin
router.use(requireAdmin);

// GET /api/users - Listar todos os usuários
router.get('/', async (req, res) => {
  try {
    const { search, role, active } = req.query;
    
    const where = {};
    
    if (search) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { username: { contains: search, mode: 'insensitive' } },
        { email: { contains: search, mode: 'insensitive' } }
      ];
    }
    
    if (role) {
      where.role = role;
    }
    
    if (active !== undefined) {
      where.active = active === 'true';
    }

    const users = await prisma.user.findMany({
      where,
      select: {
        id: true,
        username: true,
        email: true,
        name: true,
        role: true,
        active: true,
        createdAt: true,
        updatedAt: true,
        _count: {
          select: {
            reports: true
          }
        }
      },
      orderBy: {
        createdAt: 'desc'
      }
    });

    res.json({
      success: true,
      data: users
    });
  } catch (error) {
    console.error('Erro ao listar usuários:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// GET /api/users/:id - Buscar usuário por ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const user = await prisma.user.findUnique({
      where: { id: parseInt(id) },
      select: {
        id: true,
        username: true,
        email: true,
        name: true,
        role: true,
        active: true,
        createdAt: true,
        updatedAt: true,
        _count: {
          select: {
            reports: true
          }
        }
      }
    });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Usuário não encontrado'
      });
    }

    res.json({
      success: true,
      data: user
    });
  } catch (error) {
    console.error('Erro ao buscar usuário:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// POST /api/users - Criar novo usuário
router.post('/', [
  body('username')
    .notEmpty()
    .withMessage('Username é obrigatório')
    .isLength({ min: 3 })
    .withMessage('Username deve ter pelo menos 3 caracteres'),
  body('password')
    .isLength({ min: 6 })
    .withMessage('Senha deve ter pelo menos 6 caracteres'),
  body('email')
    .optional()
    .isEmail()
    .withMessage('Email deve ser válido'),
  body('name')
    .optional()
    .isLength({ min: 2 })
    .withMessage('Nome deve ter pelo menos 2 caracteres'),
  body('role')
    .isIn(['USER', 'ADMIN'])
    .withMessage('Role deve ser USER ou ADMIN')
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

    const { username, password, email, name, role = 'USER' } = req.body;

    // Verificar se username já existe
    const existingUser = await prisma.user.findUnique({
      where: { username }
    });

    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'Username já está em uso'
      });
    }

    // Verificar se email já existe (se fornecido)
    if (email) {
      const existingEmail = await prisma.user.findUnique({
        where: { email }
      });

      if (existingEmail) {
        return res.status(400).json({
          success: false,
          message: 'Email já está em uso'
        });
      }
    }

    // Criptografar senha
    const hashedPassword = await bcrypt.hash(password, 10);

    // Criar usuário
    const user = await prisma.user.create({
      data: {
        username,
        password: hashedPassword,
        email: email || null,
        name: name || null,
        role
      },
      select: {
        id: true,
        username: true,
        email: true,
        name: true,
        role: true,
        active: true,
        createdAt: true
      }
    });

    res.status(201).json({
      success: true,
      message: 'Usuário criado com sucesso',
      data: user
    });
  } catch (error) {
    console.error('Erro ao criar usuário:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// PUT /api/users/:id - Atualizar usuário
router.put('/:id', [
  body('username')
    .optional()
    .isLength({ min: 3 })
    .withMessage('Username deve ter pelo menos 3 caracteres'),
  body('password')
    .optional()
    .isLength({ min: 6 })
    .withMessage('Senha deve ter pelo menos 6 caracteres'),
  body('email')
    .optional()
    .isEmail()
    .withMessage('Email deve ser válido'),
  body('name')
    .optional()
    .isLength({ min: 2 })
    .withMessage('Nome deve ter pelo menos 2 caracteres'),
  body('role')
    .optional()
    .isIn(['USER', 'ADMIN'])
    .withMessage('Role deve ser USER ou ADMIN'),
  body('active')
    .optional()
    .isBoolean()
    .withMessage('Active deve ser true ou false')
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
    const { username, password, email, name, role, active } = req.body;

    // Verificar se usuário existe
    const existingUser = await prisma.user.findUnique({
      where: { id: parseInt(id) }
    });

    if (!existingUser) {
      return res.status(404).json({
        success: false,
        message: 'Usuário não encontrado'
      });
    }

    // Dados a serem atualizados
    const updateData = {};

    if (username && username !== existingUser.username) {
      // Verificar se novo username já existe
      const usernameExists = await prisma.user.findUnique({
        where: { username }
      });

      if (usernameExists) {
        return res.status(400).json({
          success: false,
          message: 'Username já está em uso'
        });
      }

      updateData.username = username;
    }

    if (email && email !== existingUser.email) {
      // Verificar se novo email já existe
      const emailExists = await prisma.user.findUnique({
        where: { email }
      });

      if (emailExists) {
        return res.status(400).json({
          success: false,
          message: 'Email já está em uso'
        });
      }

      updateData.email = email;
    }

    if (password) {
      updateData.password = await bcrypt.hash(password, 10);
    }

    if (name !== undefined) updateData.name = name;
    if (role !== undefined) updateData.role = role;
    if (active !== undefined) updateData.active = active;

    // Atualizar usuário
    const user = await prisma.user.update({
      where: { id: parseInt(id) },
      data: updateData,
      select: {
        id: true,
        username: true,
        email: true,
        name: true,
        role: true,
        active: true,
        updatedAt: true
      }
    });

    res.json({
      success: true,
      message: 'Usuário atualizado com sucesso',
      data: user
    });
  } catch (error) {
    console.error('Erro ao atualizar usuário:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// DELETE /api/users/:id - Deletar usuário
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const userId = parseInt(id);

    // Verificar se usuário existe
    const existingUser = await prisma.user.findUnique({
      where: { id: userId }
    });

    if (!existingUser) {
      return res.status(404).json({
        success: false,
        message: 'Usuário não encontrado'
      });
    }

    // Verificar se usuário tem relatórios associados
    const reportsCount = await prisma.report.count({
      where: { userId }
    });

    if (reportsCount > 0) {
      return res.status(400).json({
        success: false,
        message: `Não é possível deletar usuário com ${reportsCount} relatório(s) associado(s)`
      });
    }

    // Deletar usuário
    await prisma.user.delete({
      where: { id: userId }
    });

    res.json({
      success: true,
      message: 'Usuário deletado com sucesso'
    });
  } catch (error) {
    console.error('Erro ao deletar usuário:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

module.exports = router;
