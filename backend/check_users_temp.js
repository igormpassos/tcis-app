const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function checkUsers() {
  try {
    const users = await prisma.user.findMany();
    console.log('Usuários encontrados:', users.length);
    users.forEach(user => {
      console.log(`- ${user.name || user.username} (${user.role})`);
    });
  } catch (error) {
    console.error('Erro:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

checkUsers();
