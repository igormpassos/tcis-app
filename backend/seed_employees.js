const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function seedEmployees() {
  try {
    console.log('👥 Creating employees...');
    
    const employees = [
      { name: 'João Silva', code: 'JS001', position: 'Técnico de Qualidade', email: 'joao.silva@tcis.com' },
      { name: 'Maria Santos', code: 'MS002', position: 'Supervisora de Operações', email: 'maria.santos@tcis.com' },
      { name: 'Pedro Oliveira', code: 'PO003', position: 'Operador de Terminal', email: 'pedro.oliveira@tcis.com' },
      { name: 'Ana Costa', code: 'AC004', position: 'Analista de Qualidade', email: 'ana.costa@tcis.com' },
      { name: 'Carlos Ferreira', code: 'CF005', position: 'Coordenador de Logística', email: 'carlos.ferreira@tcis.com' }
    ];
    
    for (const employee of employees) {
      const created = await prisma.employee.upsert({
        where: { code: employee.code },
        update: {},
        create: employee
      });
      console.log(`✅ Created/Updated employee: ${created.name} (${created.code})`);
    }
    
    console.log('\n🎉 Employees seeded successfully!');
    
    // Listar employees criados
    const allEmployees = await prisma.employee.findMany();
    console.log(`\n📊 Total employees in database: ${allEmployees.length}`);
    
  } catch (error) {
    console.error('❌ Error seeding employees:', error);
  } finally {
    await prisma.$disconnect();
  }
}

seedEmployees();
