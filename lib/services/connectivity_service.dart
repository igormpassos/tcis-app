import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';

class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();

  /// Verifica se há conexão com a internet
  static Future<bool> hasInternetConnection() async {
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
    return _connectivity.onConnectivityChanged;
  }

  /// Verifica conectividade específica (WiFi, Mobile, etc)
  static Future<bool> hasWifiConnection() async {
    final List<ConnectivityResult> connectivityResult = 
        await _connectivity.checkConnectivity();
    return connectivityResult.contains(ConnectivityResult.wifi);
  }

  /// Verifica se está usando dados móveis
  static Future<bool> hasMobileConnection() async {
    final List<ConnectivityResult> connectivityResult = 
        await _connectivity.checkConnectivity();
    return connectivityResult.contains(ConnectivityResult.mobile);
  }
}
