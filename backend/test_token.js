const jwt = require('jsonwebtoken');

const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjgsInVzZXJuYW1lIjoicGF1bG8ucmV6ZW5kZSIsInJvbGUiOiJBRE1JTiIsImlhdCI6MTc1NTU2MjM3NCwiZXhwIjoxNzU1NjQ4Nzc0fQ.HwYpmCupN-T2_e5-5UL5nLdKjHMwG7igrCxro3iMnUA';

try {
  const decoded = jwt.verify(token, process.env.JWT_SECRET || 'tcis_jwt_secret_key_super_secure_2024');
  console.log('Token decodificado:', decoded);
  console.log('Role:', decoded.role);
  console.log('User ID:', decoded.userId);
} catch (error) {
  console.error('Erro ao decodificar token:', error.message);
}
