import 'package:flutter/material.dart';
import 'package:tcis_app/constants.dart';
import '../../model/full_report_model.dart';
import '../../components/report_card.dart';
import '../../components/secondary_report_card.dart';
import '../../components/custom_loading_widget.dart';
import 'package:tcis_app/screens/reports/create_report.dart';
import 'package:tcis_app/screens/reports/edit_report.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/report_api_service.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../profile/user_profile_screen.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});


  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  List<FullReportModel> fullReports = []; // Relatórios locais (rascunhos)
  List<Map<String, dynamic>> serverReports = []; // Relatórios do servidor
  bool isLoadingReports = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadReports();
    loadServerReports();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App voltou ao foco - recarregar dados
      loadReports();
      loadServerReports();
    }
  }

  Future<void> loadReports() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('full_reports') ?? [];
    final reports =
        data.map((e) => FullReportModel.fromJson(jsonDecode(e))).toList();
    setState(() {
      fullReports = reports.reversed.toList();
    });
  }

  Future<void> loadServerReports() async {
    if (!mounted) return;
    
    setState(() {
      isLoadingReports = true;
    });

    try {
      
      final reports = await ReportApiService.getReports(
        page: 1,
        limit: 50,
      );
      
      
      for (int i = 0; i < reports.length && i < 3; i++) {
        final report = reports[i];
      }

      if (mounted) {
        setState(() {
          serverReports = reports;
          isLoadingReports = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          serverReports = [];
          isLoadingReports = false;
        });
      }
    }
  }

  /// Força recarregamento completo dos dados
  Future<void> forceRefresh() async {
    await loadReports();
    await loadServerReports();
    if (mounted) {
      setState(() {});
    }
  }

  void _editServerReport(Map<String, dynamic> report) async {
    try {
      // Buscar dados atualizados do servidor antes de abrir a edição
      
      // Recarregar dados do servidor para ter certeza que estão atualizados
      await loadServerReports();
      
      // Encontrar o relatório atualizado na lista
      final updatedReport = serverReports.firstWhere(
        (r) => r['id'] == report['id'], 
        orElse: () => report, // Se não encontrar, usar o original
      );
      
      // Converter dados do servidor para FullReportModel
      final reportModel = FullReportModel.fromServerData(updatedReport);
      
      // Navegar para tela de edição
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditReportScreen(report: reportModel),
        ),
      );
      
      // Se houve alteração, recarregar dados
      if (result == true) {
        await forceRefresh(); // Usar método unificado de refresh
      }
    } catch (e) {
      
      // Fallback: usar dados originais se houver erro
      try {
        final reportModel = FullReportModel.fromServerData(report);
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditReportScreen(report: reportModel),
          ),
        );
        
        if (result == true) {
          await forceRefresh();
        }
      } catch (fallbackError) {
        
        // Mostrar diálogo de erro apenas se ambas as tentativas falharem
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Erro'),
                content: Text('Não foi possível abrir o relatório para edição.\n\nDetalhes: $e'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      }
    }
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

  Widget _BuildBlankReport(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      height: 230,
      width: 230,
      decoration: BoxDecoration(
        color: Color(0xFFC3C3C3),
        borderRadius: const BorderRadius.all(Radius.circular(30)),
      ),
      child: Center(
        child: IconButton(
          icon: Icon(Icons.add, color: Colors.white, size: 50),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ReportEntryScreen()),
            ).then((_) {
              loadReports();
              loadServerReports(); // Atualizar também relatórios do servidor
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: forceRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(), // Sempre permite scroll para o refresh
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                
                // Header com perfil do usuário
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Consumer<AuthController>(
                    builder: (context, authController, child) {
                      final user = authController.currentUser;
                      return Row(
                        children: [
                          // Avatar do usuário
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const UserProfileScreen(),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colorSecondary,
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 25,
                                backgroundColor: colorSecondary,
                                child: Text(
                                  _getInitials(user?.name ?? user?.username ?? 'U'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 12),
                          
                          // Saudação
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Olá,',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  user?.name ?? user?.username ?? 'Usuário',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 30),
                
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Relatórios em Andamento",
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall!.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReportEntryScreen(),
                              ),
                            ).then((_) {
                              loadReports();
                              loadServerReports(); // Atualizar também relatórios do servidor
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20),
                  child: Row(
                    children: [
                      ...fullReports
                          .where((report) => report.status == 0)
                          .map(
                            (report) => Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: reportCard(
                                report: report,
                                onDeleted: () async {
                                  await loadReports();
                                  setState(
                                    () {},
                                  ); // apenas para forçar o rebuild após o await
                                },
                                onUpdated: () async {
                                  await forceRefresh(); // Usar método unificado
                                }, // novo callback
                              ),
                            ),
                          ),
                      _BuildBlankReport(context),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "Recentes",
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Relatórios do servidor (seção Recentes)
              if (isLoadingReports)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CompactLoadingWidget(
                      message: 'Carregando relatórios...',
                      size: 60.0,
                    ),
                  ),
                )
              else if (serverReports.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    "Nenhum relatório encontrado",
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ...serverReports.map(
                  (report) => Padding(
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      bottom: 10,
                    ),
                    child: SecondaryreportCard(
                      title: report['prefix'] ?? 'Sem prefixo',
                      iconSrc: "assets/icons/ios.svg",
                      colorl: colorSecondary,
                      data: report['createdAt'] != null
                          ? DateFormat('dd/MM/yyyy').format(DateTime.parse(report['createdAt']))
                          : 'N/A',
                      usuario: report['user']?['name'] ?? 'N/A',
                      fornecedor: report['supplier']?['name'] ?? 'N/A',
                      produto: report['product']?['name'] ?? 'N/A',
                      terminal: report['terminal']?['code'] ?? 'N/A',
                      // Novos campos de listas
                      fornecedores: report['suppliers'] != null 
                          ? List<String>.from(report['suppliers'].map((s) => s['name']))
                          : [],
                      produtos: report['products'] != null 
                          ? List<String>.from(report['products'].map((p) => p['name']))
                          : [],
                      pathPdf: report['pdfUrl'] != null && (report['pdfUrl'] as String).isNotEmpty
                          ? (report['pdfUrl'] as String).startsWith('http')
                              ? report['pdfUrl'] // Já é URL completa
                              : '$API_BASE_URL/${report['pdfUrl']}' // Adicionar base URL
                          : '',
                      status: (report['status'] ?? 1).toString(),
                      onEdit: () {
                        _editServerReport(report);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () {
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(builder: (context) => const TestApiScreen()),
      //     );
      //   },
      //   icon: const Icon(Icons.api),
      //   label: const Text('Teste API'),
      //   backgroundColor: colorPrimary,
      // ),
    );
  }
}
