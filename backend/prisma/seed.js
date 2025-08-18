const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Iniciando seed do banco de dados...');

  // Criar usuário admin
  const hashedPassword = await bcrypt.hash('tcis', 10);
  
  const adminUser = await prisma.user.upsert({
    where: { username: 'tcis' },
    update: {},
    create: {
      username: 'tcis',
      password: hashedPassword,
      name: 'Administrador TCIS',
      email: 'admin@tcis.com',
      role: 'ADMIN'
    },
  });

  console.log('👤 Usuário admin criado:', adminUser);

  // Criar terminais
  const terminals = [
    { name: 'Terminal Santos', code: 'TS001', location: 'Santos - SP' },
    { name: 'Terminal Rio de Janeiro', code: 'TRJ001', location: 'Rio de Janeiro - RJ' },
    { name: 'Terminal Vitória', code: 'TV001', location: 'Vitória - ES' },
    { name: 'Terminal Paranaguá', code: 'TP001', location: 'Paranaguá - PR' }
  ];

  for (const terminal of terminals) {
    await prisma.terminal.upsert({
      where: { code: terminal.code },
      update: {},
      create: terminal,
    });
  }

  console.log('🚉 Terminais criados');

  // Criar produtos
  const products = [
    { name: 'Minério de Ferro', code: 'MF001', category: 'Mineração', description: 'Minério de ferro para exportação' },
    { name: 'Soja', code: 'SJ001', category: 'Agronegócio', description: 'Soja em grãos' },
    { name: 'Milho', code: 'ML001', category: 'Agronegócio', description: 'Milho em grãos' },
    { name: 'Açúcar', code: 'AC001', category: 'Agronegócio', description: 'Açúcar refinado' },
    { name: 'Celulose', code: 'CL001', category: 'Papel e Celulose', description: 'Celulose para exportação' }
  ];

  for (const product of products) {
    await prisma.product.upsert({
      where: { code: product.code },
      update: {},
      create: product,
    });
  }

  console.log('📦 Produtos criados');

  // Criar fornecedores
  const suppliers = [
    {
      name: 'Vale S.A.',
      code: 'VALE001',
      contact: 'João Silva',
      email: 'contato@vale.com',
      phone: '(11) 3333-4444',
      address: 'Rio de Janeiro - RJ'
    },
    {
      name: 'Cargill',
      code: 'CAR001',
      contact: 'Maria Santos',
      email: 'contato@cargill.com',
      phone: '(11) 2222-3333',
      address: 'São Paulo - SP'
    },
    {
      name: 'ADM do Brasil',
      code: 'ADM001',
      contact: 'Pedro Oliveira',
      email: 'contato@adm.com',
      phone: '(11) 1111-2222',
      address: 'São Paulo - SP'
    }
  ];

  for (const supplier of suppliers) {
    await prisma.supplier.upsert({
      where: { code: supplier.code },
      update: {},
      create: supplier,
    });
  }

  console.log('🏭 Fornecedores criados');

  // Criar funcionários
  const employees = [
    {
      name: 'Carlos Mendes',
      code: 'EMP001',
      position: 'Inspetor de Carga',
      email: 'carlos@tcis.com',
      phone: '(11) 9999-8888'
    },
    {
      name: 'Ana Costa',
      code: 'EMP002',
      position: 'Supervisora de Terminal',
      email: 'ana@tcis.com',
      phone: '(11) 8888-7777'
    },
    {
      name: 'Roberto Lima',
      code: 'EMP003',
      position: 'Inspetor de Carga',
      email: 'roberto@tcis.com',
      phone: '(11) 7777-6666'
    }
  ];

  for (const employee of employees) {
    await prisma.employee.upsert({
      where: { code: employee.code },
      update: {},
      create: employee,
    });
  }

  console.log('👥 Funcionários criados');

  console.log('✅ Seed concluído com sucesso!');
}

main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (e) => {
    console.error('❌ Erro durante o seed:', e);
    await prisma.$disconnect();
    process.exit(1);
  });
