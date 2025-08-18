// Configuração centralizada da API
class ApiConfig {
  // IP atual da máquina (atualizar quando necessário)
  static const String _localIp = '192.168.1.224';
  static const String _port = '3000';
  
  // URLs base para diferentes ambientes
  static const String _baseUrl = '/api';
  
  // Para desenvolvimento web (sempre localhost)
  static const String webUrl = 'http://localhost:$_port$_baseUrl';
  
  // Para simulador iOS (usa IP da máquina local)
  static const String iosUrl = 'http://$_localIp:$_port$_baseUrl';
  
  // Para macOS e outras plataformas desktop
  static const String desktopUrl = 'http://localhost:$_port$_baseUrl';
  
  // Para Android (pode usar 10.0.2.2 no emulador ou IP real no dispositivo)
  static const String androidUrl = 'http://$_localIp:$_port$_baseUrl';
  
  // URLs de health check
  static const String webHealthCheck = 'http://localhost:$_port/health';
  static const String networkHealthCheck = 'http://$_localIp:$_port/health';
  
  // Informações
  static const String currentIp = _localIp;
  static const String port = _port;
}
