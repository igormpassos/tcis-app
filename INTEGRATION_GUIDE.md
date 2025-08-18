# Integração Flutter com Backend TCIS

## Status do Backend

✅ **Backend Node.js criado e funcionando!**

- **URL:** http://localhost:3000
- **Usuário padrão:** tcis / tcis
- **Banco de dados:** PostgreSQL configurado
- **API documentada:** Veja README.md do backend

## Próximos Passos para Integração

### 1. Atualizar a aplicação Flutter

Substitua o armazenamento local (SharedPreferences) por chamadas HTTP para a API.

#### Dependências necessárias no Flutter:
```yaml
dependencies:
  http: ^1.1.0
  flutter_secure_storage: ^9.0.0  # Para armazenar token JWT
```

#### Exemplo de serviço HTTP para Flutter:

```dart
// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';
  static const storage = FlutterSecureStorage();
  
  static Future<String?> getToken() async {
    return await storage.read(key: 'jwt_token');
  }
  
  static Future<void> setToken(String token) async {
    await storage.write(key: 'jwt_token', value: token);
  }
  
  static Future<void> removeToken() async {
    await storage.delete(key: 'jwt_token');
  }
  
  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
  
  // Login
  static Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: await getHeaders(),
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );
    
    final data = jsonDecode(response.body);
    
    if (response.statusCode == 200 && data['success']) {
      await setToken(data['data']['token']);
      return data['data']['user'];
    } else {
      throw Exception(data['message'] ?? 'Erro no login');
    }
  }
  
  // Logout
  static Future<void> logout() async {
    await removeToken();
  }
  
  // Listar relatórios
  static Future<List<dynamic>> getReports({
    int page = 1,
    int limit = 20,
    int? status,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (status != null) 'status': status.toString(),
    };
    
    final uri = Uri.parse('$baseUrl/reports').replace(
      queryParameters: queryParams,
    );
    
    final response = await http.get(uri, headers: await getHeaders());
    final data = jsonDecode(response.body);
    
    if (response.statusCode == 200 && data['success']) {
      return data['data'];
    } else {
      throw Exception(data['message'] ?? 'Erro ao buscar relatórios');
    }
  }
  
  // Criar relatório
  static Future<Map<String, dynamic>> createReport(Map<String, dynamic> reportData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reports'),
      headers: await getHeaders(),
      body: jsonEncode(reportData),
    );
    
    final data = jsonDecode(response.body);
    
    if (response.statusCode == 201 && data['success']) {
      return data['data'];
    } else {
      throw Exception(data['message'] ?? 'Erro ao criar relatório');
    }
  }
  
  // Atualizar relatório
  static Future<Map<String, dynamic>> updateReport(String id, Map<String, dynamic> reportData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/reports/$id'),
      headers: await getHeaders(),
      body: jsonEncode(reportData),
    );
    
    final data = jsonDecode(response.body);
    
    if (response.statusCode == 200 && data['success']) {
      return data['data'];
    } else {
      throw Exception(data['message'] ?? 'Erro ao atualizar relatório');
    }
  }
  
  // Excluir relatório
  static Future<void> deleteReport(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/reports/$id'),
      headers: await getHeaders(),
    );
    
    final data = jsonDecode(response.body);
    
    if (response.statusCode != 200 || !data['success']) {
      throw Exception(data['message'] ?? 'Erro ao excluir relatório');
    }
  }
  
  // Buscar terminais
  static Future<List<dynamic>> getTerminals() async {
    final response = await http.get(
      Uri.parse('$baseUrl/terminals'),
      headers: await getHeaders(),
    );
    
    final data = jsonDecode(response.body);
    
    if (response.statusCode == 200 && data['success']) {
      return data['data'];
    } else {
      throw Exception(data['message'] ?? 'Erro ao buscar terminais');
    }
  }
  
  // Buscar produtos
  static Future<List<dynamic>> getProducts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/products'),
      headers: await getHeaders(),
    );
    
    final data = jsonDecode(response.body);
    
    if (response.statusCode == 200 && data['success']) {
      return data['data'];
    } else {
      throw Exception(data['message'] ?? 'Erro ao buscar produtos');
    }
  }
  
  // Buscar fornecedores
  static Future<List<dynamic>> getSuppliers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/suppliers'),
      headers: await getHeaders(),
    );
    
    final data = jsonDecode(response.body);
    
    if (response.statusCode == 200 && data['success']) {
      return data['data'];
    } else {
      throw Exception(data['message'] ?? 'Erro ao buscar fornecedores');
    }
  }
  
  // Buscar funcionários
  static Future<List<dynamic>> getEmployees() async {
    final response = await http.get(
      Uri.parse('$baseUrl/employees'),
      headers: await getHeaders(),
    );
    
    final data = jsonDecode(response.body);
    
    if (response.statusCode == 200 && data['success']) {
      return data['data'];
    } else {
      throw Exception(data['message'] ?? 'Erro ao buscar funcionários');
    }
  }
  
  // Upload de imagens
  static Future<List<dynamic>> uploadImages(String reportId, List<String> imagePaths) async {
    final uri = Uri.parse('$baseUrl/uploads/images/$reportId');
    final request = http.MultipartRequest('POST', uri);
    
    // Adicionar headers
    final headers = await getHeaders();
    request.headers.addAll(headers);
    
    // Adicionar imagens
    for (String imagePath in imagePaths) {
      request.files.add(await http.MultipartFile.fromPath('images', imagePath));
    }
    
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final data = jsonDecode(responseBody);
    
    if (response.statusCode == 201 && data['success']) {
      return data['data'];
    } else {
      throw Exception(data['message'] ?? 'Erro ao fazer upload das imagens');
    }
  }
}
```

### 2. Atualizar tela de login

```dart
// lib/screens/login/login.dart
import 'package:tcis_app/services/api_service.dart';

// No método _validateLogin:
void _validateLogin() async {
  try {
    setState(() => _isLoading = true);
    
    final user = await ApiService.login(
      _userController.text.trim(),
      _passwordController.text
    );
    
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
    
  } catch (e) {
    setState(() {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
    });
  }
}
```

### 3. Atualizar tela de home

```dart
// lib/screens/home/home_screen.dart
import 'package:tcis_app/services/api_service.dart';

// Substituir loadReports():
Future<void> loadReports() async {
  try {
    final reports = await ApiService.getReports(status: 0); // apenas rascunhos
    setState(() {
      fullReports = reports.map((r) => FullReportModel.fromApiJson(r)).toList();
    });
  } catch (e) {
    print('Erro ao carregar relatórios: $e');
    // Exibir snackbar de erro
  }
}
```

### 4. Atualizar modelo de dados

```dart
// lib/model/full_report_model.dart
// Adicionar método fromApiJson:

factory FullReportModel.fromApiJson(Map<String, dynamic> json) {
  return FullReportModel(
    id: json['id'],
    prefixo: json['prefix'],
    terminal: json['terminal']?['name'] ?? '',
    produto: json['product']?['name'] ?? '',
    colaborador: json['employee']?['name'] ?? '',
    fornecedor: json['supplier']?['name'],
    tipoVagao: json['wagonType'],
    dataInicio: json['startDate'],
    horarioInicio: json['startTime'] ?? '',
    dataTermino: json['endDate'],
    horarioTermino: json['endTime'] ?? '',
    horarioChegada: json['arrivalTime'] ?? '',
    horarioSaida: json['departureTime'] ?? '',
    houveContaminacao: json['hasContamination'],
    contaminacaoDescricao: json['contaminationDescription'] ?? '',
    materialHomogeneo: json['homogeneousMaterial'] ?? '',
    umidadeVisivel: json['visibleMoisture'] ?? '',
    houveChuva: json['rainOccurred'] ?? '',
    fornecedorAcompanhou: json['supplierAccompanied'] ?? '',
    observacoes: json['observations'] ?? '',
    imagens: (json['images'] as List?)?.map((i) => '/uploads/images/${i['filename']}').toList().cast<String>() ?? [],
    pathPdf: json['pdfPath'] ?? '',
    dataCriacao: DateTime.parse(json['createdAt']),
    status: json['status'],
  );
}

// Adicionar método toApiJson para criar/atualizar:
Map<String, dynamic> toApiJson() {
  return {
    'prefix': prefixo,
    'terminalId': terminalId, // Você precisará armazenar os IDs
    'productId': productId,
    'supplierId': supplierId,
    'employeeId': employeeId,
    'startDate': DateTime.parse(dataInicio).toIso8601String(),
    'endDate': DateTime.parse(dataTermino).toIso8601String(),
    'arrivalTime': horarioChegada.isNotEmpty ? DateTime.parse(horarioChegada).toIso8601String() : null,
    'departureTime': horarioSaida.isNotEmpty ? DateTime.parse(horarioSaida).toIso8601String() : null,
    'startTime': horarioInicio.isNotEmpty ? DateTime.parse(horarioInicio).toIso8601String() : null,
    'endTime': horarioTermino.isNotEmpty ? DateTime.parse(horarioTermino).toIso8601String() : null,
    'wagonType': tipoVagao,
    'hasContamination': houveContaminacao,
    'contaminationDescription': contaminacaoDescricao,
    'homogeneousMaterial': materialHomogeneo,
    'visibleMoisture': umidadeVisivel,
    'rainOccurred': houveChuva,
    'supplierAccompanied': fornecedorAcompanhou,
    'observations': observacoes,
    'status': status,
  };
}
```

## Comandos úteis

### Iniciar o backend:
```bash
cd backend
node server.js
```

### Testar a API:
```bash
cd backend
./test-api.sh
```

### Visualizar banco de dados:
```bash
cd backend
npm run studio
```

### Resetar banco de dados:
```bash
cd backend
npx prisma migrate reset
node prisma/seed.js
```

## URLs importantes

- **API Base:** http://localhost:3000/api
- **Health Check:** http://localhost:3000/health
- **Prisma Studio:** http://localhost:5555 (após `npm run studio`)

## Autenticação

- Todas as rotas exceto `/api/auth/login` requerem token JWT
- Token deve ser enviado no header: `Authorization: Bearer <token>`
- Token expira em 24h (configurável)

## Estrutura da resposta da API

```json
{
  "success": true,
  "message": "Mensagem de sucesso",
  "data": { /* dados da resposta */ },
  "pagination": { /* dados de paginação quando aplicável */ }
}
```

## Próximos passos recomendados

1. ✅ Backend criado e testado
2. 🔄 **Próximo:** Integrar Flutter com backend (substituir SharedPreferences)
3. 📱 Testar upload de imagens
4. 🎨 Adicionar indicadores de loading/erro nas telas
5. 🔒 Implementar logout automático quando token expira
6. 📊 Dashboard administrativo (opcional)
7. 🚀 Deploy em produção

O backend está completamente funcional e pronto para ser integrado com sua aplicação Flutter!
