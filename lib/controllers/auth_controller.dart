import 'package:flutter/material.dart';
import '../model/user.dart';
import '../services/auth_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.role == 'ADMIN';

  // Inicializar controller
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.initialize();
      
      if (_authService.isAuthenticated) {
        _currentUser = await _authService.getProfile();
      }
    } catch (e) {
      _errorMessage = 'Erro ao inicializar: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.login(username, password);
      
      if (response.success) {
        _currentUser = response.user;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erro no login: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      _currentUser = null;
    } catch (e) {
      _errorMessage = 'Erro no logout: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Alterar senha
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      
      if (success) {
        _errorMessage = null;
      } else {
        _errorMessage = 'Erro ao alterar senha';
      }
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Erro ao alterar senha: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Limpar erro
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Obter token atual
  String? getToken() {
    return _authService.currentToken;
  }

  // Atualizar perfil do usuário
  Future<void> refreshProfile() async {
    if (_authService.isAuthenticated) {
      try {
        _currentUser = await _authService.getProfile();
        notifyListeners();
      } catch (e) {
        _errorMessage = 'Erro ao atualizar perfil: $e';
        notifyListeners();
      }
    }
  }
}
