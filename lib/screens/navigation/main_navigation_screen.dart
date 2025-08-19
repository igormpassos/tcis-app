import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../constants.dart';
import '../home/home_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../profile/user_profile_screen.dart';
import '../reports/create_report.dart';
import '../admin/all_reports_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, child) {
        // Lista de telas baseada no tipo de usuário
        List<Widget> screens = [
          const HomePage(),
          const ReportEntryScreen(),
          if (authController.isAdmin) const AdminDashboardScreen(),
          if (authController.isAdmin) const AllReportsScreen(),
          const UserProfileScreen(),
        ];

        // Lista de itens do bottom navigation baseada no tipo de usuário
        List<BottomNavigationBarItem> navItems = [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Início',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            activeIcon: Icon(Icons.add_box),
            label: 'Criar',
          ),
          if (authController.isAdmin) ...[
            const BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings_outlined),
              activeIcon: Icon(Icons.admin_panel_settings),
              label: 'Admin',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.assessment_outlined),
              activeIcon: Icon(Icons.assessment),
              label: 'Relatórios',
            ),
          ],
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ];

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: colorPrimary,
            unselectedItemColor: Colors.grey,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
            elevation: 8,
            items: navItems,
          ),
        );
      },
    );
  }
}
