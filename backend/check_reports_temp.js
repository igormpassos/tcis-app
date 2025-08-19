const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function checkReports() {
  try {
    const reports = await prisma.report.findMany({
      select: {
        id: true,
        prefix: true,
        userId: true,
        user: {
          select: {
            id: true,
            name: true,
            username: true,
            role: true
          }
        }
      }
    });
    
    console.log('Relatórios encontrados:', reports.length);
    reports.forEach(report => {
      console.log(`- ${report.prefix} (User ID: ${report.userId}) - ${report.user.name} (${report.user.role})`);
    });
  } catch (error) {
    console.error('Erro:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

checkReports();
