const express = require('express');
const { body, query, param } = require('express-validator');
const { PrismaClient } = require('@prisma/client');
const validate = require('../middleware/validation');
const { requireRole } = require('../middleware/auth');

const router = express.Router();
const prisma = new PrismaClient();

// Validações
const createProductValidation = [
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
  body('description')
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage('Descrição deve ter no máximo 500 caracteres'),
  body('category')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('Categoria deve ter no máximo 100 caracteres')
];

// GET /api/products - Listar produtos
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
  query('category')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('Categoria deve ter no máximo 100 caracteres'),
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
      category,
      search
    } = req.query;

    const skip = (parseInt(page) - 1) * parseInt(limit);

    // Filtros
    const where = {};

    if (active !== undefined) {
      where.active = active === 'true';
    }

    if (category) {
      where.category = { contains: category, mode: 'insensitive' };
    }

    if (search) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { code: { contains: search, mode: 'insensitive' } },
        { description: { contains: search, mode: 'insensitive' } },
        { category: { contains: search, mode: 'insensitive' } }
      ];
    }

    // Buscar produtos
    const [products, total] = await Promise.all([
      prisma.product.findMany({
        where,
        skip,
        take: parseInt(limit),
        orderBy: { name: 'asc' },
        include: {
          suppliers: {
            include: {
              supplier: true
            },
            where: {
              isActive: true
            }
          },
          _count: {
            select: { suppliers: true }
          }
        }
      }),
      prisma.product.count({ where })
    ]);

    // Transformar os dados para incluir lista de fornecedores
    const productsWithSuppliers = products.map(product => ({
      ...product,
      suppliers: product.suppliers.map(ps => ps.supplier)
    }));

    const totalPages = Math.ceil(total / parseInt(limit));

    res.json({
      success: true,
      data: productsWithSuppliers,
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
    console.error('Erro ao listar produtos:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// GET /api/products/simple - Listar produtos sem paginação (para dropdowns)
router.get('/simple', async (req, res) => {
  try {
    const products = await prisma.product.findMany({
      where: { active: true },
      orderBy: { name: 'asc' },
      include: {
        suppliers: {
          include: {
            supplier: true
          },
          where: {
            isActive: true
          }
        }
      }
    });

    // Transformar os dados para incluir lista de fornecedores
    const productsWithSuppliers = products.map(product => ({
      ...product,
      suppliers: product.suppliers.map(ps => ps.supplier)
    }));

    res.json({
      success: true,
      data: productsWithSuppliers
    });

  } catch (error) {
    console.error('Erro ao listar produtos simples:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// GET /api/products/categories - Listar categorias de produtos
router.get('/categories', async (req, res) => {
  try {
    const categories = await prisma.product.findMany({
      where: {
        category: { not: null },
        active: true
      },
      select: { category: true },
      distinct: ['category']
    });

    const categoryList = categories
      .map(p => p.category)
      .filter(Boolean)
      .sort();

    res.json({
      success: true,
      data: categoryList
    });

  } catch (error) {
    console.error('Erro ao listar categorias:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// GET /api/products/:id - Buscar produto específico
router.get('/:id', [
  param('id')
    .notEmpty()
    .withMessage('ID do produto é obrigatório')
    .isInt({ min: 1 })
    .withMessage('ID do produto deve ser um número inteiro positivo')
], validate, async (req, res) => {
  try {
    const { id } = req.params;

    const product = await prisma.product.findUnique({
      where: { id: parseInt(id) },
      include: {
        suppliers: {
          include: {
            supplier: true
          },
          where: {
            isActive: true
          }
        },
        _count: {
          select: { suppliers: true }
        }
      }
    });

    if (!product) {
      return res.status(404).json({
        success: false,
        message: 'Produto não encontrado'
      });
    }

    // Transformar dados para incluir lista de fornecedores
    const productWithSuppliers = {
      ...product,
      suppliers: product.suppliers.map(ps => ps.supplier)
    };

    res.json({
      success: true,
      data: productWithSuppliers
    });

  } catch (error) {
    console.error('Erro ao buscar produto:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// POST /api/products - Criar novo produto (apenas admin)
router.post('/', requireRole('ADMIN'), createProductValidation, validate, async (req, res) => {
  try {
    const { name, code, description, category } = req.body;

    // Verificar se já existe produto com mesmo nome ou código
    const existingProduct = await prisma.product.findFirst({
      where: {
        OR: [
          { name },
          ...(code ? [{ code }] : [])
        ]
      }
    });

    if (existingProduct) {
      return res.status(409).json({
        success: false,
        message: 'Produto com este nome ou código já existe'
      });
    }

    const product = await prisma.product.create({
      data: {
        name,
        code,
        description,
        category
      }
    });

    res.status(201).json({
      success: true,
      message: 'Produto criado com sucesso',
      data: product
    });

  } catch (error) {
    console.error('Erro ao criar produto:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// PUT /api/products/:id - Atualizar produto (apenas admin)
router.put('/:id', requireRole('ADMIN'), [
  param('id')
    .notEmpty()
    .withMessage('ID do produto é obrigatório')
    .isInt({ min: 1 })
    .withMessage('ID do produto deve ser um número inteiro positivo'),
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
  body('description')
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage('Descrição deve ter no máximo 500 caracteres'),
  body('category')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('Categoria deve ter no máximo 100 caracteres'),
  body('active')
    .optional()
    .isBoolean()
    .withMessage('Campo ativo deve ser boolean')
], validate, async (req, res) => {
  try {
    const { id } = req.params;
    const { name, code, description, category, active } = req.body;

    // Verificar se o produto existe
    const existingProduct = await prisma.product.findUnique({
      where: { id: parseInt(id) }
    });

    if (!existingProduct) {
      return res.status(404).json({
        success: false,
        message: 'Produto não encontrado'
      });
    }

    // Verificar se há conflito com nome ou código
    if (name || code) {
      const conflictingProduct = await prisma.product.findFirst({
        where: {
          id: { not: parseInt(id) },
          OR: [
            ...(name ? [{ name }] : []),
            ...(code ? [{ code }] : [])
          ]
        }
      });

      if (conflictingProduct) {
        return res.status(409).json({
          success: false,
          message: 'Produto com este nome ou código já existe'
        });
      }
    }

    // Preparar dados para atualização
    const updateData = {};
    if (name !== undefined) updateData.name = name;
    if (code !== undefined) updateData.code = code;
    if (description !== undefined) updateData.description = description;
    if (category !== undefined) updateData.category = category;
    if (active !== undefined) updateData.active = active;

    const product = await prisma.product.update({
      where: { id: parseInt(id) },
      data: updateData
    });

    res.json({
      success: true,
      message: 'Produto atualizado com sucesso',
      data: product
    });

  } catch (error) {
    console.error('Erro ao atualizar produto:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// DELETE /api/products/:id - Excluir produto (apenas admin)
router.delete('/:id', requireRole('ADMIN'), [
  param('id')
    .notEmpty()
    .withMessage('ID do produto é obrigatório')
    .isInt({ min: 1 })
    .withMessage('ID do produto deve ser um número inteiro positivo')
], validate, async (req, res) => {
  try {
    const { id } = req.params;

    // Verificar se o produto existe
    const product = await prisma.product.findUnique({
      where: { id: parseInt(id) }
    });

    if (!product) {
      return res.status(404).json({
        success: false,
        message: 'Produto não encontrado'
      });
    }

    // Verificar se há relatórios associados - buscar por productIds
    const reportsCount = await prisma.report.count({
      where: {
        productIds: { has: parseInt(id) }
      }
    });

    if (reportsCount > 0) {
      return res.status(409).json({
        success: false,
        message: 'Não é possível excluir produto que possui relatórios associados'
      });
    }

    await prisma.product.delete({
      where: { id: parseInt(id) }
    });

    res.json({
      success: true,
      message: 'Produto excluído com sucesso'
    });

  } catch (error) {
    console.error('Erro ao excluir produto:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// POST /api/products/:id/suppliers - Adicionar fornecedor ao produto (apenas admin)
router.post('/:id/suppliers', requireRole('ADMIN'), [
  param('id')
    .notEmpty()
    .withMessage('ID do produto é obrigatório')
    .isInt({ min: 1 })
    .withMessage('ID do produto deve ser um número inteiro positivo'),
  body('supplierId')
    .notEmpty()
    .withMessage('ID do fornecedor é obrigatório')
    .isInt({ min: 1 })
    .withMessage('ID do fornecedor deve ser um número inteiro positivo')
], validate, async (req, res) => {
  try {
    const { id } = req.params;
    const { supplierId } = req.body;

    // Verificar se produto existe
    const product = await prisma.product.findUnique({
      where: { id: parseInt(id) }
    });

    if (!product) {
      return res.status(404).json({
        success: false,
        message: 'Produto não encontrado'
      });
    }

    // Verificar se fornecedor existe
    const supplier = await prisma.supplier.findUnique({
      where: { id: parseInt(supplierId) }
    });

    if (!supplier) {
      return res.status(404).json({
        success: false,
        message: 'Fornecedor não encontrado'
      });
    }

    // Verificar se a relação já existe
    const existingRelation = await prisma.productSupplier.findFirst({
      where: {
        productId: parseInt(id),
        supplierId: parseInt(supplierId)
      }
    });

    if (existingRelation) {
      // Se existe mas está inativa, ativar
      if (!existingRelation.isActive) {
        await prisma.productSupplier.update({
          where: { id: existingRelation.id },
          data: { isActive: true }
        });

        return res.json({
          success: true,
          message: 'Fornecedor reativado para o produto'
        });
      }

      return res.status(409).json({
        success: false,
        message: 'Fornecedor já está vinculado a este produto'
      });
    }

    // Criar a relação
    await prisma.productSupplier.create({
      data: {
        productId: parseInt(id),
        supplierId: parseInt(supplierId),
        isActive: true
      }
    });

    res.status(201).json({
      success: true,
      message: 'Fornecedor adicionado ao produto com sucesso'
    });

  } catch (error) {
    console.error('Erro ao adicionar fornecedor ao produto:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// DELETE /api/products/:id/suppliers/:supplierId - Remover fornecedor do produto (apenas admin)
router.delete('/:id/suppliers/:supplierId', requireRole('ADMIN'), [
  param('id')
    .notEmpty()
    .withMessage('ID do produto é obrigatório')
    .isInt({ min: 1 })
    .withMessage('ID do produto deve ser um número inteiro positivo'),
  param('supplierId')
    .notEmpty()
    .withMessage('ID do fornecedor é obrigatório')
    .isInt({ min: 1 })
    .withMessage('ID do fornecedor deve ser um número inteiro positivo')
], validate, async (req, res) => {
  try {
    const { id, supplierId } = req.params;

    // Buscar a relação
    const relation = await prisma.productSupplier.findFirst({
      where: {
        productId: parseInt(id),
        supplierId: parseInt(supplierId)
      }
    });

    if (!relation) {
      return res.status(404).json({
        success: false,
        message: 'Relação produto-fornecedor não encontrada'
      });
    }

    // Desativar a relação (soft delete)
    await prisma.productSupplier.update({
      where: { id: relation.id },
      data: { isActive: false }
    });

    res.json({
      success: true,
      message: 'Fornecedor removido do produto com sucesso'
    });

  } catch (error) {
    console.error('Erro ao remover fornecedor do produto:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

module.exports = router;
