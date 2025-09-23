# Sistema de Envio de Relatórios com Retry Inteligente

## 📋 Visão Geral

Este documento descreve o novo sistema robusto de envio de relatórios implementado para resolver o problema de registros duplicados e falhas durante o processo de submissão.

## 🎯 Problemas Resolvidos

### ❌ Problemas Anteriores:
- **Registros duplicados**: Múltiplos cliques criavam vários registros no banco
- **Falhas sem retry**: Erro em qualquer etapa resultava em falha completa
- **Perda de progresso**: Usuário precisava recomeçar do zero após erros
- **Falta de feedback**: Usuário não sabia em que etapa ocorreu o erro

### ✅ Soluções Implementadas:
- **Proteção contra duplicação**: Controle de estado impede múltiplas submissões
- **Sistema de retry inteligente**: Continua de onde parou após falhas
- **Controle de etapas**: Rastreamento detalhado do progresso
- **Feedback visual**: Interface clara mostrando progresso e erros

## 🏗️ Arquitetura do Sistema

### Componentes Principais:

1. **ReportSubmissionManager** 
   - Gerencia o estado da submissão
   - Controla retry e recuperação
   - Singleton por sessão

2. **ReportSubmissionProgressDialog**
   - Interface visual do progresso
   - Mostra etapas em tempo real
   - Permite cancelamento

3. **ReportSubmissionRetryDialog**
   - Interface para retry após falhas
   - Mostra informações de progresso
   - Opções de retry ou cancelamento

4. **ReportApiService (atualizado)**
   - Método `submitReportWithManager()` 
   - Integração com gerenciador de estado
   - Tratamento de erros específicos

## 🔄 Fluxo de Processo

### Etapas do Envio:
1. **Validação** - Validar dados do formulário
2. **Criação** - Criar registro no banco de dados
3. **Upload de Imagens** - Enviar imagens para servidor
4. **Geração de PDF** - Gerar PDF com dados e imagens
5. **Upload de PDF** - Enviar PDF para servidor
6. **Finalização** - Atualizar registro com URLs finais

### Estados Possíveis:
- `idle` - Aguardando início
- `validating` - Validando dados
- `creating` - Criando registro
- `uploadingImages` - Enviando imagens
- `generatingPdf` - Gerando PDF
- `uploadingPdf` - Enviando PDF
- `updating` - Finalizando
- `completed` - Concluído com sucesso
- `failed` - Falhou (pode retry)

## 🛡️ Sistema de Proteção

### Prevenção de Duplicação:
```dart
// Controle de estado global
bool _isSubmitting = false;

// Proteção no início do método
if (_isSubmitting) return;
```

### Gerenciador Singleton:
```dart
// Um gerenciador por sessão
ReportSubmissionManager.getInstance(sessionId)

// Limpeza automática após conclusão
ReportSubmissionManager.clearSession(sessionId)
```

## 🔄 Sistema de Retry

### Tipos de Erro Identificados:
- `validation` - Dados inválidos (não permite retry)
- `network` - Problemas de conexão (permite retry)
- `server` - Erro no servidor (permite retry)
- `upload` - Falha de upload (permite retry)
- `pdf` - Erro na geração de PDF (permite retry)
- `unknown` - Erro não identificado (permite retry)

### Comportamento do Retry:
- **Máximo de tentativas**: 3 (configurável)
- **Recuperação inteligente**: Continua da etapa que falhou
- **Preservação de dados**: Mantém dados já obtidos (IDs, URLs)
- **Interface intuitiva**: Usuário escolhe se quer tentar novamente

### Exemplo de Recuperação:
```
Tentativa 1: FALHOU na etapa "Upload de PDF"
├─ ✅ Registro criado (ID: abc123)
├─ ✅ Imagens enviadas (2 arquivos)
├─ ✅ PDF gerado
└─ ❌ Upload do PDF falhou

Tentativa 2: CONTINUA do "Upload do PDF"
├─ ⏭️ Pula registro (já existe)
├─ ⏭️ Pula imagens (já enviadas)
├─ ⏭️ Pula geração PDF (já gerado)
└─ 🔄 Retenta upload do PDF
```

## 📱 Interface do Usuário

### Dialog de Progresso:
- Lista visual das etapas com status
- Indicador de progresso circular
- Informações de retry (se aplicável)
- Botão de cancelar (quando apropriado)

### Dialog de Retry:
- Mensagem de erro detalhada
- Informações sobre progresso atual
- Contador de tentativas
- Opções: "Tentar Novamente" ou "Cancelar"

## 🧪 Testes e Validação

### Script de Teste:
```bash
# Execute o script de teste
./test_retry_system.sh
```

### Cenários de Teste:
1. **Erro de Rede**: Simula desconexão durante envio
2. **Erro de Servidor**: Testa retry com servidor inacessível
3. **Upload Grande**: Valida timeout e retry de arquivos grandes
4. **Múltiplos Cliques**: Verifica proteção contra duplicação

### Testes Manuais:
- Interromper conexão durante diferentes etapas
- Forçar erros no servidor
- Testar com arquivos grandes
- Verificar comportamento em conexões lentas

## 🔧 Configuração e Customização

### Parâmetros Configuráveis:
```dart
// Número máximo de tentativas
final int maxRetries = 3;

// Timeout para uploads
const Duration uploadTimeout = Duration(minutes: 5);

// Tamanho máximo de arquivo
const int maxFileSize = 50 * 1024 * 1024; // 50MB
```

### Mensagens Personalizáveis:
```dart
// Mensagens de erro por tipo
Map<ErrorType, String> errorMessages = {
  ErrorType.network: 'Problema de conexão. Verificar internet.',
  ErrorType.server: 'Servidor temporariamente indisponível.',
  ErrorType.upload: 'Falha no envio do arquivo.',
  // ...
};
```

## 📊 Monitoramento e Logs

### Logs Detalhados:
```dart
// Logs automáticos de cada etapa
debugPrint('ReportSubmission (sessionId): currentStep - message');
```

### Informações de Debug:
```dart
// Método para obter estado completo
Map<String, dynamic> info = manager.getProgressInfo();
```

### Métricas Disponíveis:
- Taxa de sucesso por etapa
- Número médio de tentativas
- Tipos de erro mais comuns
- Tempo médio por etapa

## 🚀 Deploy e Produção

### Checklist de Deploy:
- [ ] Testar todos os cenários de retry
- [ ] Validar comportamento em conexões lentas
- [ ] Verificar logs do servidor
- [ ] Confirmar limpeza de sessões
- [ ] Testar em diferentes dispositivos

### Monitoramento Recomendado:
- Logs de falhas por tipo de erro
- Tempo médio de processamento
- Taxa de retry vs. sucesso
- Feedback dos usuários

## 📝 Notas de Implementação

### Pontos Importantes:
1. **Thread Safety**: Gerenciador usa estado isolado por sessão
2. **Memory Management**: Limpeza automática após conclusão
3. **Error Handling**: Tratamento específico por tipo de erro
4. **User Experience**: Feedback claro em cada etapa

### Limitações:
1. Retry limitado a 3 tentativas (configurável)
2. Sessões não persistem entre reinicializações do app
3. Arquivos temporários dependem do sistema operacional

### Melhorias Futuras:
1. Persistência de sessões em storage local
2. Retry exponential backoff
3. Upload em chunks para arquivos grandes
4. Compressão automática de imagens
5. Cache inteligente de dados já enviados

## 🆘 Troubleshooting

### Problemas Comuns:

#### "Operação já em andamento"
- **Causa**: Tentativa de nova submissão enquanto outra está ativa
- **Solução**: Aguardar conclusão ou cancelar operação atual

#### "Limite de tentativas excedido"
- **Causa**: Falhas persistentes após 3 tentativas
- **Solução**: Verificar conectividade e tentar mais tarde

#### "Erro de validação"
- **Causa**: Dados do formulário inválidos
- **Solução**: Corrigir campos obrigatórios antes de enviar

#### "Falha no upload de imagens"
- **Causa**: Arquivos grandes ou conexão lenta
- **Solução**: Verificar tamanho dos arquivos e conexão

### Logs para Investigação:
```bash
# Flutter logs
flutter logs

# Backend logs (se aplicável)
cd backend && npm run logs

# Sistema logs (iOS)
Console.app -> Device

# Sistema logs (Android)
adb logcat
```

## 📞 Suporte

Para problemas ou dúvidas sobre o sistema de retry:

1. Consulte este README primeiro
2. Execute o script de teste para reproduzir problemas
3. Colete logs detalhados
4. Reporte problemas com informações completas

---

**Versão**: 1.0  
**Data**: Setembro 2025  
**Compatibilidade**: Flutter 3.x, Dart 3.x