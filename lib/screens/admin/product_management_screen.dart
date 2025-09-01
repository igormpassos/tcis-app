import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants.dart';
import '../../services/admin_service.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/common/delete_confirmation_dialog.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> suppliers = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    await Future.wait([loadProducts(), loadSuppliers()]);
  }

  Future<void> loadProducts() async {
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

      final response = await AdminService.getProducts(
        token: token,
        search: searchQuery.isNotEmpty ? searchQuery : null,
      );

      if (response['success']) {
        setState(() {
          products = List<Map<String, dynamic>>.from(response['data']);
        });
      } else {
        throw Exception(response['message'] ?? 'Erro desconhecido');
      }
    } catch (e) {
      print('Erro ao carregar produtos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar produtos: $e')),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> loadSuppliers() async {
    try {
      final authController = Provider.of<AuthController>(
        context,
        listen: false,
      );
      final token = authController.getToken();

      if (token == null) return;

      final response = await AdminService.getSuppliersSimple(token: token);

      if (response['success']) {
        setState(() {
          suppliers = List<Map<String, dynamic>>.from(response['data']);
        });
      }
    } catch (e) {
      print('Erro ao carregar fornecedores: $e');
    }
  }

  Future<void> deleteProduct(int productId) async {
    try {
      final authController = Provider.of<AuthController>(
        context,
        listen: false,
      );
      final token = authController.getToken();
      if (token == null) return;

      await AdminService.deleteProduct(token: token, productId: productId);

      await loadProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produto removido com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao remover produto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void showProductSuppliersDialog(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Fornecedores - ${product['name']}'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  // Lista de fornecedores atuais
                  Expanded(
                    child: ListView.builder(
                      itemCount: (product['suppliers'] as List?)?.length ?? 0,
                      itemBuilder: (context, index) {
                        final supplier = (product['suppliers'] as List)[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.business,
                            color: Colors.blue,
                          ),
                          title: Text(supplier['name']),
                          subtitle: Text(
                            'Código: ${supplier['code'] ?? 'N/A'}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.remove_circle,
                              color: Colors.red,
                            ),
                            onPressed: () async {
                              try {
                                final authController =
                                    Provider.of<AuthController>(
                                      context,
                                      listen: false,
                                    );
                                final token = authController.getToken();
                                if (token == null) return;

                                await AdminService.removeSupplierFromProduct(
                                  token: token,
                                  productId: product['id'],
                                  supplierId: supplier['id'],
                                );

                                Navigator.pop(context);
                                await loadProducts();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Fornecedor removido com sucesso!',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Erro ao remover fornecedor: $e',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),

                  const Divider(),

                  // Botão para adicionar fornecedor
                  ElevatedButton.icon(
                    onPressed: () => showAddSupplierDialog(product),
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar Fornecedor'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
            ],
          ),
    );
  }

  void showAddSupplierDialog(Map<String, dynamic> product) {
    final availableSuppliers =
        suppliers.where((supplier) {
          final currentSuppliers = (product['suppliers'] as List?) ?? [];
          return !currentSuppliers.any((s) => s['id'] == supplier['id']);
        }).toList();

    if (availableSuppliers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Todos os fornecedores já estão vinculados a este produto',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Adicionar Fornecedor'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                itemCount: availableSuppliers.length,
                itemBuilder: (context, index) {
                  final supplier = availableSuppliers[index];
                  return ListTile(
                    leading: const Icon(Icons.business, color: Colors.blue),
                    title: Text(supplier['name']),
                    subtitle: Text('Código: ${supplier['code'] ?? 'N/A'}'),
                    onTap: () async {
                      try {
                        final authController = Provider.of<AuthController>(
                          context,
                          listen: false,
                        );
                        final token = authController.getToken();
                        if (token == null) return;

                        await AdminService.addSupplierToProduct(
                          token: token,
                          productId: product['id'],
                          supplierId: supplier['id'],
                        );

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Fornecedor adicionado com sucesso!',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                        Navigator.pop(context);
                        Navigator.pop(context);
                        await loadProducts();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erro ao adicionar fornecedor: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ],
          ),
    );
  }

  void showCreateProductDialog({Map<String, dynamic>? product}) {
    final nameController = TextEditingController(text: product?['name'] ?? '');
    final codeController = TextEditingController(text: product?['code'] ?? '');
    final categoryController = TextEditingController(
      text: product?['category'] ?? '',
    );
    final descriptionController = TextEditingController(
      text: product?['description'] ?? '',
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(product == null ? 'Criar Produto' : 'Editar Produto'),
            content: SizedBox(
              width: double.maxFinite,
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
                    controller: categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Categoria',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
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

                    if (product == null) {
                      // Create new product
                      await AdminService.createProduct(
                        token: token,
                        name: nameController.text,
                        code: codeController.text,
                        category:
                            categoryController.text.isEmpty
                                ? null
                                : categoryController.text,
                        description:
                            descriptionController.text.isEmpty
                                ? null
                                : descriptionController.text,
                      );
                    } else {
                      // Update existing product
                      await AdminService.updateProduct(
                        token: token,
                        productId: product['id'],
                        name: nameController.text,
                        code: codeController.text,
                        category:
                            categoryController.text.isEmpty
                                ? null
                                : categoryController.text,
                        description:
                            descriptionController.text.isEmpty
                                ? null
                                : descriptionController.text,
                      );
                    }

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            product == null
                                ? 'Produto criado com sucesso!'
                                : 'Produto atualizado com sucesso!',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                    Navigator.pop(context);
                    await loadProducts();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro ao salvar produto: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Text(product == null ? 'Criar' : 'Salvar'),
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

  List<Map<String, dynamic>> get filteredProducts {
    if (searchQuery.isEmpty) return products;
    return products.where((product) {
      return (product['name']?.toLowerCase() ?? '').contains(
            searchQuery.toLowerCase(),
          ) ||
          (product['code']?.toLowerCase() ?? '').contains(
            searchQuery.toLowerCase(),
          ) ||
          (product['category']?.toLowerCase() ?? '').contains(
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
                    'Gerenciar Produtos',
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
                                hintText: 'Pesquisar produtos...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FloatingActionButton(
                            onPressed: () => showCreateProductDialog(),
                            backgroundColor: colorSecondary,
                            child: const Icon(Icons.add, color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                    // Lista de produtos
                    Expanded(
                      child:
                          isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : filteredProducts.isEmpty
                              ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.inventory_2_outlined,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      searchQuery.isEmpty
                                          ? 'Nenhum produto encontrado'
                                          : 'Nenhum produto corresponde à pesquisa',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : RefreshIndicator(
                                onRefresh: loadProducts,
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  itemCount: filteredProducts.length,
                                  itemBuilder: (context, index) {
                                    final product = filteredProducts[index];
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
                                          backgroundColor: Colors.orange
                                              .withOpacity(0.2),
                                          child: const Icon(
                                            Icons.inventory_2,
                                            color: Colors.orange,
                                          ),
                                        ),
                                        title: Text(
                                          product['name'] ?? 'Sem nome',
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
                                              'Código: ${product['code'] ?? 'N/A'}',
                                            ),
                                            if (product['category'] != null)
                                              Text(
                                                'Categoria: ${product['category']}',
                                              ),
                                            if (product['suppliers'] != null &&
                                                (product['suppliers'] as List)
                                                    .isNotEmpty)
                                              Text(
                                                'Fornecedores: ${(product['suppliers'] as List).map((s) => s['name']).join(', ')}',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Colors.blue[700],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              )
                                            else
                                              const Text(
                                                'Nenhum fornecedor vinculado',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            if (product['description'] != null)
                                              Text(
                                                'Descrição: ${product['description']}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                        trailing: PopupMenuButton<String>(
                                          onSelected: (value) async {
                                            switch (value) {
                                              case 'edit':
                                                showCreateProductDialog(
                                                  product: product,
                                                );
                                                break;
                                              case 'suppliers':
                                                showProductSuppliersDialog(
                                                  product,
                                                );
                                                break;
                                              case 'delete':
                                                final confirm =
                                                    await DeleteConfirmationDialog.show(
                                                      context: context,
                                                      itemType: 'produto',
                                                      itemName: product['name'],
                                                    );
                                                if (confirm == true) {
                                                  await deleteProduct(
                                                    product['id'],
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
                                                  value: 'suppliers',
                                                  child: Text(
                                                    'Gerenciar Fornecedores',
                                                  ),
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
