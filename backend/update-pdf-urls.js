const { PrismaClient } = require('@prisma/client');
const fs = require('fs');
const path = require('path');

const prisma = new PrismaClient();

async function updateReportsWithPdfUrls() {
  console.log('🔍 Procurando relatórios sem pdfUrl...');
  
  // Buscar relatórios que não têm pdfUrl
  const reportsWithoutPdfUrl = await prisma.report.findMany({
    where: {
      OR: [
        { pdfUrl: null },
        { pdfUrl: '' }
      ]
    },
    select: {
      id: true,
      prefix: true,
      createdAt: true
    }
  });
  
  console.log(`📊 Encontrados ${reportsWithoutPdfUrl.length} relatórios sem pdfUrl`);
  
  for (const report of reportsWithoutPdfUrl) {
    try {
      const createdAt = new Date(report.createdAt);
      const day = createdAt.getDate().toString().padStart(2, '0');
      const month = (createdAt.getMonth() + 1).toString().padStart(2, '0');
      const year = createdAt.getFullYear();
      const hours = createdAt.getHours().toString().padStart(2, '0');
      const minutes = createdAt.getMinutes().toString().padStart(2, '0');
      const seconds = createdAt.getSeconds().toString().padStart(2, '0');
      
      // Padrão de pasta: PREFIX-DD-MM-YYYY-HH-MM-SS
      const folderPattern = `${report.prefix}-${day}-${month}-${year}-${hours}-${minutes}-${seconds}`;
      const uploadsDir = path.join(__dirname, 'uploads');
      
      // Procurar por pastas que comecem com o padrão ou contenham o prefix
      const allFolders = fs.readdirSync(uploadsDir).filter(item => {
        const fullPath = path.join(uploadsDir, item);
        return fs.statSync(fullPath).isDirectory();
      });
      
      // Procurar por todas as pastas que contenham o prefix
      const matchingFolders = allFolders.filter(folder => {
        const folderLower = folder.toLowerCase();
        const prefixLower = report.prefix.toLowerCase();
        return folderLower.includes(prefixLower);
      });
      
      console.log(`🔍 Buscando PDF para ${report.prefix}. Pastas encontradas: ${matchingFolders.join(', ')}`);
      
      // Procurar por pastas que tenham PDFs
      let pdfFound = false;
      for (const folder of matchingFolders) {
        try {
          const folderPath = path.join(uploadsDir, folder);
          const files = fs.readdirSync(folderPath);
          const pdfFiles = files.filter(file => file.toLowerCase().endsWith('.pdf'));
          
          if (pdfFiles.length > 0) {
            const pdfFile = pdfFiles[0]; // Pega o primeiro PDF encontrado
            const pdfUrl = `http://localhost:3000/uploads/${folder}/${pdfFile}`;
            
            // Atualizar o relatório com a URL do PDF
            await prisma.report.update({
              where: { id: report.id },
              data: { pdfUrl }
            });
            
            console.log(`✅ Atualizado ${report.prefix}: ${pdfUrl}`);
            pdfFound = true;
            break; // Para no primeiro PDF encontrado
          }
        } catch (err) {
          console.log(`❌ Erro ao ler pasta ${folder}:`, err.message);
        }
      }
      
      if (!pdfFound) {
        console.log(`❌ PDF não encontrado para: ${report.prefix}`);
      }
    } catch (error) {
      console.error(`❌ Erro ao processar relatório ${report.id}:`, error);
    }
  }
  
  console.log('🎉 Script finalizado!');
  await prisma.$disconnect();
}

updateReportsWithPdfUrls().catch(console.error);
