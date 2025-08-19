import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants.dart';
import '../../services/admin_service.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/common/delete_confirmation_dialog.dart';

class ClientManagementScreen extends StatefulWidget {
  const ClientManagementScreen({super.key});

  @override
  State<ClientManagementScreen> createState() => _ClientManagementScreenState();
}

class _ClientManagementScreenState extends State<ClientManagementScreen> {
  List<Map<String, dynamic>> clients = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    loadClients();
  }

  Future<void> loadClients() async {
    setState(() => isLoading = true);
    try {
      final authController = Provider.of<AuthController>(context, listen: false);
      final token = authController.getToken();
      
      if (token == null) {
        throw Exception('Token não encontrado');
      }

      final response = await AdminService.getClients(
        token: token,
        search: searchQuery.isNotEmpty ? searchQuery : null,
      );
      
      if (response['success']) {
        setState(() {
          clients = List<Map<String, dynamic>>.from(response['data']);
        });
      } else {
        throw Exception(response['message'] ?? 'Erro desconhecido');
      }
    } catch (e) {
      print('Erro ao carregar clientes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar clientes: $e')),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> deleteClient(int clientId) async {
    try {
      final authController = Provider.of<AuthController>(context, listen: false);
      final token = authController.getToken();
      if (token == null) return;

      final response = await AdminService.deleteClient(
        token: token,
        clientId: clientId,
      );
      
      if (response['success']) {
        await loadClients();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cliente removido com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(response['message'] ?? 'Erro desconhecido');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao remover cliente: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void showCreateClientDialog({Map<String, dynamic>? client}) {
    final nameController = TextEditingController(text: client?['name'] ?? '');
    final contactController = TextEditingController(text: client?['contact'] ?? '');
    final emailsController = TextEditingController(
      text: client?['emails'] != null 
          ? (client!['emails'] as List).join(', ') 
          : ''
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(client == null ? 'Criar Cliente' : 'Editar Cliente'),
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
              const SizedBox(height: 16),
              TextField(
                controller: contactController,
                decoration: const InputDecoration(
                  labelText: 'Contato',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Emails (separados por vírgula)',
                  hintText: 'cliente@exemplo.com, outro@exemplo.com',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nome é obrigatório')),
                );
                return;
              }

              try {
                final authController = Provider.of<AuthController>(context, listen: false);
                final token = authController.getToken();
                if (token == null) return;

                // Parse emails
                List<String> emails = [];
                if (emailsController.text.isNotEmpty) {
                  emails = emailsController.text
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();
                }

                Map<String, dynamic> response;
                if (client == null) {
                  // Create new client
                  response = await AdminService.createClient(
                    token: token,
                    name: nameController.text,
                    contact: contactController.text.isEmpty ? null : contactController.text,
                    emails: emails.isEmpty ? null : emails,
                  );
                } else {
                  // Update existing client
                  response = await AdminService.updateClient(
                    token: token,
                    clientId: client['id'],
                    name: nameController.text,
                    contact: contactController.text.isEmpty ? null : contactController.text,
                    emails: emails.isEmpty ? null : emails,
                  );
                }

                if (response['success']) {
                  Navigator.pop(context);
                  await loadClients();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(client == null 
                            ? 'Cliente criado com sucesso!' 
                            : 'Cliente atualizado com sucesso!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else {
                  throw Exception(response['message'] ?? 'Erro desconhecido');
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao salvar cliente: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(client == null ? 'Criar' : 'Salvar'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get filteredClients {
    if (searchQuery.isEmpty) return clients;
    return clients.where((client) {
      return (client['name']?.toLowerCase() ?? '').contains(searchQuery.toLowerCase()) ||
             (client['contact']?.toLowerCase() ?? '').contains(searchQuery.toLowerCase()) ||
             (client['emails'] as List?)?.any((email) => 
                 email.toLowerCase().contains(searchQuery.toLowerCase())) == true;
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
                    'Gerenciar Clientes',
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
                              onChanged: (value) => setState(() => searchQuery = value),
                              decoration: InputDecoration(
                                hintText: 'Pesquisar clientes...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FloatingActionButton(
                            onPressed: () => showCreateClientDialog(),
                            backgroundColor: colorSecondary,
                            child: const Icon(Icons.add, color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                    // Lista de clientes
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : filteredClients.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.people_outlined, size: 64, color: Colors.grey[400]),
                                      const SizedBox(height: 16),
                                      Text(
                                        searchQuery.isEmpty 
                                            ? 'Nenhum cliente encontrado'
                                            : 'Nenhum cliente corresponde à pesquisa',
                                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: loadClients,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    itemCount: filteredClients.length,
                                    itemBuilder: (context, index) {
                                      final client = filteredClients[index];
                                      final emails = client['emails'] as List? ?? [];
                                      
                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.all(16),
                                          leading: CircleAvatar(
                                            backgroundColor: Colors.blue.withOpacity(0.2),
                                            child: const Icon(
                                              Icons.person,
                                              color: Colors.blue,
                                            ),
                                          ),
                                          title: Text(
                                            client['name'] ?? 'Sem nome',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              if (client['contact'] != null)
                                                Text('Contato: ${client['contact']}'),
                                              if (emails.isNotEmpty)
                                                Text(
                                                  'Emails: ${emails.join(', ')}',
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: Colors.blue[700],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Criado em: ${DateTime.parse(client['createdAt']).day.toString().padLeft(2, '0')}/${DateTime.parse(client['createdAt']).month.toString().padLeft(2, '0')}/${DateTime.parse(client['createdAt']).year}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                          trailing: PopupMenuButton<String>(
                                            onSelected: (value) async {
                                              switch (value) {
                                                case 'edit':
                                                  showCreateClientDialog(client: client);
                                                  break;
                                                case 'delete':
                                                  final confirm = await DeleteConfirmationDialog.show(
                                                    context: context,
                                                    itemType: 'cliente',
                                                    itemName: client['name'],
                                                  );
                                                  if (confirm == true) {
                                                    await deleteClient(client['id']);
                                                  }
                                                  break;
                                              }
                                            },
                                            itemBuilder: (context) => [
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
