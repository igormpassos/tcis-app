const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcrypt');
const prisma = new PrismaClient();

async function createUser() {
  try {
    console.log('👤 Creating user tcis...');
    
    // Hash da senha
    const hashedPassword = await bcrypt.hash('tcis', 10);
    
    const user = await prisma.user.upsert({
      where: { username: 'tcis' },
      update: {},
      create: {
        username: 'tcis',
        name: 'TCIS Administrator',
        email: 'admin@tcis.com',
        password: hashedPassword,
        role: 'ADMIN',
        active: true
      }
    });
    
    console.log('✅ User created/updated successfully:');
    console.log(`   ID: ${user.id}`);
    console.log(`   Username: ${user.username}`);
    console.log(`   Name: ${user.name}`);
    console.log(`   Email: ${user.email}`);
    console.log(`   Role: ${user.role}`);
    console.log(`   Active: ${user.active}`);
    
    // Testar o login
    console.log('\n🔐 Testing login...');
    const isValidPassword = await bcrypt.compare('tcis', user.password);
    console.log(`Password 'tcis' is valid: ${isValidPassword}`);
    
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await prisma.$disconnect();
  }
}

createUser();
