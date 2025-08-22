# 📋 Instruções de Execução - Sistema TCIS

## **CSI606-2024-02 - Trabalho Final**
**Discente:** Igor Marques Passos (22.2.8118)  
**Sistema:** Gerenciamento de Relatórios de Inspeção de Carga

---

## 🎯 **Execução Rápida (Recomendado)**

Para iniciar o sistema automaticamente, execute:

```bash
./iniciar-tcis.sh
```

Este script irá:
- Verificar todas as dependências
- Configurar e iniciar o backend automaticamente
- Configurar o banco de dados com dados de teste
- Iniciar o Flutter no Chrome
- Mostrar todas as URLs e credenciais

---

## 📋 **Pré-requisitos**

### **Dependências Obrigatórias:**
1. **Node.js** (versão 18+) - [Baixar aqui](https://nodejs.org/)
2. **Flutter SDK** (versão 3.7.2+) - [Baixar aqui](https://flutter.dev/docs/get-started/install)
3. **Google Chrome** (para execução web)

### **Banco de Dados (Opcional):**
- O sistema funciona com **SQLite** por padrão (sem configuração adicional)
- Para PostgreSQL, configure as variáveis de ambiente no arquivo `.env`

---

## 🚀 **Execução Manual (Passo a Passo)**

### **1. Preparar o Backend**
```bash
# Navegar para o diretório do backend
cd backend

# Instalar dependências
npm install

# Configurar banco de dados
npx prisma generate
npx prisma migrate deploy  # ou: npx prisma db push
npm run seed

# Iniciar servidor
npm start
```

### **2. Preparar o Frontend (Flutter)**
```bash
# Voltar para o diretório raiz
cd ..

# Instalar dependências do Flutter
flutter pub get

# Executar no Chrome
flutter run -d chrome
```

---

## 🌐 **URLs do Sistema**

| Serviço | URL | Descrição |
|---------|-----|-----------|
| **App Web** | http://localhost:8080 | Interface principal do sistema |
| **API Backend** | http://localhost:3000 | Servidor da aplicação |
| **Health Check** | http://localhost:3000/health | Verificar status da API |

---

## 👥 **Credenciais de Teste**

### **Administrador:**
- **Usuário:** `admin`
- **Senha:** `123456`
- **E-mail:** admin@sistema.com
- **Perfil:** Acesso total ao sistema + painel administrativo

### **Operador:**
- **Usuário:** `operador`
- **Senha:** `123456`
- **E-mail:** operador@sistema.com
- **Perfil:** Criação e visualização de relatórios

---

## **Solução de Problemas**

### **Erro: "comando não encontrado"**
```bash
# Verificar se Node.js está instalado
node --version

# Verificar se Flutter está instalado
flutter --version

# Verificar se Chrome está disponível
flutter devices
```

### **Backend não inicia**
```bash
# Verificar se a porta 3000 está livre
lsof -i :3000

# Matar processos na porta 3000
kill -9 $(lsof -ti:3000)

# Verificar logs do backend
cd backend && npm start
```

### **Flutter não abre no Chrome**
```bash
# Verificar dispositivos disponíveis
flutter devices

# Limpar cache do Flutter
flutter clean && flutter pub get

# Executar com mais detalhes
flutter run -d chrome -v
```

### **Erro no banco de dados**
```bash
cd backend

# Resetar banco de dados
rm -f prisma/dev.db
npx prisma db push
npm run seed
```

---

## **Para Parar o Sistema**

- **Script automático:** Pressione `Ctrl+C` no terminal
- **Manual:** Encerre os processos do backend e Flutter nos respectivos terminais

---

## 📞 **Suporte**

Para dúvidas sobre o sistema:
- **Repositório:** https://github.com/igormpassos/tcis-app
- **E-mail:** igor.passos@aluno.ufop.edu.br

---

## 📝 **Notas Importantes**

1. **Primeira execução** pode demorar alguns minutos para instalar dependências
2. **Chrome** deve estar instalado para execução web
3. **Dados são persistentes** entre execuções
4. **Logs** estão visíveis no terminal para debugging
5. **Sistema otimizado** para demonstração acadêmica

---

*Sistema desenvolvido como Trabalho Final da disciplina CSI606 - Sistemas Web - UFOP*
