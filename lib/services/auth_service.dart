import 'dart:convert';
import '../model/user.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  // Login
  Future<AuthResponse> login(String username, String password) async {
    try {
      final response = await _apiService.post('/auth/login', {
        'username': username,
        'password': password,
      });

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(data);
        
        // Salvar token se login for bem-sucedido
        if (authResponse.success && authResponse.token != null) {
          await _apiService.saveToken(authResponse.token!);
        }
        
        return authResponse;
      } else {
        return AuthResponse(
          success: false,
          message: data['message'] ?? 'Erro no login',
        );
      }
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Erro de conexão: $e',
      );
    }
  }

  // Registro (se necessário futuramente)
  Future<AuthResponse> register({
    required String username,
    required String password,
    required String name,
    String? email,
  }) async {
    try {
      final response = await _apiService.post('/auth/register', {
        'username': username,
        'password': password,
        'name': name,
        'email': email,
      });

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        final authResponse = AuthResponse.fromJson(data);
        
        if (authResponse.success && authResponse.token != null) {
          await _apiService.saveToken(authResponse.token!);
        }
        
        return authResponse;
      } else {
        return AuthResponse(
          success: false,
          message: data['message'] ?? 'Erro no registro',
        );
      }
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Erro de conexão: $e',
      );
    }
  }

  // Obter perfil do usuário
  Future<User?> getProfile() async {
    try {
      final response = await _apiService.get('/auth/profile');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return User.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('Erro ao buscar perfil: $e');
      return null;
    }
  }

  // Alterar senha
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _apiService.put('/auth/change-password', {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });

      final data = json.decode(response.body);
      return response.statusCode == 200 && data['success'];
    } catch (e) {
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _apiService.logout();
  }

  // Verificar se está autenticado
  bool get isAuthenticated => _apiService.isAuthenticated;

  // Inicializar (carregar token salvo)
  Future<void> initialize() async {
    await _apiService.loadToken();
  }
}
