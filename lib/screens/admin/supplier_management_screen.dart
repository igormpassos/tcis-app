import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants.dart';
import '../../services/admin_service.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/common/delete_confirmation_dialog.dart';

class SupplierManagementScreen extends StatefulWidget {
  const SupplierManagementScreen({super.key});

  @override
  State<SupplierManagementScreen> createState() =>
      _SupplierManagementScreenState();
}

class _SupplierManagementScreenState extends State<SupplierManagementScreen> {
  List<Map<String, dynamic>> suppliers = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    loadSuppliers();
  }

  Future<void> loadSuppliers() async {
    setState(() => isLoading = true);
    try {
      final authController = Provider.of<AuthController>(
        context,
        listen: false,
      );
      final token = authController.getToken();

      if (token == null) {
        throw Exception('Token não encontrado');
      }

      final response = await AdminService.getSuppliers(
        token: token,
        search: searchQuery.isNotEmpty ? searchQuery : null,
      );

      if (response['success']) {
        setState(() {
          suppliers = List<Map<String, dynamic>>.from(response['data']);
        });
      } else {
        throw Exception(response['message'] ?? 'Erro desconhecido');
      }
    } catch (e) {
      print('Erro ao carregar fornecedores: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar fornecedores: $e')),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> deleteSupplier(int supplierId) async {
    try {
      final authController = Provider.of<AuthController>(
        context,
        listen: false,
      );
      final token = authController.getToken();
      if (token == null) return;

      await AdminService.deleteSupplier(token: token, supplierId: supplierId);

      await loadSuppliers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fornecedor removido com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao remover fornecedor: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void showCreateSupplierDialog({Map<String, dynamic>? supplier}) {
    final nameController = TextEditingController(text: supplier?['name'] ?? '');
    final codeController = TextEditingController(text: supplier?['code'] ?? '');
    final contactController = TextEditingController(
      text: supplier?['contact'] ?? '',
    );
    final emailController = TextEditingController(
      text: supplier?['email'] ?? '',
    );
    final phoneController = TextEditingController(
      text: supplier?['phone'] ?? '',
    );
    final addressController = TextEditingController(
      text: supplier?['address'] ?? '',
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              supplier == null ? 'Criar Fornecedor' : 'Editar Fornecedor',
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome*',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: codeController,
                      decoration: const InputDecoration(
                        labelText: 'Código*',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: contactController,
                      decoration: const InputDecoration(
                        labelText: 'Pessoa de contato',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Telefone',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: addressController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Endereço',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty ||
                      codeController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Preencha os campos obrigatórios'),
                      ),
                    );
                    return;
                  }

                  try {
                    final authController = Provider.of<AuthController>(
                      context,
                      listen: false,
                    );
                    final token = authController.getToken();
                    if (token == null) return;

                    if (supplier == null) {
                      // Create new supplier
                      await AdminService.createSupplier(
                        token: token,
                        name: nameController.text,
                        code: codeController.text,
                        contact:
                            contactController.text.isEmpty
                                ? null
                                : contactController.text,
                        email:
                            emailController.text.isEmpty
                                ? null
                                : emailController.text,
                        phone:
                            phoneController.text.isEmpty
                                ? null
                                : phoneController.text,
                        address:
                            addressController.text.isEmpty
                                ? null
                                : addressController.text,
                      );
                    } else {
                      // Update existing supplier
                      await AdminService.updateSupplier(
                        token: token,
                        supplierId: supplier['id'],
                        name: nameController.text,
                        code: codeController.text,
                        contact:
                            contactController.text.isEmpty
                                ? null
                                : contactController.text,
                        email:
                            emailController.text.isEmpty
                                ? null
                                : emailController.text,
                        phone:
                            phoneController.text.isEmpty
                                ? null
                                : phoneController.text,
                        address:
                            addressController.text.isEmpty
                                ? null
                                : addressController.text,
                      );
                    }

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            supplier == null
                                ? 'Fornecedor criado com sucesso!'
                                : 'Fornecedor atualizado com sucesso!',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                    Navigator.pop(context);
                    await loadSuppliers();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro ao salvar fornecedor: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Text(supplier == null ? 'Criar' : 'Salvar'),
              ),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ),
            ],
          ),
    );
  }

  List<Map<String, dynamic>> get filteredSuppliers {
    if (searchQuery.isEmpty) return suppliers;
    return suppliers.where((supplier) {
      return (supplier['name']?.toLowerCase() ?? '').contains(
            searchQuery.toLowerCase(),
          ) ||
          (supplier['code']?.toLowerCase() ?? '').contains(
            searchQuery.toLowerCase(),
          ) ||
          (supplier['contact']?.toLowerCase() ?? '').contains(
            searchQuery.toLowerCase(),
          );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorPrimary,
      resizeToAvoidBottomInset: false,
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
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Gerenciar Fornecedores',
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
                    // Barra de pesquisa e botão adicionar
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              onChanged:
                                  (value) =>
                                      setState(() => searchQuery = value),
                              decoration: InputDecoration(
                                hintText: 'Pesquisar fornecedores...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FloatingActionButton(
                            onPressed: () => showCreateSupplierDialog(),
                            backgroundColor: colorSecondary,
                            child: const Icon(Icons.add, color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                    // Lista de fornecedores
                    Expanded(
                      child:
                          isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : filteredSuppliers.isEmpty
                              ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.business_outlined,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      searchQuery.isEmpty
                                          ? 'Nenhum fornecedor encontrado'
                                          : 'Nenhum fornecedor corresponde à pesquisa',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : RefreshIndicator(
                                onRefresh: loadSuppliers,
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  itemCount: filteredSuppliers.length,
                                  itemBuilder: (context, index) {
                                    final supplier = filteredSuppliers[index];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.all(
                                          16,
                                        ),
                                        leading: CircleAvatar(
                                          backgroundColor: Colors.green
                                              .withOpacity(0.2),
                                          child: const Icon(
                                            Icons.business,
                                            color: Colors.green,
                                          ),
                                        ),
                                        title: Text(
                                          supplier['name'] ?? 'Sem nome',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Código: ${supplier['code'] ?? 'N/A'}',
                                            ),
                                            if (supplier['contact'] != null)
                                              Text(
                                                'Contato: ${supplier['contact']}',
                                              ),
                                            if (supplier['email'] != null)
                                              Text(
                                                'Email: ${supplier['email']}',
                                              ),
                                            if (supplier['phone'] != null)
                                              Text(
                                                'Telefone: ${supplier['phone']}',
                                              ),
                                          ],
                                        ),
                                        trailing: PopupMenuButton<String>(
                                          onSelected: (value) async {
                                            switch (value) {
                                              case 'edit':
                                                showCreateSupplierDialog(
                                                  supplier: supplier,
                                                );
                                                break;
                                              case 'delete':
                                                final confirm =
                                                    await DeleteConfirmationDialog.show(
                                                      context: context,
                                                      itemType: 'fornecedor',
                                                      itemName:
                                                          supplier['name'],
                                                    );
                                                if (confirm == true) {
                                                  await deleteSupplier(
                                                    supplier['id'],
                                                  );
                                                }
                                                break;
                                            }
                                          },
                                          itemBuilder:
                                              (context) => [
                                                const PopupMenuItem(
                                                  value: 'edit',
                                                  child: Text('Editar'),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'delete',
                                                  child: Text('Excluir'),
                                                ),
                                              ],
                                        ),
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
