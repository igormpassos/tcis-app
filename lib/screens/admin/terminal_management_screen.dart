import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants.dart';
import '../../services/admin_service.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/common/delete_confirmation_dialog.dart';

class TerminalManagementScreen extends StatefulWidget {
  const TerminalManagementScreen({super.key});

  @override
  State<TerminalManagementScreen> createState() => _TerminalManagementScreenState();
}

class _TerminalManagementScreenState extends State<TerminalManagementScreen> {
  List<Map<String, dynamic>> terminals = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    loadTerminals();
  }

  Future<void> loadTerminals() async {
    setState(() => isLoading = true);
    try {
      final authController = Provider.of<AuthController>(context, listen: false);
      final token = authController.getToken();
      
      if (token == null) {
        throw Exception('Token não encontrado');
      }

      final response = await AdminService.getTerminals(
        token: token,
        search: searchQuery.isNotEmpty ? searchQuery : null,
      );
      
      if (response['success']) {
        setState(() {
          terminals = List<Map<String, dynamic>>.from(response['data']);
        });
      } else {
        throw Exception(response['message'] ?? 'Erro desconhecido');
      }
    } catch (e) {
      print('Erro ao carregar terminais: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar terminais: $e')),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> deleteTerminal(int terminalId) async {
    try {
      final authController = Provider.of<AuthController>(context, listen: false);
      final token = authController.getToken();
      if (token == null) return;

      await AdminService.deleteTerminal(
        token: token,
        terminalId: terminalId,
      );
      
      await loadTerminals();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terminal removido com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao remover terminal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> toggleTerminalStatus(int terminalId, bool currentStatus) async {
    try {
      final authController = Provider.of<AuthController>(context, listen: false);
      final token = authController.getToken();
      if (token == null) return;

      await AdminService.updateTerminal(
        token: token,
        terminalId: terminalId,
        active: !currentStatus,
      );
      
      await loadTerminals();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(currentStatus 
                ? 'Terminal desativado com sucesso!' 
                : 'Terminal ativado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao alterar status do terminal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void showCreateTerminalDialog({Map<String, dynamic>? terminal}) {
    final nameController = TextEditingController(text: terminal?['name'] ?? '');
    final codeController = TextEditingController(text: terminal?['code'] ?? '');
    final prefixController = TextEditingController(text: terminal?['prefix'] ?? '');
    final locationController = TextEditingController(text: terminal?['location'] ?? '');
    final descriptionController = TextEditingController(text: terminal?['description'] ?? '');
    bool isActive = terminal?['active'] ?? true;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(terminal == null ? 'Criar Terminal' : 'Editar Terminal'),
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
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Código*',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: prefixController,
                decoration: const InputDecoration(
                  labelText: 'Prefixo',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: TSA, VLB, etc.',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Localização',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(),
                ),
              ),
              if (terminal != null) // Só mostra o switch para terminais existentes
                Column(
                  children: [
                    const SizedBox(height: 16),
                    StatefulBuilder(
                      builder: (context, setState) => Row(
                        children: [
                          const Text('Status:'),
                          const SizedBox(width: 16),
                          Switch(
                            value: isActive,
                            onChanged: (value) {
                              setState(() {
                                isActive = value;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          Text(isActive ? 'Ativo' : 'Inativo'),
                        ],
                      ),
                    ),
                  ],
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
              if (nameController.text.isEmpty || codeController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Preencha os campos obrigatórios')),
                );
                return;
              }

              try {
                final authController = Provider.of<AuthController>(context, listen: false);
                final token = authController.getToken();
                if (token == null) return;

                if (terminal == null) {
                  // Create new terminal
                  await AdminService.createTerminal(
                    token: token,
                    name: nameController.text,
                    code: codeController.text,
                    prefix: prefixController.text.isEmpty ? null : prefixController.text,
                    location: locationController.text.isEmpty ? null : locationController.text,
                  );
                } else {
                  // Update existing terminal
                  await AdminService.updateTerminal(
                    token: token,
                    terminalId: terminal['id'],
                    name: nameController.text,
                    code: codeController.text,
                    prefix: prefixController.text.isEmpty ? null : prefixController.text,
                    location: locationController.text.isEmpty ? null : locationController.text,
                    active: isActive,
                  );
                }

                Navigator.pop(context);
                await loadTerminals();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(terminal == null 
                          ? 'Terminal criado com sucesso!' 
                          : 'Terminal atualizado com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao salvar terminal: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(terminal == null ? 'Criar' : 'Salvar'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get filteredTerminals {
    if (searchQuery.isEmpty) return terminals;
    return terminals.where((terminal) {
      return (terminal['name']?.toLowerCase() ?? '').contains(searchQuery.toLowerCase()) ||
             (terminal['code']?.toLowerCase() ?? '').contains(searchQuery.toLowerCase()) ||
             (terminal['location']?.toLowerCase() ?? '').contains(searchQuery.toLowerCase());
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
                    'Gerenciar Terminais',
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
                                hintText: 'Pesquisar terminais...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FloatingActionButton(
                            onPressed: () => showCreateTerminalDialog(),
                            backgroundColor: colorSecondary,
                            child: const Icon(Icons.add, color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                    // Lista de terminais
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : filteredTerminals.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.location_on_outlined, size: 64, color: Colors.grey[400]),
                                      const SizedBox(height: 16),
                                      Text(
                                        searchQuery.isEmpty 
                                            ? 'Nenhum terminal encontrado'
                                            : 'Nenhum terminal corresponde à pesquisa',
                                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: loadTerminals,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    itemCount: filteredTerminals.length,
                                    itemBuilder: (context, index) {
                                      final terminal = filteredTerminals[index];
                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.all(16),
                                          leading: CircleAvatar(
                                            backgroundColor: terminal['active'] == false 
                                                ? Colors.grey.withOpacity(0.2)
                                                : Colors.purple.withOpacity(0.2),
                                            child: Icon(
                                              Icons.location_on,
                                              color: terminal['active'] == false 
                                                  ? Colors.grey
                                                  : Colors.purple,
                                            ),
                                          ),
                                          title: Text(
                                            terminal['name'] ?? 'Sem nome',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Código: ${terminal['code'] ?? 'N/A'}'),
                                              if (terminal['prefix'] != null)
                                                Text('Prefixo: ${terminal['prefix']}'),
                                              if (terminal['location'] != null)
                                                Text('Localização: ${terminal['location']}'),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: terminal['active'] == false 
                                                          ? Colors.grey.withOpacity(0.1)
                                                          : Colors.green.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      terminal['active'] == false ? 'Inativo' : 'Ativo',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: terminal['active'] == false 
                                                            ? Colors.grey
                                                            : Colors.green,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (terminal['description'] != null)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 4),
                                                  child: Text(
                                                    'Descrição: ${terminal['description']}',
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          trailing: PopupMenuButton<String>(
                                            onSelected: (value) async {
                                              switch (value) {
                                                case 'edit':
                                                  showCreateTerminalDialog(terminal: terminal);
                                                  break;
                                                case 'toggle_status':
                                                  await toggleTerminalStatus(
                                                    terminal['id'],
                                                    terminal['active'] ?? true,
                                                  );
                                                  break;
                                                case 'delete':
                                                  final confirm = await DeleteConfirmationDialog.show(
                                                    context: context,
                                                    itemType: 'terminal',
                                                    itemName: terminal['name'],
                                                  );
                                                  if (confirm == true) {
                                                    await deleteTerminal(terminal['id']);
                                                  }
                                                  break;
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              PopupMenuItem(
                                                value: 'edit',
                                                child: Row(
                                                  children: const [
                                                    Icon(Icons.edit, size: 20),
                                                    SizedBox(width: 8),
                                                    Text('Editar'),
                                                  ],
                                                ),
                                              ),
                                              PopupMenuItem(
                                                value: 'toggle_status',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      terminal['active'] == false 
                                                          ? Icons.visibility 
                                                          : Icons.visibility_off,
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      terminal['active'] == false 
                                                          ? 'Ativar' 
                                                          : 'Desativar',
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: const [
                                                    Icon(Icons.delete, size: 20, color: Colors.red),
                                                    SizedBox(width: 8),
                                                    Text('Excluir', style: TextStyle(color: Colors.red)),
                                                  ],
                                                ),
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
