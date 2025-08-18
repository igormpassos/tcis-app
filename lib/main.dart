import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tcis_app/screens/home/home_screen.dart';
import 'package:tcis_app/screens/reports/create_report.dart';
import 'package:tcis_app/styles.dart';
import 'package:tcis_app/screens/login/login.dart';
import 'package:tcis_app/screens/examples/report_form_example.dart';
import 'package:tcis_app/screens/test_api_screen.dart';
import 'package:tcis_app/screens/test_image.dart';
import 'package:tcis_app/controllers/auth_controller.dart';
import 'package:tcis_app/controllers/data_controller.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => DataController()),
      ],
      child: MaterialApp(
        title: 'TCIS - Inspeção de Carga',
        theme: NewTheme,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('pt', 'BR'),
        ],
        home: const AppInitializer(),
        routes: {
          '/login': (context) => Login(),
          '/home': (context) => HomePage(),
          '/reports': (context) => ReportEntryScreen(),
          '/example-form': (context) => const ReportFormExample(),
          '/test-api': (context) => const TestApiScreen(),
          '/test-image': (context) => const TestImageScreen(),
        },
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    // Usando WidgetsBinding.addPostFrameCallback para evitar setState durante build
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeApp());
  }

  Future<void> _initializeApp() async {
    final authController = Provider.of<AuthController>(context, listen: false);
    await authController.initialize();
    
    // Se estiver autenticado, carrega os dados
    if (authController.isAuthenticated) {
      final dataController = Provider.of<DataController>(context, listen: false);
      await dataController.loadAllData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, child) {
        if (authController.isLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Inicializando aplicação...'),
                ],
              ),
            ),
          );
        }

        // Se está autenticado, vai para home, senão para login
        if (authController.isAuthenticated) {
          return HomePage();
        } else {
          return Login();
        }
      },
    );
  }
}
