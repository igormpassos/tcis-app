const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function checkReports() {
  try {
    console.log('🔍 Checking reports in database...');
    
    const reports = await prisma.report.findMany({
      take: 5,
      include: {
        terminal: {
          select: { id: true, name: true, code: true }
        },
        product: {
          select: { id: true, name: true, code: true }
        },
        employee: {
          select: { id: true, name: true, code: true, position: true }
        },
        supplier: {
          select: { id: true, name: true, code: true }
        },
        images: {
          select: { id: true, filename: true, originalName: true }
        }
      }
    });
    
    console.log(`Found ${reports.length} reports:`);
    
    reports.forEach((report, index) => {
      console.log(`\n📊 Report ${index + 1}:`);
      console.log(`   ID: ${report.id}`);
      console.log(`   Prefix: ${report.prefix}`);
      console.log(`   EmployeeId: ${report.employeeId}`);
      console.log(`   Employee: ${report.employee ? report.employee.name : 'NULL'}`);
      console.log(`   Terminal: ${report.terminal ? report.terminal.name : 'NULL'}`);
      console.log(`   Product: ${report.product ? report.product.name : 'NULL'}`);
      console.log(`   Images: ${report.images.length}`);
      console.log(`   ImageUrls: ${report.imageUrls.length}`);
    });
    
    // Também verificar quantos employees existem
    const employees = await prisma.employee.findMany({
      take: 5,
      select: { id: true, name: true, code: true, position: true }
    });
    
    console.log(`\n👥 Found ${employees.length} employees:`);
    employees.forEach(emp => {
      console.log(`   ID: ${emp.id}, Name: ${emp.name}, Code: ${emp.code}`);
    });
    
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await prisma.$disconnect();
  }
}

checkReports();
