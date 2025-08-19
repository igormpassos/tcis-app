const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function seedClients() {
  try {
    console.log('🌱 Seeding clients...');
    
    const clients = [
      {
        name: 'CSN - Companhia Siderúrgica Nacional',
        contact: '+55 24 3355-6000',
        emails: ['fornecedores@csn.com.br', 'qualidade@csn.com.br']
      },
    ];

    for (const client of clients) {
      const existingClient = await prisma.client.findUnique({
        where: { name: client.name }
      });

      if (!existingClient) {
        await prisma.client.create({
          data: client
        });
        console.log(`✅ Cliente criado: ${client.name}`);
      } else {
        console.log(`⚠️  Cliente já existe: ${client.name}`);
      }
    }

    console.log('✅ Seed de clientes concluído!');
  } catch (error) {
    console.error('❌ Erro ao fazer seed dos clientes:', error);
  } finally {
    await prisma.$disconnect();
  }
}

seedClients();
