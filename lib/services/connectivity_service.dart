import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();
  static bool? _lastConnectionStatus;
  static DateTime? _lastCheck;
  static const Duration _cacheTimeout = Duration(seconds: 5);
  
  // Hosts para testar conectividade (mais rápidos que DNS lookup)
  static const List<String> _testHosts = [
    '8.8.8.8', // Google DNS
    '1.1.1.1', // Cloudflare DNS
  ];

  /// Verifica se há conexão com a internet
  static Future<bool> hasInternetConnection() async {
    // No ambiente web, sempre considera como online
    if (kIsWeb) {
      return true;
    }
    
    // Usa cache se a verificação foi feita recentemente
    if (_lastConnectionStatus != null && 
        _lastCheck != null && 
        DateTime.now().difference(_lastCheck!) < _cacheTimeout) {
      return _lastConnectionStatus!;
    }
    
    try {
      // Primeiro verifica o tipo de conexão - mais rápido
      final List<ConnectivityResult> connectivityResult = 
          await _connectivity.checkConnectivity();
      
      // Se não há conexão de rede, retorna false imediatamente
      if (connectivityResult.contains(ConnectivityResult.none)) {
        _lastConnectionStatus = false;
        _lastCheck = DateTime.now();
        return false;
      }
      
      // Para Android, tenta uma abordagem mais rápida
      if (Platform.isAndroid) {
        final bool hasConnection = await _testInternetConnectionFast();
        _lastConnectionStatus = hasConnection;
        _lastCheck = DateTime.now();
        return hasConnection;
      }
      
      // Para outras plataformas, usa o método tradicional
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      final bool hasConnection = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      _lastConnectionStatus = hasConnection;
      _lastCheck = DateTime.now();
      return hasConnection;
    } catch (e) {
      _lastConnectionStatus = false;
      _lastCheck = DateTime.now();
      return false;
    }
  }

  /// Teste rápido de conectividade para Android
  static Future<bool> _testInternetConnectionFast() async {
    for (String host in _testHosts) {
      try {
        final socket = await Socket.connect(host, 53, timeout: const Duration(seconds: 2));
        socket.destroy();
        return true;
      } catch (e) {
        continue;
      }
    }
    return false;
  }

  /// Stream para monitorar mudanças de conectividade com verificação real
  static Stream<bool> onInternetConnectivityChanged() {
    // No ambiente web, retorna um stream que sempre indica conexão
    if (kIsWeb) {
      return Stream.periodic(const Duration(seconds: 1), (_) => true);
    }
    
    return _connectivity.onConnectivityChanged.asyncMap((_) async {
      // Limpa o cache quando há mudança de conectividade
      _lastConnectionStatus = null;
      _lastCheck = null;
      return await hasInternetConnection();
    });
  }

  /// Stream para monitorar mudanças de conectividade (apenas tipo de rede)
  static Stream<List<ConnectivityResult>> onConnectivityChanged() {
    // No ambiente web, retorna um stream que sempre indica conexão
    if (kIsWeb) {
      return Stream.value([ConnectivityResult.wifi]);
    }
    return _connectivity.onConnectivityChanged;
  }

  /// Verifica conectividade específica (WiFi, Mobile, etc)
  static Future<bool> hasWifiConnection() async {
    // No ambiente web, sempre considera como WiFi
    if (kIsWeb) {
      return true;
    }
    
    final List<ConnectivityResult> connectivityResult = 
        await _connectivity.checkConnectivity();
    return connectivityResult.contains(ConnectivityResult.wifi);
  }

  /// Verifica se está usando dados móveis
  static Future<bool> hasMobileConnection() async {
    // No ambiente web, nunca considera como dados móveis
    if (kIsWeb) {
      return false;
    }
    
    final List<ConnectivityResult> connectivityResult = 
        await _connectivity.checkConnectivity();
    return connectivityResult.contains(ConnectivityResult.mobile);
  }

  /// Força uma nova verificação de conectividade (ignora cache)
  static Future<bool> forceCheckInternetConnection() async {
    _lastConnectionStatus = null;
    _lastCheck = null;
    return await hasInternetConnection();
  }

  /// Limpa o cache de conectividade
  static void clearCache() {
    _lastConnectionStatus = null;
    _lastCheck = null;
  }

  /// Obtém o status da última verificação (pode ser null)
  static bool? get lastConnectionStatus => _lastConnectionStatus;
}
