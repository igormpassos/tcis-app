const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcrypt');
const prisma = new PrismaClient();

async function checkUsers() {
  try {
    console.log('🔍 Checking users in database...');
    
    const users = await prisma.user.findMany({
      select: {
        id: true,
        username: true,
        name: true,
        email: true,
        role: true,
        active: true,
        password: true // Para verificar se está encriptada
      }
    });
    
    console.log(`Found ${users.length} users:`);
    
    for (const user of users) {
      console.log(`\n👤 User:`);
      console.log(`   ID: ${user.id}`);
      console.log(`   Username: ${user.username}`);
      console.log(`   Name: ${user.name}`);
      console.log(`   Email: ${user.email}`);
      console.log(`   Role: ${user.role}`);
      console.log(`   Active: ${user.active}`);
      console.log(`   Password hash: ${user.password.substring(0, 20)}...`);
      
      // Testar se a senha "tcis" funciona para este usuário
      if (user.username === 'tcis') {
        const isValidPassword = await bcrypt.compare('tcis', user.password);
        console.log(`   Password 'tcis' matches: ${isValidPassword}`);
      }
    }
    
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await prisma.$disconnect();
  }
}

checkUsers();
