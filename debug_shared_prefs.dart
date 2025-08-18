// Script para debugar o SharedPreferences

void main() {
  print('=== DEBUG SHARED PREFERENCES ===');
  print('Este script deveria ser executado em um device real, mas vamos mostrar como verificar os dados.');
  print('');
  print('Para verificar os dados no simulador iOS:');
  print('1. Acesse: ~/Library/Developer/CoreSimulator/Devices/[DEVICE_ID]/data/Containers/Data/Application/[APP_ID]/Documents/');
  print('2. Ou use o debugger do Flutter para inspecionar SharedPreferences.getStringList("full_reports")');
  print('');
  print('Estrutura esperada dos relatórios:');
  print('{');
  print('  "id": "uuid",');
  print('  "prefixo": "NFL 1234",');
  print('  "colaborador": "Nome do Inspetor",');
  print('  "status": 0 ou 1,');
  print('  "dataCriacao": "2025-01-15T...",');
  print('  ...outros campos');
  print('}');
  print('');
  print('Problemas possíveis:');
  print('1. Colaborador sendo salvo como null ou vazio');
  print('2. Relatórios duplicados com IDs diferentes');
  print('3. Status não sendo atualizado corretamente');
}
