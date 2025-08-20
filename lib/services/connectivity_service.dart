import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();

  /// Verifica se há conexão com a internet
  static Future<bool> hasInternetConnection() async {
    // No ambiente web, sempre considera como online
    if (kIsWeb) {
      return true;
    }
    
    try {
      // Primeiro verifica o tipo de conexão
      final List<ConnectivityResult> connectivityResult = 
          await _connectivity.checkConnectivity();
      
      // Se não há conexão de rede, retorna false
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return false;
      }
      
      // Tenta fazer um ping real para verificar se há internet
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Stream para monitorar mudanças de conectividade
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
}
