import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';

class AdminService {
  static const String baseUrl = API_BASE_URL;

  // Headers padrão com autenticação
  static Map<String, String> _getHeaders(String? token) {
    final headers = {
      'Content-Type': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  // USUÁRIOS
  static Future<Map<String, dynamic>> getUsers({
    String? token,
    int page = 1,
    int limit = 20,
    String? search,
    String? role,
    bool? active,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (role != null && role.isNotEmpty) {
        queryParams['role'] = role;
      }
      if (active != null) {
        queryParams['active'] = active.toString();
      }

      final uri = Uri.parse('$baseUrl/api/users').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erro ao carregar usuários: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  static Future<Map<String, dynamic>> createUser({
    required String token,
    required String username,
    required String password,
    String? email,
    String? name,
    String role = 'USER',
  }) async {
    try {
      final body = {
        'username': username,
        'password': password,
        'role': role,
      };
      
      if (email != null && email.isNotEmpty) body['email'] = email;
      if (name != null && name.isNotEmpty) body['name'] = name;

      final response = await http.post(
        Uri.parse('$baseUrl/api/users'),
        headers: _getHeaders(token),
        body: json.encode(body),
      );

      return json.decode(response.body);
    } catch (e) {
      throw Exception('Erro ao criar usuário: $e');
    }
  }

  static Future<Map<String, dynamic>> updateUser({
    required String token,
    required int userId,
    String? username,
    String? password,
    String? email,
    String? name,
    String? role,
    bool? active,
  }) async {
    try {
      final body = <String, dynamic>{};
      
      if (username != null) body['username'] = username;
      if (password != null && password.isNotEmpty) body['password'] = password;
      if (email != null) body['email'] = email;
      if (name != null) body['name'] = name;
      if (role != null) body['role'] = role;
      if (active != null) body['active'] = active;

      final response = await http.put(
        Uri.parse('$baseUrl/api/users/$userId'),
        headers: _getHeaders(token),
        body: json.encode(body),
      );

      return json.decode(response.body);
    } catch (e) {
      throw Exception('Erro ao atualizar usuário: $e');
    }
  }

  static Future<Map<String, dynamic>> deleteUser({
    required String token,
    required int userId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/users/$userId'),
        headers: _getHeaders(token),
      );

      return json.decode(response.body);
    } catch (e) {
      throw Exception('Erro ao deletar usuário: $e');
    }
  }

  // FORNECEDORES
  static Future<Map<String, dynamic>> getSuppliers({
    String? token,
    int page = 1,
    int limit = 20,
    String? search,
    bool? active,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (active != null) {
        queryParams['active'] = active.toString();
      }

      final uri = Uri.parse('$baseUrl/api/suppliers').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erro ao carregar fornecedores: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  static Future<Map<String, dynamic>> getSuppliersSimple({String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/suppliers/simple'),
        headers: _getHeaders(token),
      );

      return json.decode(response.body);
    } catch (e) {
      throw Exception('Erro ao buscar fornecedores: $e');
    }
  }

  static Future<Map<String, dynamic>> createSupplier({
    required String token,
    required String name,
    String? code,
    String? contact,
    String? email,
    String? phone,
    String? address,
  }) async {
    try {
      final body = {
        'name': name,
      };
      
      if (code != null && code.isNotEmpty) body['code'] = code;
      if (contact != null && contact.isNotEmpty) body['contact'] = contact;
      if (email != null && email.isNotEmpty) body['email'] = email;
      if (phone != null && phone.isNotEmpty) body['phone'] = phone;
      if (address != null && address.isNotEmpty) body['address'] = address;

      final response = await http.post(
        Uri.parse('$baseUrl/api/suppliers'),
        headers: _getHeaders(token),
        body: json.encode(body),
      );

      return json.decode(response.body);
    } catch (e) {
      throw Exception('Erro ao criar fornecedor: $e');
    }
  }

  static Future<Map<String, dynamic>> updateSupplier({
    required String token,
    required int supplierId,
    String? name,
    String? code,
    String? contact,
    String? email,
    String? phone,
    String? address,
    bool? active,
  }) async {
    try {
      final body = <String, dynamic>{};
      
      if (name != null) body['name'] = name;
      if (code != null) body['code'] = code;
      if (contact != null) body['contact'] = contact;
      if (email != null) body['email'] = email;
      if (phone != null) body['phone'] = phone;
      if (address != null) body['address'] = address;
      if (active != null) body['active'] = active;

      final response = await http.put(
        Uri.parse('$baseUrl/api/suppliers/$supplierId'),
        headers: _getHeaders(token),
        body: json.encode(body),
      );

      return json.decode(response.body);
    } catch (e) {
      throw Exception('Erro ao atualizar fornecedor: $e');
    }
  }

  static Future<Map<String, dynamic>> deleteSupplier({
    required String token,
    required int supplierId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/suppliers/$supplierId'),
        headers: _getHeaders(token),
      );

      return json.decode(response.body);
    } catch (e) {
      throw Exception('Erro ao deletar fornecedor: $e');
    }
  }

  // PRODUTOS
  static Future<Map<String, dynamic>> getProducts({
    String? token,
    int page = 1,
    int limit = 20,
    String? search,
    String? category,
    bool? active,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      if (active != null) {
        queryParams['active'] = active.toString();
      }

      final uri = Uri.parse('$baseUrl/api/products').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erro ao carregar produtos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  static Future<Map<String, dynamic>> getProductsSimple({String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/products/simple'),
        headers: _getHeaders(token),
      );

      return json.decode(response.body);
    } catch (e) {
      throw Exception('Erro ao buscar produtos: $e');
    }
  }

  static Future<Map<String, dynamic>> createProduct({
    required String token,
    required String name,
    String? code,
    String? description,
    String? category,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
      };
      
      if (code != null && code.isNotEmpty) body['code'] = code;
      if (description != null && description.isNotEmpty) body['description'] = description;
      if (category != null && category.isNotEmpty) body['category'] = category;

      final response = await http.post(
        Uri.parse('$baseUrl/api/products'),
        headers: _getHeaders(token),
        body: json.encode(body),
      );

      return json.decode(response.body);
    } catch (e) {
      throw Exception('Erro ao criar produto: $e');
    }
  }

  static Future<Map<String, dynamic>> updateProduct({
    required String token,
    required int productId,
    String? name,
    String? code,
    String? description,
    String? category,
    bool? active,
  }) async {
    try {
      final body = <String, dynamic>{};
      
      if (name != null) body['name'] = name;
      if (code != null) body['code'] = code;
      if (description != null) body['description'] = description;
      if (category != null) body['category'] = category;
      if (active != null) body['active'] = active;

      final response = await http.put(
        Uri.parse('$baseUrl/api/products/$productId'),
        headers: _getHeaders(token),
        body: json.encode(body),
      );

      return json.decode(response.body);
    } catch (e) {
      throw Exception('Erro ao atualizar produto: $e');
    }
  }

  static Future<Map<String, dynamic>> deleteProduct({
    required String token,
    required int productId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/products/$productId'),
        headers: _getHeaders(token),
      );

      return json.decode(response.body);
    } catch (e) {
      throw Exception('Erro ao deletar produto: $e');
    }
  }

  static Future<Map<String, dynamic>> addSupplierToProduct({
    required String token,
    required int productId,
    required int supplierId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/products/$productId/suppliers'),
        headers: _getHeaders(token),
        body: json.encode({'supplierId': supplierId}),
      );

      return json.decode(response.body);
    } catch (e) {
      throw Exception('Erro ao adicionar fornecedor ao produto: $e');
    }
  }

  static Future<Map<String, dynamic>> removeSupplierFromProduct({
    required String token,
    required int productId,
    required int supplierId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/products/$productId/suppliers/$supplierId'),
        headers: _getHeaders(token),
      );

      return json.decode(response.body);
    } catch (e) {
      throw Exception('Erro ao remover fornecedor do produto: $e');
    }
  }

  // TERMINAIS
  static Future<Map<String, dynamic>> getTerminals({
    String? token,
    int page = 1,
    int limit = 20,
    String? search,
    bool? active,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (active != null) {
        queryParams['active'] = active.toString();
      }

      final uri = Uri.parse('$baseUrl/api/terminals').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erro ao carregar terminais: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  static Future<Map<String, dynamic>> createTerminal({
    required String token,
    required String name,
    String? code,
    String? prefix,
    String? location,
  }) async {
    try {
      final body = {
        'name': name,
      };
      
      if (code != null && code.isNotEmpty) body['code'] = code;
      if (prefix != null && prefix.isNotEmpty) body['prefix'] = prefix;
      if (location != null && location.isNotEmpty) body['location'] = location;

      final response = await http.post(
        Uri.parse('$baseUrl/api/terminals'),
        headers: _getHeaders(token),
        body: json.encode(body),
      );

      return json.decode(response.body);
    } catch (e) {
      throw Exception('Erro ao criar terminal: $e');
    }
  }

  static Future<Map<String, dynamic>> updateTerminal({
    required String token,
    required int terminalId,
    String? name,
    String? code,
    String? prefix,
    String? location,
    bool? active,
  }) async {
    try {
      final body = <String, dynamic>{};
      
      if (name != null) body['name'] = name;
      if (code != null) body['code'] = code;
      if (prefix != null) body['prefix'] = prefix;
      if (location != null) body['location'] = location;
      if (active != null) body['active'] = active;

      final response = await http.put(
        Uri.parse('$baseUrl/api/terminals/$terminalId'),
        headers: _getHeaders(token),
        body: json.encode(body),
      );

      return json.decode(response.body);
    } catch (e) {
      throw Exception('Erro ao atualizar terminal: $e');
    }
  }

  static Future<Map<String, dynamic>> deleteTerminal({
    required String token,
    required int terminalId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/terminals/$terminalId'),
        headers: _getHeaders(token),
      );

      return json.decode(response.body);
    } catch (e) {
      throw Exception('Erro ao deletar terminal: $e');
    }
  }

  // RELATÓRIOS (para admins verem todos)
  static Future<Map<String, dynamic>> getAllReports({
    String? token,
    int page = 1,
    int limit = 20,
    int? status,
    int? terminalId,
    int? productId,
    String? startDateTime,
    String? endDateTime,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (status != null) queryParams['status'] = status.toString();
      if (terminalId != null) queryParams['terminalId'] = terminalId.toString();
      if (productId != null) queryParams['productId'] = productId.toString();
      if (startDateTime != null) queryParams['startDateTime'] = startDateTime;
      if (endDateTime != null) queryParams['endDateTime'] = endDateTime;

      final uri = Uri.parse('$baseUrl/api/reports').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erro ao carregar relatórios: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }
}
