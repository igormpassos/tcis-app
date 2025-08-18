import 'dart:convert';
import '../model/api_models.dart';
import '../model/user.dart';
import 'api_service.dart';

class DataService {
  final ApiService _apiService = ApiService();

  // ===== TERMINAIS =====
  Future<List<Terminal>> getTerminals() async {
    try {
      final response = await _apiService.get('/terminals');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return (data['data'] as List)
              .map((terminal) => Terminal.fromJson(terminal))
              .toList();
        }
      }
      throw Exception('Erro ao buscar terminais');
    } catch (e) {
      throw Exception('Erro ao buscar terminais: $e');
    }
  }

  // ===== FORNECEDORES =====
  Future<List<Supplier>> getSuppliers() async {
    try {
      final response = await _apiService.get('/suppliers');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return (data['data'] as List)
              .map((supplier) => Supplier.fromJson(supplier))
              .toList();
        }
      }
      throw Exception('Erro ao buscar fornecedores');
    } catch (e) {
      throw Exception('Erro ao buscar fornecedores: $e');
    }
  }

  Future<Supplier?> getSupplierById(int id) async {
    try {
      final response = await _apiService.get('/suppliers/$id');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return Supplier.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('Erro ao buscar fornecedor: $e');
      return null;
    }
  }

  // ===== PRODUTOS =====
  Future<List<Product>> getProducts() async {
    try {
      final response = await _apiService.get('/products');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return (data['data'] as List)
              .map((product) => Product.fromJson(product))
              .toList();
        }
      }
      throw Exception('Erro ao buscar produtos');
    } catch (e) {
      throw Exception('Erro ao buscar produtos: $e');
    }
  }

  Future<List<Product>> getProductsBySupplier(int supplierId) async {
    try {
      final response = await _apiService.get('/products?supplierId=$supplierId');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return (data['data'] as List)
              .map((product) => Product.fromJson(product))
              .toList();
        }
      }
      throw Exception('Erro ao buscar produtos do fornecedor');
    } catch (e) {
      throw Exception('Erro ao buscar produtos do fornecedor: $e');
    }
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final response = await _apiService.get('/products?category=$category');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return (data['data'] as List)
              .map((product) => Product.fromJson(product))
              .toList();
        }
      }
      throw Exception('Erro ao buscar produtos por categoria');
    } catch (e) {
      throw Exception('Erro ao buscar produtos por categoria: $e');
    }
  }

  // ===== USUÁRIOS =====
  Future<List<User>> getUsers() async {
    try {
      final response = await _apiService.get('/auth/users');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return (data['data'] as List)
              .map((user) => User.fromJson(user))
              .toList();
        }
      }
      throw Exception('Erro ao buscar usuários');
    } catch (e) {
      throw Exception('Erro ao buscar usuários: $e');
    }
  }

  // ===== CLIENTES =====
  Future<List<Client>> getClients() async {
    try {
      final response = await _apiService.get('/clients');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return (data['data'] as List)
              .map((client) => Client.fromJson(client))
              .toList();
        }
      }
      throw Exception('Erro ao buscar clientes');
    } catch (e) {
      throw Exception('Erro ao buscar clientes: $e');
    }
  }
}
