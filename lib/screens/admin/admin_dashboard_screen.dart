import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../constants.dart';
import 'user_management_screen.dart';
import 'supplier_management_screen.dart';
import 'product_management_screen.dart';
import 'terminal_management_screen.dart';
import 'client_management_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, child) {
        // Verificar se é administrador
        if (!authController.isAdmin) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning,
                    size: 64,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Acesso Negado',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Você não tem permissão para acessar esta área.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Verifica se pode voltar, senão vai para home
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                      }
                    },
                    child: const Text('Voltar'),
                  ),
                ],
              ),
            ),
          );
        }

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
                        'Painel Administrativo',
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
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width < 600 ? 20 : 30,
                        vertical: 30,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gerenciamento',
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width < 600 ? 20 : 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Gerencie usuários, fornecedores, produtos e relatórios',
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width < 600 ? 14 : 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 30),

                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                // Determina o número de colunas baseado na largura da tela
                                int crossAxisCount;
                                double childAspectRatio;
                                double iconSize;
                                
                                if (constraints.maxWidth > 1200) {
                                  // Desktop grande
                                  crossAxisCount = 4;
                                  childAspectRatio = 1.1;
                                  iconSize = 28;
                                } else if (constraints.maxWidth > 800) {
                                  // Desktop pequeno / Tablet grande
                                  crossAxisCount = 3;
                                  childAspectRatio = 1.0;
                                  iconSize = 30;
                                } else if (constraints.maxWidth > 600) {
                                  // Tablet
                                  crossAxisCount = 3;
                                  childAspectRatio = 0.9;
                                  iconSize = 32;
                                } else if (constraints.maxWidth > 400) {
                                  // Mobile grande
                                  crossAxisCount = 2;
                                  childAspectRatio = 1.0;
                                  iconSize = 32;
                                } else {
                                  // Mobile pequeno
                                  crossAxisCount = 2;
                                  childAspectRatio = 0.85;
                                  iconSize = 28;
                                }

                                return GridView.count(
                                  shrinkWrap: true,
                                  physics: const BouncingScrollPhysics(),
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 15,
                                  mainAxisSpacing: 15,
                                  childAspectRatio: childAspectRatio,
                                  children: [
                                    _buildAdminCard(
                                      context,
                                      'Usuários',
                                      'Gerenciar usuários do sistema',
                                      Icons.people,
                                      Colors.blue,
                                      iconSize,
                                      () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const UserManagementScreen(),
                                        ),
                                      ),
                                    ),
                                    _buildAdminCard(
                                      context,
                                      'Fornecedores',
                                      'Gerenciar fornecedores',
                                      Icons.business,
                                      Colors.green,
                                      iconSize,
                                      () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const SupplierManagementScreen(),
                                        ),
                                      ),
                                    ),
                                    _buildAdminCard(
                                      context,
                                      'Produtos',
                                      'Gerenciar produtos',
                                      Icons.inventory_2,
                                      Colors.orange,
                                      iconSize,
                                      () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const ProductManagementScreen(),
                                        ),
                                      ),
                                    ),
                                    _buildAdminCard(
                                      context,
                                      'Terminais',
                                      'Gerenciar terminais',
                                      Icons.location_on,
                                      Colors.purple,
                                      iconSize,
                                      () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const TerminalManagementScreen(),
                                        ),
                                      ),
                                    ),
                                    _buildAdminCard(
                                      context,
                                      'Clientes',
                                      'Gerenciar clientes',
                                      Icons.people_alt,
                                      Colors.teal,
                                      iconSize,
                                      () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const ClientManagementScreen(),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
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

  Widget _buildAdminCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    double iconSize,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 12 : 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: iconSize,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width < 600 ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width < 600 ? 10 : 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
