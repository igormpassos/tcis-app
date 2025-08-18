const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const router = express.Router();
const auth = require('../middleware/auth');

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

    res.json({
      success: true,
      message: 'Imagem enviada com sucesso',
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

module.exports = router;
