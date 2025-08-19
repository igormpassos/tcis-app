# **CSI606-2025-01 - Remoto - Proposta de Trabalho Final**

## *Discente: Igor Marques Passos - 22.2.8118*

### Resumo

O trabalho final apresenta o desenvolvimento de um Sistema de Gerenciamento de Relatórios de Inspeção de Carga (TCIS), uma aplicação mobile multiplataforma desenvolvida em Flutter com backend Node.js. O sistema permite o gerenciamento completo de relatórios de inspeção, incluindo criação, edição, visualização e administração de dados relacionados como usuários, terminais, produtos e fornecedores. A aplicação oferece funcionalidades offline para criação de relatórios e sincronização automática quando há conexão disponível.

### 1. Tema

O trabalho final tem como tema o desenvolvimento de um **Sistema de Gerenciamento de Relatórios de Inspeção de Carga (TCIS)** - uma aplicação mobile que permite aos inspetores de carga criar, gerenciar e sincronizar relatórios de inspeção de materiais em terminais portuários e ferroviários.

### 2. Escopo

Este projeto terá as seguintes funcionalidades:

#### 2.1 Funcionalidades do Sistema Mobile (Flutter)
- **Autenticação de usuários** com sistema de roles (USER/ADMIN)
- **Criação de relatórios de inspeção** com dados completos:
  - Informações de terminal, produto, fornecedor
  - Dados de chegada/saída, tipo de vagão
  - Condições da carga (contaminação, umidade, chuva)
  - Captura e anexo de imagens
  - Observações detalhadas
- **Modo offline** para criação de relatórios sem conexão
- **Sincronização automática** com servidor quando conectado
- **Visualização e edição** de relatórios existentes
- **Sistema de filtros e busca** para localização de relatórios

#### 2.2 Funcionalidades Administrativas
- **Gerenciamento de usuários** (criação, edição, desativação)
- **Cadastro de terminais** com códigos e prefixos personalizados
- **Gestão de produtos** e seus códigos identificadores
- **Controle de fornecedores** e suas informações
- **Dashboard administrativo** com estatísticas
- **Visualização de todos os relatórios** do sistema

#### 2.3 Backend e API (Node.js/Express)
- **API RESTful completa** para todas as operações
- **Banco de dados PostgreSQL** com Prisma ORM
- **Autenticação JWT** com controle de sessões
- **Sistema de upload de imagens** com validação
- **Geração automática de prefixos** para relatórios
- **Controle de acesso baseado em roles**
- **Validação robusta** de dados e relacionamentos

### 3. Restrições

Neste trabalho não serão considerados:

- **Integração com sistemas externos** de terceiros
- **Notificações push** em tempo real
- **Relatórios analíticos avançados** com gráficos complexos
- **Sistema de aprovação/workflow** para relatórios
- **Backup automático** em nuvem
- **Suporte para múltiplos idiomas** (internacionalização)
- **Funcionalidades de geolocalização** GPS
- **Sistema de chat** ou comunicação entre usuários

### 4. Protótipo

Protótipos para as principais telas foram elaborados e implementados, incluindo:

- **Tela de Login** com autenticação segura
- **Dashboard Principal** com navegação intuitiva
- **Formulário de Criação de Relatórios** com todos os campos necessários
- **Tela de Visualização de Relatórios** com filtros e busca
- **Painel Administrativo** para gestão do sistema
- **Telas de Gerenciamento** (usuários, terminais, produtos, fornecedores)

As telas implementadas seguem padrões de UI/UX modernos com Material Design, garantindo uma experiência consistente e profissional.

#### 4.1 Tecnologias Utilizadas
- **Frontend Mobile:** Flutter 3.7.2+ (Dart)
- **Backend:** Node.js com Express.js
- **Banco de Dados:** PostgreSQL
- **ORM:** Prisma
- **Autenticação:** JWT (JSON Web Tokens)
- **Arquitetura:** Clean Architecture com Provider (State Management)

#### 4.2 Repositório do Projeto
O código-fonte completo está disponível em: https://github.com/igormpassos/tcis-app

### 5. Referências

FLUTTER. Flutter Documentation. Disponível em: https://docs.flutter.dev/. Acesso em: 19 ago. 2025.

NODEJS. Node.js Documentation. Disponível em: https://nodejs.org/en/docs/. Acesso em: 19 ago. 2025.

PRISMA. Prisma ORM Documentation. Disponível em: https://www.prisma.io/docs. Acesso em: 19 ago. 2025.

POSTGRESQL. PostgreSQL Documentation. Disponível em: https://www.postgresql.org/docs/. Acesso em: 19 ago. 2025.
