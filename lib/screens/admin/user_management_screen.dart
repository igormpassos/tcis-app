import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants.dart';
import '../../services/admin_service.dart';
import '../../controllers/auth_controller.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    setState(() => isLoading = true);
    try {
      final authController = Provider.of<AuthController>(context, listen: false);
      final token = authController.getToken();
      
      if (token == null) {
        throw Exception('Token não encontrado');
      }

      final response = await AdminService.getUsers(
        token: token,
        search: searchQuery.isNotEmpty ? searchQuery : null,
      );
      
      if (response['success']) {
        setState(() {
          users = List<Map<String, dynamic>>.from(response['data']);
        });
      } else {
        throw Exception(response['message'] ?? 'Erro desconhecido');
      }
    } catch (e) {
      print('Erro ao carregar usuários: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar usuários: $e')),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> toggleUserStatus(int userId, bool currentStatus) async {
    try {
      final authController = Provider.of<AuthController>(context, listen: false);
      final token = authController.getToken();
      
      if (token == null) {
        throw Exception('Token não encontrado');
      }

      final response = await AdminService.updateUser(
        token: token,
        userId: userId,
        active: !currentStatus,
      );
      
      if (response['success']) {
        await loadUsers(); // Recarregar lista
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(currentStatus ? 'Usuário desativado' : 'Usuário ativado'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(response['message'] ?? 'Erro ao atualizar usuário');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void showCreateUserDialog() {
    final nameController = TextEditingController();
    final usernameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'USER';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Text(
          'Criar Novo Usuário',
          style: TextStyle(
            color: colorPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 20,
          ),
        ),
        content: SingleChildScrollView(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    border: OutlineInputBorder(),

                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome de usuário',
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
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Função',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'USER', child: Text('Usuário')),
                    DropdownMenuItem(value: 'ADMIN', child: Text('Administrador')),
                  ],
                  onChanged: (value) => selectedRole = value!,
                ),
              ],
            ),
          ),
        ),
        actions: [
          
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  usernameController.text.isEmpty ||
                  passwordController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Preencha todos os campos obrigatórios'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                final authController = Provider.of<AuthController>(context, listen: false);
                final token = authController.getToken();
                
                if (token == null) {
                  throw Exception('Token não encontrado');
                }

                final response = await AdminService.createUser(
                  token: token,
                  name: nameController.text,
                  username: usernameController.text,
                  email: emailController.text.isNotEmpty ? emailController.text : null,
                  password: passwordController.text,
                  role: selectedRole,
                );
                
                if (response['success']) {
                  Navigator.pop(context);
                  await loadUsers();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Usuário criado com sucesso'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else {
                  throw Exception(response['message'] ?? 'Erro ao criar usuário');
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorPrimary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Criar'),
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

  void showEditUserDialog(Map<String, dynamic> user) {
    final nameController = TextEditingController(text: user['name'] ?? '');
    final usernameController = TextEditingController(text: user['username'] ?? '');
    final emailController = TextEditingController(text: user['email'] ?? '');
    final passwordController = TextEditingController();
    String selectedRole = user['role'] ?? 'USER';
    bool isActive = user['active'] ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Editar Usuário',
            style: TextStyle(
              color: colorPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome de usuário',
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
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Nova Senha (deixe em branco para manter)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Função',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'USER', child: Text('Usuário')),
                    DropdownMenuItem(value: 'ADMIN', child: Text('Administrador')),
                  ],
                  onChanged: (value) => selectedRole = value!,
                ),
                const SizedBox(height: 10),
                CheckboxListTile(
                  title: const Text('Usuário ativo'),
                  value: isActive,
                  onChanged: (value) => setState(() => isActive = value!),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
        ),
        actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || usernameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Preencha nome e nome de usuário')),
                  );
                  return;
                }

                try {
                  final authController = Provider.of<AuthController>(context, listen: false);
                  final token = authController.getToken();
                  
                  if (token == null) {
                    throw Exception('Token não encontrado');
                  }

                  final response = await AdminService.updateUser(
                    token: token,
                    userId: user['id'],
                    name: nameController.text,
                    username: usernameController.text,
                    email: emailController.text.isEmpty ? null : emailController.text,
                    password: passwordController.text.isEmpty ? null : passwordController.text,
                    role: selectedRole,
                    active: isActive,
                  );

                    if (response['success']) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Usuário atualizado com sucesso!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                      Navigator.pop(context);
                      await loadUsers();
                    } else {
                      throw Exception(response['message'] ?? 'Erro ao atualizar usuário');
                    }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro ao atualizar usuário: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get filteredUsers {
    if (searchQuery.isEmpty) return users;
    return users.where((user) {
      return (user['name']?.toLowerCase() ?? '').contains(searchQuery.toLowerCase()) ||
             (user['username']?.toLowerCase() ?? '').contains(searchQuery.toLowerCase()) ||
             (user['email']?.toLowerCase() ?? '').contains(searchQuery.toLowerCase());
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
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                  ),
                  const Spacer(),
                  const Text(
                    'Gerenciar Usuários',
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
                                hintText: 'Pesquisar usuários...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FloatingActionButton(
                            onPressed: showCreateUserDialog,
                            backgroundColor: colorSecondary,
                            child: const Icon(Icons.add, color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                    // Lista de usuários
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : filteredUsers.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                                      const SizedBox(height: 10),
                                      Text(
                                        searchQuery.isEmpty 
                                            ? 'Nenhum usuário encontrado'
                                            : 'Nenhum usuário corresponde à pesquisa',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: loadUsers,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    itemCount: filteredUsers.length,
                                    itemBuilder: (context, index) {
                                      final user = filteredUsers[index];
                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.all(16),
                                          leading: CircleAvatar(
                                            backgroundColor: user['role'] == 'ADMIN' 
                                                ? Colors.red.withOpacity(0.2)
                                                : colorSecondary.withOpacity(0.2),
                                            child: Text(
                                              _getInitials(user['name'] ?? user['username'] ?? 'U'),
                                              style: TextStyle(
                                                color: user['role'] == 'ADMIN' 
                                                    ? Colors.red
                                                    : colorSecondary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            user['name'] ?? user['username'] ?? 'Sem nome',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('@${user['username'] ?? 'N/A'}'),
                                              if (user['email'] != null) Text(user['email']),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: user['role'] == 'ADMIN' 
                                                          ? Colors.red.withOpacity(0.1)
                                                          : Colors.blue.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      user['role'] == 'ADMIN' ? 'Admin' : 'Usuário',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: user['role'] == 'ADMIN' 
                                                            ? Colors.red
                                                            : Colors.blue,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: user['active'] == true 
                                                          ? Colors.green.withOpacity(0.1)
                                                          : Colors.grey.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      user['active'] == true ? 'Ativo' : 'Inativo',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: user['active'] == true 
                                                            ? Colors.green
                                                            : Colors.grey,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          trailing: PopupMenuButton<String>(
                                            onSelected: (value) async {
                                              switch (value) {
                                                case 'edit':
                                                  showEditUserDialog(user);
                                                  break;
                                                case 'toggle_status':
                                                  await toggleUserStatus(
                                                    user['id'],
                                                    user['active'] == true,
                                                  );
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
                                                      user['active'] == true 
                                                          ? Icons.visibility_off 
                                                          : Icons.visibility,
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      user['active'] == true 
                                                          ? 'Desativar' 
                                                          : 'Ativar',
                                                    ),
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

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else {
      return words[0].length >= 2 
          ? words[0].substring(0, 2).toUpperCase()
          : words[0][0].toUpperCase();
    }
  }
}
