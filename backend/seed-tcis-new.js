const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Inserindo dados genéricos do sistema...');

  // Limpar dados existentes (exceto usuário admin)
  await prisma.productSupplier.deleteMany({});
  await prisma.report.deleteMany({});
  await prisma.client.deleteMany({});
  await prisma.user.deleteMany({ where: { role: 'USER' } });
  await prisma.product.deleteMany({});
  await prisma.supplier.deleteMany({});
  await prisma.terminal.deleteMany({});
  
  console.log('🗑️ Dados antigos removidos');

  // Inserir terminais genéricos
  const terminals = await Promise.all([
    prisma.terminal.create({ data: { name: 'Terminal Norte', code: 'TNR', location: 'Região Norte', prefix: 'TNR-1' }}),
    prisma.terminal.create({ data: { name: 'Terminal Sul', code: 'TSL', location: 'Região Sul', prefix: 'TSL-1' }}),
    prisma.terminal.create({ data: { name: 'Terminal Leste', code: 'TLS', location: 'Região Leste', prefix: 'TLS-1' }}),
    prisma.terminal.create({ data: { name: 'Terminal Oeste', code: 'TOE', location: 'Região Oeste', prefix: 'TOE-1' }}),
    prisma.terminal.create({ data: { name: 'Terminal Central', code: 'TCT', location: 'Região Central', prefix: 'TCT-1' }}),
    prisma.terminal.create({ data: { name: 'Terminal Portuário', code: 'TPT', location: 'Porto Principal', prefix: 'TPT-1' }})
  ]);
  console.log('🚉 Terminais inseridos:', terminals.length);

  // Inserir fornecedores genéricos
  const suppliers = await Promise.all([
    prisma.supplier.create({ data: { name: 'Fornecedor Alpha', code: 'ALP', contact: 'Contato Alpha', email: 'contato@alpha.com', phone: '(11) 1111-1111', address: 'São Paulo - SP' }}),
    prisma.supplier.create({ data: { name: 'Fornecedor Beta', code: 'BET', contact: 'Contato Beta', email: 'contato@beta.com', phone: '(21) 2222-2222', address: 'Rio de Janeiro - RJ' }}),
    prisma.supplier.create({ data: { name: 'Fornecedor Gamma', code: 'GAM', contact: 'Contato Gamma', email: 'contato@gamma.com', phone: '(31) 3333-3333', address: 'Belo Horizonte - MG' }}),
    prisma.supplier.create({ data: { name: 'Fornecedor Delta', code: 'DEL', contact: 'Contato Delta', email: 'contato@delta.com', phone: '(41) 4444-4444', address: 'Curitiba - PR' }}),
    prisma.supplier.create({ data: { name: 'Fornecedor Epsilon', code: 'EPS', contact: 'Contato Epsilon', email: 'contato@epsilon.com', phone: '(51) 5555-5555', address: 'Porto Alegre - RS' }}),
    prisma.supplier.create({ data: { name: 'Fornecedor Zeta', code: 'ZET', contact: 'Contato Zeta', email: 'contato@zeta.com', phone: '(61) 6666-6666', address: 'Brasília - DF' }}),
    prisma.supplier.create({ data: { name: 'Fornecedor Eta', code: 'ETA', contact: 'Contato Eta', email: 'contato@eta.com', phone: '(71) 7777-7777', address: 'Salvador - BA' }}),
    prisma.supplier.create({ data: { name: 'Fornecedor Theta', code: 'THE', contact: 'Contato Theta', email: 'contato@theta.com', phone: '(81) 8888-8888', address: 'Recife - PE' }}),
    prisma.supplier.create({ data: { name: 'Fornecedor Iota', code: 'IOT', contact: 'Contato Iota', email: 'contato@iota.com', phone: '(85) 9999-9999', address: 'Fortaleza - CE' }}),
    prisma.supplier.create({ data: { name: 'Fornecedor Kappa', code: 'KAP', contact: 'Contato Kappa', email: 'contato@kappa.com', phone: '(62) 1010-1010', address: 'Goiânia - GO' }}),
  ]);
  console.log('🏭 Fornecedores inseridos:', suppliers.length);

  // Criar mapa de fornecedores por nome para facilitar relacionamento
  const supplierMap = {};
  suppliers.forEach(supplier => {
    supplierMap[supplier.name] = supplier.id;
  });

  // Inserir produtos genéricos
  const products = await Promise.all([
    // Produtos Alpha
    prisma.product.create({ data: { name: 'Material A1', code: 'MAT_A1', category: 'Matéria Prima', description: 'Material tipo A1 do Fornecedor Alpha' }}),
    prisma.product.create({ data: { name: 'Material A2', code: 'MAT_A2', category: 'Matéria Prima', description: 'Material tipo A2 do Fornecedor Alpha' }}),
    
    // Produtos Beta
    prisma.product.create({ data: { name: 'Material B1', code: 'MAT_B1', category: 'Matéria Prima', description: 'Material tipo B1 do Fornecedor Beta' }}),
    prisma.product.create({ data: { name: 'Material B2', code: 'MAT_B2', category: 'Matéria Prima', description: 'Material tipo B2 do Fornecedor Beta' }}),
    prisma.product.create({ data: { name: 'Granulado Beta', code: 'GRAN_B', category: 'Processado', description: 'Granulado do Fornecedor Beta' }}),
    
    // Produtos Gamma
    prisma.product.create({ data: { name: 'Granulado Gamma', code: 'GRAN_G', category: 'Processado', description: 'Granulado do Fornecedor Gamma' }}),
    prisma.product.create({ data: { name: 'Material G1', code: 'MAT_G1', category: 'Semi-processado', description: 'Material G1 do Fornecedor Gamma' }}),
    
    // Produtos Delta
    prisma.product.create({ data: { name: 'Material D1', code: 'MAT_D1', category: 'Matéria Prima', description: 'Material D1 do Fornecedor Delta' }}),
    
    // Produtos Epsilon
    prisma.product.create({ data: { name: 'Material E1', code: 'MAT_E1', category: 'Matéria Prima', description: 'Material E1 do Fornecedor Epsilon' }}),
    prisma.product.create({ data: { name: 'Composto E1/D1', code: 'COMP_E1D1', category: 'Composto', description: 'Material composto Epsilon/Delta' }}),
    
    // Produtos Zeta
    prisma.product.create({ data: { name: 'Material Z1', code: 'MAT_Z1', category: 'Processado', description: 'Material Z1 do Fornecedor Zeta' }}),
    
    // Produtos Eta
    prisma.product.create({ data: { name: 'Material H1', code: 'MAT_H1', category: 'Matéria Prima', description: 'Material H1 do Fornecedor Eta' }}),
    
    // Produtos Theta
    prisma.product.create({ data: { name: 'Material T1', code: 'MAT_T1', category: 'Semi-processado', description: 'Material T1 do Fornecedor Theta' }}),
    
    // Produtos Iota
    prisma.product.create({ data: { name: 'Granulado Iota', code: 'GRAN_I', category: 'Processado', description: 'Granulado do Fornecedor Iota' }}),
    
    // Produtos Kappa
    prisma.product.create({ data: { name: 'Material K1', code: 'MAT_K1', category: 'Matéria Prima', description: 'Material K1 do Fornecedor Kappa' }}),
    
    // Produto genérico
    prisma.product.create({ data: { name: 'Outros Materiais', code: 'OUTROS', category: 'Diversos', description: 'Outros tipos de materiais' }})
  ]);
  console.log('📦 Produtos inseridos:', products.length);

  // Criar relacionamentos Product-Supplier (many-to-many)
  console.log('🔗 Criando relacionamentos produto-fornecedor...');
  
  const productSupplierRelations = [
    // Alpha
    { productName: 'Material A1', supplierName: 'Fornecedor Alpha' },
    { productName: 'Material A2', supplierName: 'Fornecedor Alpha' },
    
    // Beta
    { productName: 'Material B1', supplierName: 'Fornecedor Beta' },
    { productName: 'Material B2', supplierName: 'Fornecedor Beta' },
    { productName: 'Granulado Beta', supplierName: 'Fornecedor Beta' },
    
    // Gamma
    { productName: 'Granulado Gamma', supplierName: 'Fornecedor Gamma' },
    { productName: 'Material G1', supplierName: 'Fornecedor Gamma' },
    
    // Delta
    { productName: 'Material D1', supplierName: 'Fornecedor Delta' },
    
    // Epsilon
    { productName: 'Material E1', supplierName: 'Fornecedor Epsilon' },
    { productName: 'Composto E1/D1', supplierName: 'Fornecedor Epsilon' },
    
    // Zeta
    { productName: 'Material Z1', supplierName: 'Fornecedor Zeta' },
    
    // Eta
    { productName: 'Material H1', supplierName: 'Fornecedor Eta' },
    
    // Theta
    { productName: 'Material T1', supplierName: 'Fornecedor Theta' },
    
    // Iota
    { productName: 'Granulado Iota', supplierName: 'Fornecedor Iota' },
    
    // Kappa
    { productName: 'Material K1', supplierName: 'Fornecedor Kappa' },
    
    // Genérico
    { productName: 'Outros Materiais', supplierName: 'Fornecedor Alpha' }
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
  console.log('👥 Criando usuários...');
  const saltRounds = 10;
  const hashedPassword = await bcrypt.hash('123456', saltRounds);
  
  const users = await Promise.all([
    prisma.user.upsert({
      where: { username: 'admin' },
      update: {
        password: hashedPassword,
        email: 'admin@sistema.com',
        name: 'Administrador do Sistema',
        role: 'ADMIN'
      },
      create: {
        username: 'admin',
        password: hashedPassword,
        email: 'admin@sistema.com',
        name: 'Administrador do Sistema',
        role: 'ADMIN'
      }
    }),
    prisma.user.upsert({
      where: { username: 'operador' },
      update: {
        password: hashedPassword,
        email: 'operador@sistema.com',
        name: 'Operador do Sistema',
        role: 'USER'
      },
      create: {
        username: 'operador',
        password: hashedPassword,
        email: 'operador@sistema.com',
        name: 'Operador do Sistema',
        role: 'USER'
      }
    }),
    
  ]);
  console.log('👥 Usuários criados:', users.length);

  // Criar clientes
  console.log('🏢 Criando clientes...');
  const clients = await Promise.all([
    prisma.client.create({
      data: {
        name: 'Empresa Cliente Principal',
        contact: 'contato@cliente.com',
        emails: ['recebimento@cliente.com', 'qualidade@cliente.com', 'compras@cliente.com']
      }
    }),
    prisma.client.create({
      data: {
        name: 'Indústria ABC Ltda',
        contact: 'contato@industriaabc.com',
        emails: ['logistica@industriaabc.com', 'suprimentos@industriaabc.com']
      }
    }),
    
  ]);
  console.log('🏢 Clientes criados:', clients.length);

  console.log('✅ Dados genéricos inseridos com sucesso!');
}

main()
  .catch((e) => {
    console.error('❌ Erro ao executar seed:', e);
    throw e;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
