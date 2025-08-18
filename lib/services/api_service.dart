import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

class ApiService {
  // Detecta automaticamente a URL baseada na plataforma
  static String get baseUrl {
    // Para web sempre usa localhost
    if (kIsWeb) {
      return ApiConfig.webUrl;
    }
    
    // Para simulador iOS usa o IP da máquina local
    if (Platform.isIOS) {
      return ApiConfig.iosUrl;
    }
    
    // Para Android
    if (Platform.isAndroid) {
      return ApiConfig.androidUrl;
    }
    
    // Para macOS e outras plataformas desktop usa localhost
    return ApiConfig.desktopUrl;
  }
  
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;

  // Headers padrão
  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    
    return headers;
  }

  // Configurar token
  void setToken(String? token) {
    _token = token;
  }

  // Salvar token no SharedPreferences
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    setToken(token);
  }

  // Carregar token do SharedPreferences
  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    setToken(token);
  }

  // Remover token
  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    setToken(null);
  }

  // Getter para o token atual
  String? get currentToken => _token;

  // Getter público para a baseUrl
  static String get apiBaseUrl => baseUrl;

  // GET request
  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    
    try {
      final response = await http.get(url, headers: _headers);
      return response;
    } catch (e) {
      throw ApiException('Erro de conexão: $e');
    }
  }

  // POST request
  Future<http.Response> post(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl$endpoint');
    
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: json.encode(data),
      );
      return response;
    } catch (e) {
      throw ApiException('Erro de conexão: $e');
    }
  }

  // PUT request
  Future<http.Response> put(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl$endpoint');
    
    try {
      final response = await http.put(
        url,
        headers: _headers,
        body: json.encode(data),
      );
      return response;
    } catch (e) {
      throw ApiException('Erro de conexão: $e');
    }
  }

  // DELETE request
  Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    
    try {
      final response = await http.delete(url, headers: _headers);
      return response;
    } catch (e) {
      throw ApiException('Erro de conexão: $e');
    }
  }

  // Verificar se está autenticado
  bool get isAuthenticated => _token != null;

  // Método request genérico
  static Future<Map<String, dynamic>> request({
    required String endpoint,
    required String method,
    Map<String, dynamic>? data,
  }) async {
    final apiService = ApiService();
    await apiService.loadToken();
    
    try {
      http.Response response;
      
      switch (method.toUpperCase()) {
        case 'GET':
          response = await apiService.get(endpoint);
          break;
        case 'POST':
          response = await apiService.post(endpoint, data ?? {});
          break;
        case 'PUT':
          response = await apiService.put(endpoint, data ?? {});
          break;
        case 'DELETE':
          response = await apiService.delete(endpoint);
          break;
        default:
          throw ApiException('Método HTTP não suportado: $method');
      }
      
      final responseData = json.decode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseData;
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Erro desconhecido',
          'data': null
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
        'data': null
      };
    }
  }

  // Logout
  Future<void> logout() async {
    await removeToken();
  }
}

// Exceção personalizada para API
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
