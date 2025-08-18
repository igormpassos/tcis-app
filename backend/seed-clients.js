const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function seedClients() {
  try {
    console.log('🌱 Seeding clients...');
    
    const clients = [
      {
        name: 'ArcelorMittal',
        contact: '+55 27 3348-1000',
        emails: ['compras@amt.com.br', 'logistica@amt.com.br']
      },
      {
        name: 'CSN - Companhia Siderúrgica Nacional',
        contact: '+55 24 3355-6000',
        emails: ['fornecedores@csn.com.br', 'qualidade@csn.com.br']
      },
      {
        name: 'Usiminas',
        contact: '+55 31 3499-8000',
        emails: ['suprimentos@usiminas.com', 'contratos@usiminas.com']
      },
      {
        name: 'Gerdau',
        contact: '+55 51 3323-2000',
        emails: ['compras@gerdau.com.br', 'inspetoria@gerdau.com.br']
      },
      {
        name: 'Vale S.A.',
        contact: '+55 21 3485-3333',
        emails: ['fornecedores@vale.com', 'logistica@vale.com']
      }
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
