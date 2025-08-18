import 'package:flutter/material.dart';
import 'package:tcis_app/constants.dart';
import '../../model/full_report_model.dart';
import '../../components/report_card.dart';
import '../../components/secondary_report_card.dart';
import 'package:tcis_app/screens/reports/create_report.dart';
import 'package:tcis_app/screens/reports/edit_report.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/report_api_service.dart';
import '../test_api_screen.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {

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
      print('🔍 DEBUG: Carregando relatórios do servidor...');
      
      final reports = await ReportApiService.getReports(
        page: 1,
        limit: 50,
      );
      
      print('🔍 DEBUG: Server reports response count: ${reports.length}');
      
      for (int i = 0; i < reports.length && i < 3; i++) {
        final report = reports[i];
        print('📊 DEBUG: Report $i structure:');
        print('   ID: ${report['id']}');
        print('   Prefix: ${report['prefix']}');
        print('   Status: ${report['status']}');
        print('   Terminal: ${report['terminal']}');
        print('   Product: ${report['product']}');
        print('   Employee: ${report['employee']}');
        print('   Images: ${report['images']}');
        print('   ImageUrls: ${report['imageUrls']}');
        print('   PdfUrl: ${report['pdfUrl']}');
        print('   Full report: ${report.toString().substring(0, 200)}...');
        print('');
      }

      if (mounted) {
        setState(() {
          serverReports = reports;
          isLoadingReports = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar relatórios do servidor: $e');
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
      print('🔄 Buscando dados atualizados do relatório ${report['id']}...');
      
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
      print('Erro ao abrir edição: $e');
      
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
        print('Erro no fallback: $fallbackError');
        
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
                    child: CircularProgressIndicator(),
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
                      terminal: report['terminal']?['name'] ?? 'N/A',
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TestApiScreen()),
          );
        },
        icon: const Icon(Icons.api),
        label: const Text('Teste API'),
        backgroundColor: colorPrimary,
      ),
    );
  }
}
