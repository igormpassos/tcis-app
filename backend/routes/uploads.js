const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const router = express.Router();
const auth = require('../middleware/auth').authenticateToken;

// Configuração do Multer para upload de arquivos
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const folderName = req.body.folder || 'general';
    const uploadPath = path.join(__dirname, '../uploads', folderName);
    
    // Criar diretório se não existir
    fs.mkdirSync(uploadPath, { recursive: true });
    cb(null, uploadPath);
  },
  filename: (req, file, cb) => {
    // Manter nome original ou usar timestamp
    const fileName = file.originalname || `${Date.now()}-${file.fieldname}.${file.mimetype.split('/')[1]}`;
    cb(null, fileName);
  }
});

const upload = multer({
  storage,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB por arquivo
  },
  fileFilter: (req, file, cb) => {
    if (file.fieldname === 'image') {
      // Aceitar apenas imagens
      if (file.mimetype.startsWith('image/')) {
        cb(null, true);
      } else {
        cb(new Error('Apenas imagens são permitidas'), false);
      }
    } else if (file.fieldname === 'pdf') {
      // Aceitar apenas PDFs
      if (file.mimetype === 'application/pdf') {
        cb(null, true);
      } else {
        cb(new Error('Apenas arquivos PDF são permitidos'), false);
      }
    } else {
      cb(new Error('Campo de arquivo não reconhecido'), false);
    }
  }
});

// POST /api/upload/image - Upload de imagem
router.post('/image', auth, upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'Nenhuma imagem foi enviada'
      });
    }

    const folderName = req.body.folder || 'general';
    const relativePath = path.join('uploads', folderName, req.file.filename);
    
    // Obter timestamp original da imagem se fornecido
    const originalTimestamp = req.body.timestamp || new Date().toISOString();
    const uploadOrder = parseInt(req.body.uploadOrder) || 0;

    // Criar arquivo de metadados para preservar a ordem cronológica
    const metadataPath = path.join(__dirname, '../uploads', folderName, `${req.file.filename}.metadata.json`);
    const metadata = {
      filename: req.file.filename,
      originalName: req.file.originalname,
      originalTimestamp: originalTimestamp,
      uploadOrder: uploadOrder,
      uploadTimestamp: new Date().toISOString(),
      size: req.file.size,
      mimetype: req.file.mimetype
    };
    
    try {
      fs.writeFileSync(metadataPath, JSON.stringify(metadata, null, 2));
    } catch (metaError) {
      console.warn('Erro ao salvar metadados da imagem:', metaError);
    }

    res.json({
      success: true,
      message: 'Imagem enviada com sucesso',
      data: {
        filename: req.file.filename,
        originalName: req.file.originalname,
        path: relativePath,
        size: req.file.size,
        mimetype: req.file.mimetype,
        folder: folderName,
        originalTimestamp: originalTimestamp,
        uploadOrder: uploadOrder
      }
    });

  } catch (error) {
    console.error('Erro no upload de imagem:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// POST /api/upload/pdf - Upload de PDF
router.post('/pdf', auth, upload.single('pdf'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'Nenhum PDF foi enviado'
      });
    }

    const folderName = req.body.folder || 'general';
    const relativePath = path.join('uploads', folderName, req.file.filename);

    res.json({
      success: true,
      message: 'PDF enviado com sucesso',
      data: {
        filename: req.file.filename,
        originalName: req.file.originalname,
        path: relativePath,
        size: req.file.size,
        mimetype: req.file.mimetype,
        folder: folderName
      }
    });

  } catch (error) {
    console.error('Erro no upload de PDF:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// POST /api/upload/multiple - Upload múltiplo
router.post('/multiple', auth, upload.array('files', 10), async (req, res) => {
  try {
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Nenhum arquivo foi enviado'
      });
    }

    const folderName = req.body.folder || 'general';
    const uploadedFiles = req.files.map(file => ({
      filename: file.filename,
      originalName: file.originalname,
      path: path.join('uploads', folderName, file.filename),
      size: file.size,
      mimetype: file.mimetype
    }));

    res.json({
      success: true,
      message: `${uploadedFiles.length} arquivos enviados com sucesso`,
      data: {
        files: uploadedFiles,
        folder: folderName,
        count: uploadedFiles.length
      }
    });

  } catch (error) {
    console.error('Erro no upload múltiplo:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// GET /api/upload/:folder/:filename - Servir arquivos
router.get('/:folder/:filename', (req, res) => {
  try {
    const { folder, filename } = req.params;
    const filePath = path.join(__dirname, '../uploads', folder, filename);

    // Verificar se o arquivo existe
    if (!fs.existsSync(filePath)) {
      return res.status(404).json({
        success: false,
        message: 'Arquivo não encontrado'
      });
    }

    // Servir o arquivo
    res.sendFile(filePath);

  } catch (error) {
    console.error('Erro ao servir arquivo:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// DELETE /api/upload/:folder/:filename - Deletar arquivo
router.delete('/:folder/:filename', auth, (req, res) => {
  try {
    const { folder, filename } = req.params;
    const filePath = path.join(__dirname, '../uploads', folder, filename);

    // Verificar se o arquivo existe
    if (!fs.existsSync(filePath)) {
      return res.status(404).json({
        success: false,
        message: 'Arquivo não encontrado'
      });
    }

    // Deletar arquivo
    fs.unlinkSync(filePath);

    // Tentar deletar arquivo de metadados associado
    const metadataPath = `${filePath}.metadata.json`;
    if (fs.existsSync(metadataPath)) {
      try {
        fs.unlinkSync(metadataPath);
      } catch (metaError) {
        console.warn('Erro ao deletar metadados:', metaError);
      }
    }

    res.json({
      success: true,
      message: 'Arquivo deletado com sucesso'
    });

  } catch (error) {
    console.error('Erro ao deletar arquivo:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

// GET /api/uploads/images/:folder/ordered - Buscar imagens de uma pasta ordenadas cronologicamente
router.get('/images/:folder/ordered', auth, (req, res) => {
  try {
    const { folder } = req.params;
    const folderPath = path.join(__dirname, '../uploads', folder);

    // Verificar se a pasta existe
    if (!fs.existsSync(folderPath)) {
      return res.json({
        success: true,
        data: [],
        message: 'Pasta não encontrada'
      });
    }

    // Buscar todos os arquivos de imagem na pasta
    const files = fs.readdirSync(folderPath);
    const imageFiles = files.filter(file => 
      /\.(jpg|jpeg|png|gif|webp)$/i.test(file) && 
      !file.endsWith('.metadata.json')
    );

    const imageList = [];

    for (const filename of imageFiles) {
      const filePath = path.join(folderPath, filename);
      const metadataPath = `${filePath}.metadata.json`;
      
      let metadata = {
        filename,
        originalTimestamp: null,
        uploadOrder: 0,
        uploadTimestamp: null
      };

      // Tentar carregar metadados se existirem
      if (fs.existsSync(metadataPath)) {
        try {
          const metaContent = fs.readFileSync(metadataPath, 'utf8');
          const metaData = JSON.parse(metaContent);
          metadata = {
            ...metadata,
            ...metaData
          };
        } catch (metaError) {
          console.warn(`Erro ao ler metadados para ${filename}:`, metaError);
        }
      }

      // Se não tiver timestamp original, usar a data de modificação do arquivo
      if (!metadata.originalTimestamp) {
        try {
          const stats = fs.statSync(filePath);
          metadata.originalTimestamp = stats.mtime.toISOString();
        } catch (statError) {
          metadata.originalTimestamp = new Date().toISOString();
        }
      }

      imageList.push({
        ...metadata,
        path: path.join('uploads', folder, filename),
        relativePath: path.join(folder, filename)
      });
    }

    // Ordenar por timestamp original, depois por ordem de upload
    imageList.sort((a, b) => {
      const timeA = new Date(a.originalTimestamp);
      const timeB = new Date(b.originalTimestamp);
      
      if (timeA.getTime() === timeB.getTime()) {
        return a.uploadOrder - b.uploadOrder;
      }
      
      return timeA.getTime() - timeB.getTime();
    });

    res.json({
      success: true,
      data: imageList,
      count: imageList.length
    });

  } catch (error) {
    console.error('Erro ao buscar imagens ordenadas:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

module.exports = router;
