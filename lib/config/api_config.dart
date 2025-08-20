// Configuração centralizada da API
class ApiConfig {
  // IP atual da máquina (atualizar quando necessário)
  static const String _localIp = '192.168.1.224';
  static const String _port = '3000';
  
  // URLs base para diferentes ambientes
  static const String _baseUrl = '/api';
  static const String _prodUrl = 'https://projetos-tcis-api.fzhijv.easypanel.host';
  
  // Detectar ambiente automaticamente
  static bool get isProduction {
    const bool.fromEnvironment('dart.vm.product', defaultValue: false);
    // Para Flutter Web, verifica se está rodando em produção
    return const bool.fromEnvironment('dart.vm.product', defaultValue: false) ||
           Uri.base.host != 'localhost';
  }
  
  // URL base dinâmica baseada no ambiente
  static String get baseUrl {
    if (isProduction) {
      // Em produção, retorna a URL do backend
      return _prodUrl;
    } else {
      // Em desenvolvimento, retorna localhost
      return _getDevBaseUrl();
    }
  }
  
  static String _getDevBaseUrl() {
    // Para desenvolvimento web (sempre localhost)
    return 'http://localhost:$_port$_baseUrl';
  }
  
  // URLs específicas por plataforma (mantidas para compatibilidade)
  static const String webUrl = 'http://localhost:$_port$_baseUrl';
  static const String iosUrl = 'http://$_localIp:$_port$_baseUrl';
  static const String desktopUrl = 'http://localhost:$_port$_baseUrl';
  static const String androidUrl = 'http://$_localIp:$_port$_baseUrl';
  
  // URLs de health check
  static String get healthCheckUrl {
    if (isProduction) {
      return '/health';
    } else {
      return 'http://localhost:$_port/health';
    }
  }
  
  static const String webHealthCheck = 'http://localhost:$_port/health';
  static const String networkHealthCheck = 'http://$_localIp:$_port/health';
  
  // Informações
  static const String currentIp = _localIp;
  static const String port = _port;
}
