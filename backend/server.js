const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

// Importar rotas
const authRoutes = require('./routes/auth');
const reportRoutes = require('./routes/reports');
const terminalRoutes = require('./routes/terminals');
const productRoutes = require('./routes/products');
const supplierRoutes = require('./routes/suppliers');
const employeeRoutes = require('./routes/employees');
const uploadRoutes = require('./routes/uploads');

// Importar middlewares
const errorHandler = require('./middleware/errorHandler');
const { authenticateToken } = require('./middleware/auth');

const app = express();
const PORT = process.env.PORT || 3000;

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutos
  max: 1000, // limite de 1000 requests por IP por janela
  message: {
    error: 'Muitas tentativas, tente novamente em 15 minutos'
  }
});

// Middlewares globais
app.use(limiter);
app.use(helmet());
app.use(compression());
app.use(morgan('combined'));
app.use(cors({
  origin: process.env.NODE_ENV === 'production' 
    ? (process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000'])
    : true, // Permite todas as origens em desenvolvimento
  credentials: true,
  optionsSuccessStatus: 200, // Suporte para navegadores mais antigos
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Servir arquivos estáticos para uploads
app.use('/uploads', express.static('uploads'));

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    timestamp: new Date().toISOString(),
    version: '1.0.0',
    environment: process.env.NODE_ENV
  });
});

// Rotas públicas
app.use('/api/auth', authRoutes);

// Rota de teste sem autenticação
app.post('/api/test-reports', (req, res) => {
  console.log('📥 Request body:', JSON.stringify(req.body, null, 2));
  res.json({ success: true, message: 'Test OK', body: req.body });
});

// Rotas protegidas
app.use('/api/reports', authenticateToken, reportRoutes);
app.use('/api/terminals', authenticateToken, terminalRoutes);
app.use('/api/products', authenticateToken, productRoutes);
app.use('/api/suppliers', authenticateToken, supplierRoutes);
app.use('/api/employees', authenticateToken, employeeRoutes);
app.use('/api/uploads', authenticateToken, uploadRoutes);

// Rota 404
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: 'Endpoint não encontrado'
  });
});

// Error handler
app.use(errorHandler);

// Inicializar servidor
const server = app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Servidor rodando na porta ${PORT}`);
  console.log(`🌍 Ambiente: ${process.env.NODE_ENV}`);
  console.log(`📊 Health check: http://localhost:${PORT}/health`);
  console.log(`📱 Para simulador: http://192.168.1.224:${PORT}/health`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    console.log('HTTP server closed');
  });
});

module.exports = app;
