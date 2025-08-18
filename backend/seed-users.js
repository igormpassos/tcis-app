const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcrypt');
const prisma = new PrismaClient();

async function insertUsers() {
  console.log('👥 Inserindo colaboradores da TCIS...');

  // Lista de colaboradores
  const colaboradores = [
    { name: 'Lucas Euzébio', username: 'lucas.euzebio', role: 'USER' },
    { name: 'Luan Pereira', username: 'luan.pereira', role: 'USER' },
    { name: 'Gabriel Gonzaga', username: 'gabriel.gonzaga', role: 'USER' },
    { name: 'Willian', username: 'willian', role: 'USER' },
    { name: 'Rogério Gonçalves', username: 'rogerio.goncalves', role: 'USER' },
    { name: 'Moizes Ferreira', username: 'moizes.ferreira', role: 'USER' },
    { name: 'Paulo Rezende', username: 'paulo.rezende', role: 'ADMIN' }, // ADM e Colaborador
    { name: 'João Paulo Lacerda', username: 'joao.lacerda', role: 'ADMIN' }, // ADM e Colaborador
    { name: 'Alexandre Neuton', username: 'alexandre.neuton', role: 'USER' },
    { name: 'Warlley Lopes', username: 'warlley.lopes', role: 'USER' }
  ];

  // Senha padrão para todos (pode ser alterada depois)
  const defaultPassword = await bcrypt.hash('tcis2025', 10);

  // Inserir colaboradores
  for (const colaborador of colaboradores) {
    try {
      await prisma.user.create({
        data: {
          username: colaborador.username,
          name: colaborador.name,
          email: `${colaborador.username}@tcis.com`,
          password: defaultPassword,
          role: colaborador.role,
          active: true
        }
      });
      console.log(`✅ ${colaborador.name} (${colaborador.role})`);
    } catch (error) {
      if (error.code === 'P2002') {
        console.log(`⚠️  ${colaborador.name} já existe`);
      } else {
        console.error(`❌ Erro ao inserir ${colaborador.name}:`, error.message);
      }
    }
  }

  console.log('✅ Colaboradores inseridos!');
  console.log('');
  console.log('📋 Credenciais de acesso:');
  console.log('Username: [username] | Senha: tcis2025');
  console.log('');
  console.log('👑 Administradores:');
  console.log('- tcis (senha: tcis)');
  console.log('- paulo.rezende (senha: tcis2025)');
  console.log('- joao.lacerda (senha: tcis2025)');
}

insertUsers()
  .catch((e) => {
    console.error('Erro:', e);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
