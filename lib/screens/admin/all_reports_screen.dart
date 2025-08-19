import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants.dart';
import '../../services/admin_service.dart';
import '../../controllers/auth_controller.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AllReportsScreen extends StatefulWidget {
  const AllReportsScreen({super.key});

  @override
  State<AllReportsScreen> createState() => _AllReportsScreenState();
}

class _AllReportsScreenState extends State<AllReportsScreen> {
  List<Map<String, dynamic>> reports = [];
  List<Map<String, dynamic>> terminals = [];
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> suppliers = [];
  
  bool isLoading = true;
  String searchQuery = '';
  int? selectedStatus;
  int? selectedTerminal;
  int? selectedProduct;
  int? selectedSupplier;
  
  int currentPage = 1;
  int totalPages = 1;
  int itemsPerPage = 20;

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    await Future.wait([
      loadReports(),
      loadTerminals(),
      loadProducts(),
      loadSuppliers(),
    ]);
  }

  Future<void> loadReports([int page = 1]) async {
    if (page == 1) setState(() => isLoading = true);
    
    try {
      final authController = Provider.of<AuthController>(context, listen: false);
      final token = authController.getToken();
      
      if (token == null) {
        throw Exception('Token não encontrado');
      }

      final response = await AdminService.getAllReports(
        token: token,
        page: page,
        limit: itemsPerPage,
        status: selectedStatus,
        terminalId: selectedTerminal,
        productId: selectedProduct,
      );
      
      if (response['success']) {
        final data = response;
        setState(() {
          if (page == 1) {
            reports = List<Map<String, dynamic>>.from(data['data'] ?? []);
          } else {
            reports.addAll(List<Map<String, dynamic>>.from(data['data'] ?? []));
          }
          currentPage = data['pagination']?['page'] ?? page;
          totalPages = data['pagination']?['totalPages'] ?? 1;
        });
      } else {
        throw Exception(response['message'] ?? 'Erro desconhecido');
      }
    } catch (e) {
      print('Erro ao carregar relatórios: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar relatórios: $e')),
        );
      }
    } finally {
      if (page == 1) setState(() => isLoading = false);
    }
  }

  Future<void> loadTerminals() async {
    try {
      final authController = Provider.of<AuthController>(context, listen: false);
      final token = authController.getToken();
      
      if (token != null) {
        final response = await AdminService.getTerminals(token: token);
        if (response['success']) {
          setState(() {
            terminals = List<Map<String, dynamic>>.from(response['data']);
          });
        }
      }
    } catch (e) {
      print('Erro ao carregar terminais: $e');
    }
  }

  Future<void> loadProducts() async {
    try {
      final authController = Provider.of<AuthController>(context, listen: false);
      final token = authController.getToken();
      
      if (token != null) {
        final response = await AdminService.getProducts(token: token);
        if (response['success']) {
          setState(() {
            products = List<Map<String, dynamic>>.from(response['data']);
          });
        }
      }
    } catch (e) {
      print('Erro ao carregar produtos: $e');
    }
  }

  Future<void> loadSuppliers() async {
    try {
      final authController = Provider.of<AuthController>(context, listen: false);
      final token = authController.getToken();
      
      if (token != null) {
        final response = await AdminService.getSuppliers(token: token);
        if (response['success']) {
          setState(() {
            suppliers = List<Map<String, dynamic>>.from(response['data']);
          });
        }
      }
    } catch (e) {
      print('Erro ao carregar fornecedores: $e');
    }
  }

  void applyFilters() {
    currentPage = 1;
    loadReports();
  }

  void clearFilters() {
    setState(() {
      selectedStatus = null;
      selectedTerminal = null;
      selectedProduct = null;
      selectedSupplier = null;
      searchQuery = '';
    });
    applyFilters();
  }

  Future<void> openPdf(String? pdfUrl) async {
    if (pdfUrl == null || pdfUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF não disponível')),
      );
      return;
    }

    try {
      final url = pdfUrl.startsWith('http') ? pdfUrl : '${API_BASE_URL}/$pdfUrl';
      final uri = Uri.parse(url);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Não foi possível abrir o PDF';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao abrir PDF: $e')),
      );
    }
  }

  String getStatusText(int? status) {
    switch (status) {
      case 0:
        return 'Rascunho';
      case 1:
        return 'Finalizado';
      case 2:
        return 'Enviado';
      default:
        return 'N/A';
    }
  }

  Color getStatusColor(int? status) {
    switch (status) {
      case 0:
        return Colors.orange;
      case 1:
        return Colors.blue;
      case 2:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  List<Map<String, dynamic>> get filteredReports {
    if (searchQuery.isEmpty) return reports;
    return reports.where((report) {
      return (report['prefix']?.toLowerCase() ?? '').contains(searchQuery.toLowerCase()) ||
             (report['user']?['name']?.toLowerCase() ?? '').contains(searchQuery.toLowerCase()) ||
             (report['terminal']?['name']?.toLowerCase() ?? '').contains(searchQuery.toLowerCase()) ||
             (report['product']?['name']?.toLowerCase() ?? '').contains(searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                  ),
                  const Spacer(),
                  const Text(
                    'Todos os Relatórios',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // Container principal
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    // Filtros e pesquisa
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Barra de pesquisa
                          TextField(
                            onChanged: (value) => setState(() => searchQuery = value),
                            decoration: InputDecoration(
                              hintText: 'Pesquisar relatórios...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Filtros
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                // Status
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  child: DropdownButton<int?>(
                                    hint: const Text('Status'),
                                    value: selectedStatus,
                                    onChanged: (value) {
                                      setState(() => selectedStatus = value);
                                      applyFilters();
                                    },
                                    items: const [
                                      DropdownMenuItem(value: null, child: Text('Todos')),
                                      DropdownMenuItem(value: 0, child: Text('Rascunho')),
                                      DropdownMenuItem(value: 1, child: Text('Finalizado')),
                                      DropdownMenuItem(value: 2, child: Text('Enviado')),
                                    ],
                                  ),
                                ),
                                
                                // Terminal
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  child: DropdownButton<int?>(
                                    hint: const Text('Terminal'),
                                    value: selectedTerminal,
                                    onChanged: (value) {
                                      setState(() => selectedTerminal = value);
                                      applyFilters();
                                    },
                                    items: [
                                      const DropdownMenuItem(value: null, child: Text('Todos')),
                                      ...terminals.map((t) => DropdownMenuItem(
                                        value: t['id'],
                                        child: Text(t['name'] ?? 'N/A'),
                                      )),
                                    ],
                                  ),
                                ),
                                
                                // Produto
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  child: DropdownButton<int?>(
                                    hint: const Text('Produto'),
                                    value: selectedProduct,
                                    onChanged: (value) {
                                      setState(() => selectedProduct = value);
                                      applyFilters();
                                    },
                                    items: [
                                      const DropdownMenuItem(value: null, child: Text('Todos')),
                                      ...products.map((p) => DropdownMenuItem(
                                        value: p['id'],
                                        child: Text(p['name'] ?? 'N/A'),
                                      )),
                                    ],
                                  ),
                                ),

                                // Botão limpar filtros
                                if (selectedStatus != null || 
                                    selectedTerminal != null || 
                                    selectedProduct != null || 
                                    selectedSupplier != null)
                                  TextButton(
                                    onPressed: clearFilters,
                                    child: const Text('Limpar'),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Lista de relatórios
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : filteredReports.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.assessment_outlined, size: 64, color: Colors.grey[400]),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Nenhum relatório encontrado',
                                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: () => loadReports(),
                                  child: ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    itemCount: filteredReports.length + (currentPage < totalPages ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      // Botão "Carregar mais"
                                      if (index == filteredReports.length) {
                                        return Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: ElevatedButton(
                                            onPressed: () => loadReports(currentPage + 1),
                                            child: const Text('Carregar mais'),
                                          ),
                                        );
                                      }

                                      final report = filteredReports[index];
                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.all(16),
                                          leading: CircleAvatar(
                                            backgroundColor: getStatusColor(report['status']).withOpacity(0.2),
                                            child: Icon(
                                              Icons.assessment,
                                              color: getStatusColor(report['status']),
                                            ),
                                          ),
                                          title: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  report['prefix'] ?? 'Sem prefixo',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: getStatusColor(report['status']).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  getStatusText(report['status']),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: getStatusColor(report['status']),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 4),
                                              Text('Usuário: ${report['user']?['name'] ?? 'N/A'}'),
                                              Text('Terminal: ${report['terminal']?['name'] ?? 'N/A'}'),
                                              Text('Produto: ${report['product']?['name'] ?? 'N/A'}'),
                                              if (report['supplier'] != null)
                                                Text('Fornecedor: ${report['supplier']['name']}'),
                                              if (report['createdAt'] != null)
                                                Text(
                                                  'Data: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(report['createdAt']))}',
                                                ),
                                            ],
                                          ),
                                          trailing: report['pdfUrl'] != null
                                              ? IconButton(
                                                  icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                                                  onPressed: () => openPdf(report['pdfUrl']),
                                                  tooltip: 'Abrir PDF',
                                                )
                                              : null,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
