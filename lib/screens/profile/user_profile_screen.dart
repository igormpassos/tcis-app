import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../constants.dart';
import '../login/login.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, child) {
        final user = authController.currentUser;
        
        if (user == null) {
          return const Scaffold(
            body: Center(
              child: Text('Usuário não encontrado'),
            ),
          );
        }

        return Scaffold(
          backgroundColor: colorPrimary,
          resizeToAvoidBottomInset: false,
          body: SafeArea(
            child: Column(
              children: [
                // Header com botão de voltar
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          // Verifica se pode voltar, senão vai para home
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                          }
                        },
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Perfil do Usuário',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 40), // Espaço para balancear o layout
                    ],
                  ),
                ),
                
                // Avatar do usuário
                Container(
                  margin: const EdgeInsets.only(bottom: 30),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: colorSecondary,
                      child: Text(
                        _getInitials(user.name ?? user.username),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                // Container com informações do usuário
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
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width < 600 ? 20 : 30,
                        vertical: 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          
                          // Nome
                          _buildInfoCard(
                            context,
                            'Nome',
                            user.name ?? 'Não informado',
                            Icons.person,
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Username
                          _buildInfoCard(
                            context,
                            'Usuário',
                            user.username,
                            Icons.account_circle,
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Email
                          _buildInfoCard(
                            context,
                            'Email',
                            user.email ?? 'Não informado',
                            Icons.email,
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Role
                          _buildInfoCard(
                            context,
                            'Função',
                            _getRoleDisplayName(user.role),
                            Icons.work,
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Botão de Logout
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: authController.isLoading 
                                ? null 
                                : () => _showLogoutDialog(context, authController),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              icon: authController.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.logout),
                              label: Text(
                                authController.isLoading ? 'Saindo...' : 'Sair',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          
                          SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 40 : 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: colorPrimary,
            size: MediaQuery.of(context).size.width < 600 ? 22 : 24,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width < 600 ? 12 : 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width < 600 ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
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

  String _getRoleDisplayName(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return 'Administrador';
      case 'USER':
        return 'Usuário';
      default:
        return role;
    }
  }

  void _showLogoutDialog(BuildContext context, AuthController authController) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Saída'),
          content: const Text('Tem certeza que deseja sair da sua conta?'),
          actions: [
            // TextButton(
            //   onPressed: () => Navigator.of(context).pop(),
            //   style: TextButton.styleFrom(
            //     foregroundColor: Colors.grey[700],
            //   ),
            //   child: const Text('Cancelar'),
            // ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Fechar dialog
                await authController.logout();

                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const Login()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );
  }
}
