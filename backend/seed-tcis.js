const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Inserindo dados da TCIS...');

  // Limpar dados existentes (exceto usuário admin)
  await prisma.product.deleteMany({});
  await prisma.supplier.deleteMany({});
  await prisma.terminal.deleteMany({});
  
  console.log('🗑️ Dados antigos removidos');

  // Inserir terminais
  const terminals = await Promise.all([
    prisma.terminal.create({ data: { name: 'Terminal Serra Azul', code: 'TSA', location: 'Serra Azul' }}),
    prisma.terminal.create({ data: { name: 'Sarzedo Velho (Itaminas)', code: 'SZD', location: 'Sarzedo - MG' }}),
    prisma.terminal.create({ data: { name: 'Terminal Sarzedo Novo', code: 'TCS', location: 'Sarzedo - MG' }}),
    prisma.terminal.create({ data: { name: 'Terminal Multitudo', code: 'TCM', location: 'Multitudo' }}),
    prisma.terminal.create({ data: { name: 'Terminal de Itutinga', code: 'TCI', location: 'Itutinga - MG' }})
  ]);
  console.log('🚉 Terminais inseridos:', terminals.length);

  // Inserir fornecedores
  const suppliers = await Promise.all([
    prisma.supplier.create({ data: { name: 'AVG', code: 'AVG', contact: 'Contato AVG', email: 'contato@avg.com', phone: '(31) 7777-7777', address: 'Minas Gerais' }}),
    prisma.supplier.create({ data: { name: 'ECKOMINING', code: 'EKO', contact: 'Contato EKO', email: 'contato@eckomining.com', phone: '(31) 0000-0000', address: 'Minas Gerais' }}),
    prisma.supplier.create({ data: { name: 'LHG', code: 'LHG', contact: 'Contato LHG', email: 'contato@lhg.com', phone: '(31) 5555-5555', address: 'Minas Gerais' }}),
    prisma.supplier.create({ data: { name: 'FERRO+', code: 'FER', contact: 'Contato FERRO+', email: 'contato@ferromais.com', phone: '(31) 0000-1111', address: 'Minas Gerais' }}),
    prisma.supplier.create({ data: { name: 'J.MENDES', code: 'JME', contact: 'Contato J.MENDES', email: 'contato@jmendes.com', phone: '(31) 4444-4444', address: 'Minas Gerais' }}),
    prisma.supplier.create({ data: { name: 'HERCULANO', code: 'HER', contact: 'Contato HERCULANO', email: 'contato@herculano.com', phone: '(31) 2222-2222', address: 'Minas Gerais' }}),
    prisma.supplier.create({ data: { name: 'ITAMINAS', code: 'ITA', contact: 'Contato ITAMINAS', email: 'contato@itaminas.com', phone: '(31) 1111-1111', address: 'Minas Gerais' }}),
    prisma.supplier.create({ data: { name: 'SERRA LESTE', code: 'SLE', contact: 'Contato SERRA LESTE', email: 'contato@serraleste.com', phone: '(31) 3333-3333', address: 'Minas Gerais' }}),
    prisma.supplier.create({ data: { name: 'SERRA LOPES', code: 'SLO', contact: 'Contato SERRA LOPES', email: 'contato@serralopes.com', phone: '(31) 6666-6666', address: 'Minas Gerais' }}),
    prisma.supplier.create({ data: { name: 'VETRIA', code: 'VET', contact: 'Contato VETRIA', email: 'contato@vetria.com', phone: '(31) 0000-1111', address: 'Minas Gerais' }}),
    prisma.supplier.create({ data: { name: '4B', code: '4B', contact: 'Contato 4B', email: 'contato@4b.com', phone: '(31) 9999-9999', address: 'Minas Gerais' }}),
    prisma.supplier.create({ data: { name: '3A', code: '3A', contact: 'Contato 3A', email: 'contato@3a.com', phone: '(31) 1111-2222', address: 'Minas Gerais' }}),
    prisma.supplier.create({ data: { name: 'BEMISA', code: 'BEM', contact: 'Contato BEMISA', email: 'contato@bemisa.com', phone: '(31) 8888-8888', address: 'Minas Gerais' }}),
    prisma.supplier.create({ data: { name: 'MINERITA', code: 'MIN', contact: 'Contato MINERITA', email: 'contato@minerita.com', phone: '(31) 2222-4444', address: 'Minas Gerais' }}),
    prisma.supplier.create({ data: { name: 'Outro', code: 'OUT', contact: 'Contato Genérico', email: 'contato@outro.com', phone: '(31) 2222-3333', address: 'Diversos' }})
  ]);
  console.log('🏭 Fornecedores inseridos:', suppliers.length);

  // Criar mapa de fornecedores por nome para facilitar relacionamento
  const supplierMap = {};
  suppliers.forEach(supplier => {
    supplierMap[supplier.name] = supplier.id;
  });

  // Inserir produtos com relacionamentos corretos
  const products = await Promise.all([
    // AVG
    prisma.product.create({ data: { name: 'FFVG', code: 'FFVG', category: 'Minério de Ferro', description: 'Produto da AVG', supplierId: supplierMap['AVG'] }}),
    prisma.product.create({ data: { name: 'FLVG', code: 'FLVG', category: 'Minério de Ferro', description: 'Produto da AVG', supplierId: supplierMap['AVG'] }}),
    
    // ECKOMINING
    prisma.product.create({ data: { name: 'FSEC', code: 'FSEC', category: 'Minério de Ferro', description: 'Produto da ECKOMINING', supplierId: supplierMap['ECKOMINING'] }}),
    prisma.product.create({ data: { name: 'FSE2', code: 'FSE2', category: 'Minério de Ferro', description: 'Produto da ECKOMINING', supplierId: supplierMap['ECKOMINING'] }}),
    prisma.product.create({ data: { name: 'GRANULADO (EKO)', code: 'GRAN_EKO', category: 'Minério de Ferro', description: 'Granulado da ECKOMINING', supplierId: supplierMap['ECKOMINING'] }}),
    
    // LHG
    prisma.product.create({ data: { name: 'GRANULADO (LHG)', code: 'GRAN_LHG', category: 'Minério de Ferro', description: 'Granulado da LHG', supplierId: supplierMap['LHG'] }}),
    prisma.product.create({ data: { name: 'GRANULADO/SINTER (LHG)', code: 'GRAN_SINT_LHG', category: 'Minério de Ferro', description: 'Granulado/Sinter da LHG', supplierId: supplierMap['LHG'] }}),
    
    // FERRO+
    prisma.product.create({ data: { name: 'FMFM', code: 'FMFM', category: 'Minério de Ferro', description: 'Produto FERRO+', supplierId: supplierMap['FERRO+'] }}),
    
    // J.MENDES
    prisma.product.create({ data: { name: 'FFJM', code: 'FFJM', category: 'Minério de Ferro', description: 'Produto da J.MENDES', supplierId: supplierMap['J.MENDES'] }}),
    prisma.product.create({ data: { name: 'FFJM/FMFM', code: 'FFJM_FMFM', category: 'Minério de Ferro', description: 'Produto misto J.MENDES', supplierId: supplierMap['J.MENDES'] }}),
    prisma.product.create({ data: { name: 'FHJM/FMFM', code: 'FHJM_FMFM', category: 'Minério de Ferro', description: 'Produto misto J.MENDES', supplierId: supplierMap['J.MENDES'] }}),
    
    // HERCULANO
    prisma.product.create({ data: { name: 'F1MH', code: 'F1MH', category: 'Minério de Ferro', description: 'Produto da HERCULANO', supplierId: supplierMap['HERCULANO'] }}),
    
    // ITAMINAS
    prisma.product.create({ data: { name: 'FSIT', code: 'FSIT', category: 'Minério de Ferro', description: 'Produto da ITAMINAS', supplierId: supplierMap['ITAMINAS'] }}),
    
    // SERRA LESTE
    prisma.product.create({ data: { name: 'FFSL', code: 'FFSL', category: 'Minério de Ferro', description: 'Produto da SERRA LESTE', supplierId: supplierMap['SERRA LESTE'] }}),
    
    // SERRA LOPES
    prisma.product.create({ data: { name: 'FSML', code: 'FSML', category: 'Minério de Ferro', description: 'Produto da SERRA LOPES', supplierId: supplierMap['SERRA LOPES'] }}),
    
    // VETRIA
    prisma.product.create({ data: { name: 'GRANULADO (VETRIA)', code: 'GRAN_VET', category: 'Minério de Ferro', description: 'Granulado da VETRIA', supplierId: supplierMap['VETRIA'] }}),
    
    // 4B
    prisma.product.create({ data: { name: 'GRANULADO (4B)', code: 'GRAN_4B', category: 'Minério de Ferro', description: 'Granulado da 4B', supplierId: supplierMap['4B'] }}),
    
    // 3A
    prisma.product.create({ data: { name: 'GRANULADO (3A)', code: 'GRAN_3A', category: 'Minério de Ferro', description: 'Granulado da 3A', supplierId: supplierMap['3A'] }}),
    
    // BEMISA
    prisma.product.create({ data: { name: 'FMBE', code: 'FMBE', category: 'Minério de Ferro', description: 'Produto da BEMISA', supplierId: supplierMap['BEMISA'] }}),
    
    // MINERITA
    prisma.product.create({ data: { name: 'FNMT', code: 'FNMT', category: 'Minério de Ferro', description: 'Produto da MINERITA', supplierId: supplierMap['MINERITA'] }}),
    
    // Outro
    prisma.product.create({ data: { name: 'Outro', code: 'OUTRO', category: 'Diversos', description: 'Outros produtos', supplierId: supplierMap['Outro'] }})
  ]);
  console.log('📦 Produtos inseridos:', products.length);

  console.log('✅ Dados da TCIS inseridos com sucesso!');
}

main()
  .catch((e) => {
    throw e;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
