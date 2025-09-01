const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Inserindo dados da TCIS...');

  // Limpar dados existentes (exceto usuário admin)
  await prisma.productSupplier.deleteMany({});
  await prisma.report.deleteMany({});
  await prisma.client.deleteMany({});
  await prisma.user.deleteMany({ where: { role: 'USER' } });
  await prisma.product.deleteMany({});
  await prisma.supplier.deleteMany({});
  await prisma.terminal.deleteMany({});
  
  console.log('🗑️ Dados antigos removidos');

  // Inserir terminais com prefixos
  const terminals = await Promise.all([
    prisma.terminal.create({ data: { name: 'Serra Azul', code: 'TSA', location: 'Serra Azul', prefix: 'NEL-2' }}),
    prisma.terminal.create({ data: { name: 'Sarzedo Velho (Itaminas)', code: 'SZD', location: 'Sarzedo - MG', prefix: 'NEL-1' }}),
    prisma.terminal.create({ data: { name: 'Sarzedo Novo', code: 'TCS', location: 'Sarzedo - MG', prefix: 'NEL-3' }}),
    prisma.terminal.create({ data: { name: 'Murtinho', code: 'TCM', location: 'Congonhas - MG', prefix: 'NCL-1' }}),
    prisma.terminal.create({ data: { name: 'Itutinga', code: 'TCI', location: 'Itutinga - MG', prefix: 'NFV-2' }}),
    prisma.terminal.create({ data: { name: 'Vallourec', code: 'VSB', location: '', prefix: 'VSB-1' }})
  ]);
  console.log('🚉 Terminais inseridos:', terminals.length);

  // Inserir fornecedores
  const suppliers = await Promise.all([
    prisma.supplier.create({ data: { name: 'AVG', code: 'AVG', contact: 'Suporte AVG', email: 'contato@avg.com', phone: '(31) 1111-2222', address: 'MG' }}),
    prisma.supplier.create({ data: { name: 'ECKOMINING', code: 'EKO', contact: 'Suporte ECKOMINING', email: 'contato@eckomining.com', phone: '(31) 2222-3333', address: 'MG' }}),
    prisma.supplier.create({ data: { name: 'LHG', code: 'LHG', contact: 'Suporte LHG', email: 'contato@lhg.com', phone: '(31) 3333-4444', address: 'MG' }}),
    prisma.supplier.create({ data: { name: 'FERRO+', code: 'FER', contact: 'Suporte FERRO+', email: 'contato@ferromais.com', phone: '(31) 4444-5555', address: 'MG' }}),
    prisma.supplier.create({ data: { name: 'J.MENDES', code: 'JME', contact: 'Suporte J.MENDES', email: 'contato@jmendes.com', phone: '(31) 5555-6666', address: 'MG' }}),
    prisma.supplier.create({ data: { name: 'HERCULANO', code: 'HER', contact: 'Suporte HERCULANO', email: 'contato@herculano.com', phone: '(31) 6666-7777', address: 'MG' }}),
    prisma.supplier.create({ data: { name: 'ITAMINAS', code: 'ITA', contact: 'Suporte ITAMINAS', email: 'contato@itaminas.com', phone: '(31) 7777-8888', address: 'MG' }}),
    prisma.supplier.create({ data: { name: 'SERRA LESTE', code: 'SLE', contact: 'Suporte SERRA LESTE', email: 'contato@serraleste.com', phone: '(31) 8888-9999', address: 'MG' }}),
    prisma.supplier.create({ data: { name: 'SERRA LOPES', code: 'SLO', contact: 'Suporte SERRA LOPES', email: 'contato@serralopes.com', phone: '(31) 9999-0000', address: 'MG' }}),
    prisma.supplier.create({ data: { name: 'VETRIA', code: 'VET', contact: 'Suporte VETRIA', email: 'contato@vetria.com', phone: '(31) 1010-1111', address: 'MG' }}),
    prisma.supplier.create({ data: { name: '4B', code: '4B', contact: 'Suporte 4B', email: 'contato@4b.com', phone: '(31) 1111-1212', address: 'MG' }}),
    prisma.supplier.create({ data: { name: '3A', code: '3A', contact: 'Suporte 3A', email: 'contato@3a.com', phone: '(31) 1212-1313', address: 'MG' }}),
    prisma.supplier.create({ data: { name: 'BEMISA', code: 'BEM', contact: 'Suporte BEMISA', email: 'contato@bemisa.com', phone: '(31) 1313-1414', address: 'MG' }}),
    prisma.supplier.create({ data: { name: 'MINERITA', code: 'MIN', contact: 'Suporte MINERITA', email: 'contato@minerita.com', phone: '(31) 1414-1515', address: 'MG' }}),
  ]);
  console.log('🏭 Fornecedores inseridos:', suppliers.length);

  // Criar mapa de fornecedores por nome para facilitar relacionamento
  const supplierMap = {};
  suppliers.forEach(supplier => {
    supplierMap[supplier.name] = supplier.id;
  });

  // Inserir produtos primeiro (sem relacionamentos)
  const products = await Promise.all([
    // AVG
    prisma.product.create({ data: { name: 'FFVG', code: 'FFVG', category: 'Minério de Ferro', description: 'Produto da AVG' }}),
    prisma.product.create({ data: { name: 'FLVG', code: 'FLVG', category: 'Minério de Ferro', description: 'Produto da AVG' }}),
    
    // ECKOMINING
    prisma.product.create({ data: { name: 'FSEC', code: 'FSEC', category: 'Minério de Ferro', description: 'Produto da ECKOMINING' }}),
    prisma.product.create({ data: { name: 'FSE2', code: 'FSE2', category: 'Minério de Ferro', description: 'Produto da ECKOMINING' }}),
    
    // LHG
    prisma.product.create({ data: { name: 'GRANULADO/SINTER (LHG)', code: 'GRAN_SINT_LHG', category: 'Minério de Ferro', description: 'Granulado/Sinter da LHG' }}),
    
    // FERRO+
    prisma.product.create({ data: { name: 'FMFM', code: 'FMFM', category: 'Minério de Ferro', description: 'Produto FERRO+' }}),
    
    // J.MENDES
    prisma.product.create({ data: { name: 'FFJM', code: 'FFJM', category: 'Minério de Ferro', description: 'Produto da J.MENDES' }}),
    prisma.product.create({ data: { name: 'FFJM/FMFM', code: 'FFJM_FMFM', category: 'Minério de Ferro', description: 'Produto misto J.MENDES' }}),
    prisma.product.create({ data: { name: 'FHJM/FMFM', code: 'FHJM_FMFM', category: 'Minério de Ferro', description: 'Produto misto J.MENDES' }}),
    
    // HERCULANO
    prisma.product.create({ data: { name: 'F1MH', code: 'F1MH', category: 'Minério de Ferro', description: 'Produto da HERCULANO' }}),
    
    // ITAMINAS
    prisma.product.create({ data: { name: 'FSIT', code: 'FSIT', category: 'Minério de Ferro', description: 'Produto da ITAMINAS' }}),
    
    // SERRA LESTE
    prisma.product.create({ data: { name: 'FFSL', code: 'FFSL', category: 'Minério de Ferro', description: 'Produto da SERRA LESTE' }}),
    
    // SERRA LOPES
    prisma.product.create({ data: { name: 'FSML', code: 'FSML', category: 'Minério de Ferro', description: 'Produto da SERRA LOPES' }}),
    
    // VETRIA
    
    // Produto unificado
    prisma.product.create({ data: { name: 'GRANULADO', code: 'GRAN', category: 'Minério de Ferro', description: 'Granulado de minério de ferro' }}),
    
    // BEMISA
    prisma.product.create({ data: { name: 'FMBE', code: 'FMBE', category: 'Minério de Ferro', description: 'Produto da BEMISA' }}),
    
    // MINERITA
    prisma.product.create({ data: { name: 'FNMT', code: 'FNMT', category: 'Minério de Ferro', description: 'Produto da MINERITA' }}),
    
    // Outro
    prisma.product.create({ data: { name: 'Outro', code: 'OUTRO', category: 'Diversos', description: 'Outros produtos' }})
  ]);
  console.log('📦 Produtos inseridos:', products.length);

  // Criar relacionamentos Product-Supplier (many-to-many)
  console.log('🔗 Criando relacionamentos produto-fornecedor...');
  
  const productSupplierRelations = [
    // AVG
    { productName: 'FFVG', supplierName: 'AVG' },
    { productName: 'FLVG', supplierName: 'AVG' },
    
    // ECKOMINING
    { productName: 'FSEC', supplierName: 'ECKOMINING' },
    { productName: 'FSE2', supplierName: 'ECKOMINING' },
    
    // LHG
    { productName: 'GRANULADO/SINTER (LHG)', supplierName: 'LHG' },
    
    // FERRO+
    { productName: 'FMFM', supplierName: 'FERRO+' },
    
    // J.MENDES
    { productName: 'FFJM', supplierName: 'J.MENDES' },
    { productName: 'FFJM/FMFM', supplierName: 'J.MENDES' },
    { productName: 'FHJM/FMFM', supplierName: 'J.MENDES' },
    
    // HERCULANO
    { productName: 'F1MH', supplierName: 'HERCULANO' },
    
    // ITAMINAS
    { productName: 'FSIT', supplierName: 'ITAMINAS' },
    
    // SERRA LESTE
    { productName: 'FFSL', supplierName: 'SERRA LESTE' },
    
    // SERRA LOPES
    { productName: 'FSML', supplierName: 'SERRA LOPES' },
    
    // VETRIA
    { productName: 'GRANULADO', supplierName: 'VETRIA' },
    { productName: 'GRANULADO', supplierName: '4B' },
    { productName: 'GRANULADO', supplierName: '3A' },
    { productName: 'GRANULADO', supplierName: 'ECKOMINING' },
    { productName: 'GRANULADO', supplierName: 'LHG' },
    
    // BEMISA
    { productName: 'FMBE', supplierName: 'BEMISA' },
    
    // MINERITA
    { productName: 'FNMT', supplierName: 'MINERITA' },
    
    // Outro
    { productName: 'Outro', supplierName: 'Outro' }
  ];

  // Criar mapas para facilitar busca
  const productMap = {};
  
  products.forEach(product => {
    productMap[product.name] = product.id;
  });

  // Criar relacionamentos
  for (const relation of productSupplierRelations) {
    const productId = productMap[relation.productName];
    const supplierId = supplierMap[relation.supplierName];
    
    if (productId && supplierId) {
      await prisma.productSupplier.create({
        data: {
          productId: productId,
          supplierId: supplierId
        }
      });
    }
  }
  
  console.log('🔗 Relacionamentos produto-fornecedor criados:', productSupplierRelations.length);

  // Criar usuários
  console.log('👥 Criando/atualizando usuários...');
  const saltRounds = 10;
  const hashedPassword = await bcrypt.hash('tcis', saltRounds);
  
  const users = await Promise.all([
    prisma.user.upsert({
      where: { username: 'tcis' },
      update: {
        password: hashedPassword,
        email: 'admin@tcis.com.br',
        name: 'Administrador TCIS',
        role: 'ADMIN'
      },
      create: {
        username: 'tcis',
        password: hashedPassword,
        email: 'admin@tcis.com.br',
        name: 'Administrador TCIS',
        role: 'ADMIN'
      }
    }),
    
  ]);
  console.log('👥 Usuários criados/atualizados:', users.length);

  // Criar clientes
  console.log('🏢 Criando clientes...');
  const clients = await Promise.all([
    prisma.client.create({
      data: {
        name: 'CSN - Companhia Siderúrgica Nacional',
        contact: 'contato@csn.com.br',
        emails: ['recebimento@csn.com.br', 'qualidade@csn.com.br']
      }
    }),
    
  ]);
  console.log('🏢 Clientes criados:', clients.length);

  console.log('✅ Dados da TCIS inseridos com sucesso!');
}

main()
  .catch((e) => {
    console.error('❌ Erro ao executar seed:', e);
    throw e;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
