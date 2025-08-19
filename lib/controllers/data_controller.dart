import 'package:flutter/material.dart';
import '../model/api_models.dart';
import '../model/user.dart';
import '../services/data_service.dart';

class DataController extends ChangeNotifier {
  final DataService _dataService = DataService();
  
  List<Terminal> _terminals = [];
  List<Product> _products = [];
  List<Supplier> _suppliers = [];
  List<User> _users = [];
  List<Client> _clients = [];

  bool _isLoadingTerminals = false;
  bool _isLoadingProducts = false;
  bool _isLoadingSuppliers = false;
  bool _isLoadingUsers = false;
  bool _isLoadingClients = false;  String? _errorMessage;

  // Getters
  List<Terminal> get terminals => _terminals;
  List<Product> get products => _products;
  List<Supplier> get suppliers => _suppliers;
  List<User> get users => _users;
  List<Client> get clients => _clients;

  bool get isLoadingTerminals => _isLoadingTerminals;
  bool get isLoadingProducts => _isLoadingProducts;
  bool get isLoadingSuppliers => _isLoadingSuppliers;
  bool get isLoadingUsers => _isLoadingUsers;
  bool get isLoadingClients => _isLoadingClients;  String? get errorMessage => _errorMessage;

  // Carregar todos os dados
  Future<void> loadAllData() async {
    await Future.wait([
      loadTerminals(),
      loadProducts(),
      loadSuppliers(),
      loadUsers(),
      loadClients(),
    ]);
  }

  // ===== TERMINAIS =====
  Future<void> loadTerminals() async {
    _isLoadingTerminals = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _terminals = await _dataService.getTerminals();
    } catch (e) {
      _errorMessage = 'Erro ao carregar terminais: $e';
    } finally {
      _isLoadingTerminals = false;
      notifyListeners();
    }
  }

  Terminal? getTerminalById(int id) {
    try {
      return _terminals.firstWhere((terminal) => terminal.id == id);
    } catch (e) {
      return null;
    }
  }

  // ===== FORNECEDORES =====
  Future<void> loadSuppliers() async {
    _isLoadingSuppliers = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _suppliers = await _dataService.getSuppliers();
    } catch (e) {
      _errorMessage = 'Erro ao carregar fornecedores: $e';
    } finally {
      _isLoadingSuppliers = false;
      notifyListeners();
    }
  }

  Supplier? getSupplierById(int id) {
    try {
      return _suppliers.firstWhere((supplier) => supplier.id == id);
    } catch (e) {
      return null;
    }
  }

  // ===== PRODUTOS =====
  Future<void> loadProducts() async {
    _isLoadingProducts = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _products = await _dataService.getProducts();
    } catch (e) {
      _errorMessage = 'Erro ao carregar produtos: $e';
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  Product? getProductById(int id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Product> getProductsBySupplier(int supplierId) {
    return _products.where((product) {
      // Verifica se o produto tem fornecedores e se o supplierId está na lista
      return product.suppliers?.any((supplier) => supplier.id == supplierId) ?? false;
    }).toList();
  }

  List<Product> getProductsByCategory(String category) {
    return _products.where((product) => product.category == category).toList();
  }

  // ===== COLABORADORES =====
  Future<void> loadUsers() async {
    _isLoadingUsers = true;
    notifyListeners();

    try {
      _users = await _dataService.getUsers();
    } catch (e) {
      _errorMessage = 'Erro ao carregar usuários: $e';
    } finally {
      _isLoadingUsers = false;
      notifyListeners();
    }
  }

  User? getUserById(int id) {
    try {
      return _users.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }

  // ===== UTILITÁRIOS =====
  
  // Limpar erro
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Refresh específico
  Future<void> refreshTerminals() => loadTerminals();
  Future<void> refreshSuppliers() => loadSuppliers();
  Future<void> refreshProducts() => loadProducts();
  Future<void> refreshUsers() => loadUsers();

  // ===== CLIENTES =====
  Future<void> loadClients() async {
    _isLoadingClients = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loadedClients = await _dataService.getClients();
      _clients = loadedClients;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erro ao carregar clientes: $e';
      _clients = [];
    } finally {
      _isLoadingClients = false;
      notifyListeners();
    }
  }

  // Método para atualizar clientes
  Future<void> refreshClients() => loadClients();

  // Obter categorias únicas de produtos
  List<String> get productCategories {
    final categories = _products
        .where((product) => product.category != null)
        .map((product) => product.category!)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  // Verificar se dados básicos foram carregados
  bool get hasBasicData => 
    _terminals.isNotEmpty && 
    _suppliers.isNotEmpty && 
    _products.isNotEmpty;
}
