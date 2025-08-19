const { PrismaClient } = require('@prisma/client');

async function migrateDatos() {
  const prisma = new PrismaClient();

  try {
    console.log('🔄 Iniciando migração dos dados produto-fornecedor...');

    // 1. Primeiro, vamos buscar todos os produtos que têm supplierId
    const productsWithSuppliers = await prisma.product.findMany({
      where: {
        supplierId: {
          not: null
        }
      },
      include: {
        supplier: true
      }
    });

    console.log(`📊 Encontrados ${productsWithSuppliers.length} produtos com fornecedores para migrar`);

    // 2. Criar a tabela ProductSupplier se não existir
    await prisma.$executeRaw`
      CREATE TABLE IF NOT EXISTS "product_suppliers" (
        id SERIAL PRIMARY KEY,
        "productId" INTEGER NOT NULL,
        "supplierId" INTEGER NOT NULL,
        "isActive" BOOLEAN DEFAULT true,
        "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        "updatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE("productId", "supplierId"),
        FOREIGN KEY ("productId") REFERENCES "products"(id) ON DELETE CASCADE,
        FOREIGN KEY ("supplierId") REFERENCES "suppliers"(id) ON DELETE CASCADE
      );
    `;

    console.log('✅ Tabela product_suppliers criada');

    // 3. Migrar os dados existentes para a nova tabela
    for (const product of productsWithSuppliers) {
      if (product.supplierId) {
        // Verificar se a relação já existe
        const existing = await prisma.$queryRaw`
          SELECT id FROM "product_suppliers" 
          WHERE "productId" = ${product.id} AND "supplierId" = ${product.supplierId}
        `;

        if (existing.length === 0) {
          await prisma.$executeRaw`
            INSERT INTO "product_suppliers" ("productId", "supplierId", "isActive", "createdAt", "updatedAt")
            VALUES (${product.id}, ${product.supplierId}, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
          `;
          
          console.log(`✅ Migrado: ${product.name} → ${product.supplier.name}`);
        }
      }
    }

    // 4. Remover a coluna supplierId da tabela products
    await prisma.$executeRaw`ALTER TABLE "products" DROP COLUMN IF EXISTS "supplierId";`;
    
    console.log('✅ Coluna supplierId removida da tabela products');
    
    console.log('🎉 Migração concluída com sucesso!');

  } catch (error) {
    console.error('❌ Erro durante a migração:', error);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

migrateDatos();
