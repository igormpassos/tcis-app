import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tcis_app/components/custom_loading_widget.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tcis_app/constants.dart';
import 'package:tcis_app/utils/utils.dart';
import 'package:tcis_app/model/full_report_model.dart';
import 'package:tcis_app/controllers/report/report_pdf.dart';
import 'package:tcis_app/components/custom_loading_dialog.dart';
import 'package:tcis_app/widgets/reports/dados_relatorio_card_api.dart';
import 'package:tcis_app/widgets/reports/dados_locomotiva_card.dart';
import 'package:tcis_app/widgets/reports/dados_carregamento_card.dart';
import '../../controllers/data_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../services/connectivity_service.dart';
import '../../services/report_api_service.dart';
import '../../utils/datetime_utils.dart';

class ReportEntryScreen extends StatefulWidget {
  const ReportEntryScreen({super.key});

  @override
  State<ReportEntryScreen> createState() => _ReportEntryScreenState();
}

class _ReportEntryScreenState extends State<ReportEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<Map<String, dynamic>> _images =
      []; // Lista para armazenar as imagens e metadados

  // Estado de conectividade
  bool _hasInternetConnection = false;

  @override
  void initState() {
    super.initState();
    // Carregar dados da API quando a tela inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DataController>().loadAllData();
      _checkConnectivity();
      
      // Se não é admin, define o colaborador como o usuário logado
      final authController = context.read<AuthController>();
      if (authController.currentUser?.role != 'ADMIN') {
        setState(() {
          colaborador = authController.currentUser?.name ?? authController.currentUser?.username;
        });
      }
    });
  }

  /// Verifica conectividade com a internet
  Future<void> _checkConnectivity() async {
    final hasConnection = await ConnectivityService.hasInternetConnection();
    setState(() {
      _hasInternetConnection = hasConnection;
    });
  }

  // Função para selecionar várias imagens da galeria
  Future<void> _addImage() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => const CustomLoadingDialog(message: "Carregando imagens..."),
    );

    try {
      final newImages = await ImageUtils.pickImagesWithMetadata();
      if (newImages.isNotEmpty) {
        setState(() => _images.addAll(newImages));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar imagens: $e')));
    } finally {
      Navigator.of(context).pop();
    }
  }

  // Função para remover uma imagem
  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  // Controllers and variables to store form data
  final TextEditingController prefixoController = TextEditingController();
  String? selectedTerminal;
  String? selectedProduto; // DEPRECATED - usar selectedProdutos
  
  // Novos campos multi-select
  List<String> selectedProdutos = [];
  List<String> selectedFornecedores = [];
  String? selectedVagao;
  String? colaborador;
  String? fornecedor;
  String? selectedCliente;
  String? selectedValue;
  final TextEditingController dataInicioController = TextEditingController();
  final TextEditingController horarioChegadaController =
      TextEditingController();
  final TextEditingController horarioInicioController = TextEditingController();
  final TextEditingController horarioTerminoController =
      TextEditingController();
  final TextEditingController horarioSaidaController = TextEditingController();
  final TextEditingController dataTerminoController = TextEditingController();
  bool? houveContaminacao;
  String contaminacaoDescricao = '';
  String? materialHomogeneo;
  String? umidadeVisivel;
  String? houveChuva;
  String? fornecedorAcompanhou;
  final TextEditingController observacoesController = TextEditingController();

  Future<void> onSubmitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Mostrar loading usando componente
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (_) => const CustomLoadingWidget(message: "Gerando relatório..."),
      );

      try {
        await generatePdf(
          prefixoController: prefixoController,
          selectedTerminal: selectedTerminal,
          selectedProduto: selectedProduto ?? '',
          selectedVagao: selectedVagao,
          colaborador: colaborador,
          fornecedor: fornecedor ?? '',
          selectedValue: selectedValue,
          // Passar as listas para o PDF
          selectedProdutos: selectedProdutos,
          selectedFornecedores: selectedFornecedores,
          dataInicioController: dataInicioController,
          horarioChegadaController: horarioChegadaController,
          horarioInicioController: horarioInicioController,
          horarioTerminoController: horarioTerminoController,
          horarioSaidaController: horarioSaidaController,
          dataTerminoController: dataTerminoController,
          houveContaminacao: houveContaminacao,
          contaminacaoDescricao: contaminacaoDescricao,
          materialHomogeneo: materialHomogeneo,
          umidadeVisivel: umidadeVisivel,
          houveChuva: houveChuva,
          fornecedorAcompanhou: fornecedorAcompanhou,
          observacoesController: observacoesController,
          images: _images,
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erro ao gerar relatório: $e")));
      } finally {
        Navigator.of(context).pop(); // Fecha o loading
      }
    }
  }

  /// Envia relatório para o servidor
  Future<void> submitToServer() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha todos os campos obrigatórios'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validar datas/horários
    final dateTimeValidation = DateTimeUtils.getValidationError(
      startDateStr: dataInicioController.text,
      startTimeStr: horarioInicioController.text,
      endDateStr: dataTerminoController.text,
      endTimeStr: horarioTerminoController.text,
    );

    if (dateTimeValidation.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(dateTimeValidation),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_hasInternetConnection) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sem conexão com a internet. Salvando como rascunho.'),
          backgroundColor: Colors.orange,
        ),
      );
      await saveDraft();
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CustomLoadingWidget(message: "Enviando relatório..."),
    );

    try {
      // Preparar arquivos de imagem
      final imageFiles = <File>[];
      for (var imageData in _images) {
        final file = imageData['file'] as File?;
        if (file != null && await file.exists()) {
          imageFiles.add(file);
        }
      }

      // Criar modelo do relatório
      final uuid = const Uuid();
      final reportData = FullReportModel(
        id: uuid.v4(),
        prefixo: prefixoController.text,
        terminal: selectedTerminal ?? '',
        produto: selectedProduto ?? '',
        colaborador: colaborador ?? '',
        fornecedor: fornecedor ?? '',
        cliente: selectedCliente ?? '',
        dataInicio: dataInicioController.text,
        horarioInicio: horarioInicioController.text,
        dataTermino: dataTerminoController.text,
        horarioTermino: horarioTerminoController.text,
        horarioChegada: horarioChegadaController.text,
        horarioSaida: horarioSaidaController.text,
        houveContaminacao: houveContaminacao,
        contaminacaoDescricao: contaminacaoDescricao,
        materialHomogeneo: materialHomogeneo ?? '',
        umidadeVisivel: umidadeVisivel ?? '',
        houveChuva: houveChuva ?? '',
        fornecedorAcompanhou: fornecedorAcompanhou ?? '',
        observacoes: observacoesController.text,
        imagens: _images.map((img) => img['file'].path.toString()).toList(),
        pathPdf: '',
        dataCriacao: DateTime.now(),
        status: 1, // Finalizado
        // Adicionar as listas multi-select
        produtos: selectedProdutos,
        fornecedores: selectedFornecedores,
      );

      final dataController = context.read<DataController>();

      // Enviar para servidor usando o novo fluxo
      final result = await ReportApiService.submitReport(
        report: reportData,
        dataController: dataController,
        imageFiles: imageFiles,
      );

      if (mounted) {
        Navigator.of(context).pop(); // fecha loading

        if (result['success'] == true) {
          // Sucesso: mostrar mensagem e abrir PDF
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Relatório enviado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );

          // Abrir PDF usando a URL do servidor
          final pdfUrl = result['data']['pdf_url'];
          if (pdfUrl != null && pdfUrl.isNotEmpty) {
            await _openServerPdf(pdfUrl);
          }

          // Voltar para tela principal indicando que houve mudança
          Navigator.popUntil(context, (route) => route.isFirst);
          
        } else {
          // Erro: mostrar mensagem
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Erro ao enviar relatório: ${result['message']}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // fecha loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao enviar relatório: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Abrir PDF do servidor
  Future<void> _openServerPdf(String pdfUrl) async {
    try {
      String fullUrl;
      
      // Garantir que temos uma URL completa
      if (pdfUrl.startsWith('http')) {
        fullUrl = pdfUrl;
      } else {
        fullUrl = '$API_BASE_URL/$pdfUrl';
      }
      
      final uri = Uri.parse(fullUrl);
      
      // Mostrar mensagem de carregamento
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Abrindo PDF...'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      // Tentar abrir com aplicação externa (recomendado para PDFs)
      bool success = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      
      // Se falhou, tentar com navegador interno
      if (!success) {
        success = await launchUrl(
          uri,
          mode: LaunchMode.inAppWebView,
        );
      }
      
      // Se ainda falhou, tentar modo padrão do sistema
      if (!success) {
        success = await launchUrl(uri);
      }
      
      // Se todas as tentativas falharam
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Não foi possível abrir o PDF automaticamente'),
                const SizedBox(height: 8),
                Text(
                  'URL: $fullUrl',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Copie a URL e cole no navegador ou instale um leitor de PDF',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            duration: const Duration(seconds: 8),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Copiar URL',
              onPressed: () {
                // Implementar cópia da URL se necessário
              },
            ),
          ),
        );
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> saveDraft() async {
    final uuid = const Uuid();
    final prefs = await SharedPreferences.getInstance();

    final reportData = FullReportModel(
      id: uuid.v4(),
      prefixo: prefixoController.text,
      terminal: selectedTerminal ?? '',
      produto: selectedProduto ?? '',
      colaborador: colaborador ?? '',
      fornecedor: fornecedor ?? '',
      cliente: selectedCliente ?? '',
      dataInicio: dataInicioController.text,
      horarioInicio: horarioInicioController.text,
      dataTermino: dataTerminoController.text,
      horarioTermino: horarioTerminoController.text,
      horarioChegada: horarioChegadaController.text,
      horarioSaida: horarioSaidaController.text,
      houveContaminacao: houveContaminacao,
      contaminacaoDescricao: contaminacaoDescricao,
      materialHomogeneo: materialHomogeneo ?? '',
      umidadeVisivel: umidadeVisivel ?? '',
      houveChuva: houveChuva ?? '',
      fornecedorAcompanhou: fornecedorAcompanhou ?? '',
      observacoes: observacoesController.text,
      imagens: _images.map((img) => img['file'].path.toString()).toList(),
      pathPdf: '', // ainda não foi gerado
      dataCriacao: DateTime.now(),
      status: 0, // Rascunho (local apenas)
      // Adicionar as listas multi-select
      produtos: selectedProdutos,
      fornecedores: selectedFornecedores,
    );

    final savedReports = prefs.getStringList('full_reports') ?? [];
    savedReports.add(jsonEncode(reportData.toJson()));
    await prefs.setStringList('full_reports', savedReports);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Rascunho salvo com sucesso.')));

    // Voltar para tela principal indicando que houve mudança
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Criar Relatório'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Verifica se pode voltar, senão vai para home
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Salvar',
              onPressed: saveDraft,
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DadosRelatorioCardApi(
                    prefixoController: prefixoController,
                    selectedTerminal: selectedTerminal,
                    onTerminalChanged:
                        (val) => setState(() => selectedTerminal = val),
                    colaborador: colaborador,
                    onColaboradorChanged:
                        (val) => setState(() => colaborador = val),
                    selectedProdutos: selectedProdutos,
                    onProdutosChanged:
                        (val) => setState(() {
                          selectedProdutos = val;
                          selectedProduto = val.isNotEmpty ? val.first : null;
                        }),
                    selectedFornecedores: selectedFornecedores,
                    onFornecedoresChanged:
                        (val) => setState(() {
                          selectedFornecedores = val;
                          fornecedor = val.isNotEmpty ? val.first : null;
                        }),
                    selectedCliente: selectedCliente,
                    onClienteChanged:
                        (val) => setState(() => selectedCliente = val),
                  ),

                  const SizedBox(height: 16),
                  DadosLocomotivaCard(
                    horarioChegadaController: horarioChegadaController,
                    horarioSaidaController: horarioSaidaController,
                    selectedVagao: selectedVagao,
                    onVagaoChanged:
                        (value) => setState(() => selectedVagao = value),
                    onSelectTime:
                        (controller) => selectTime(
                          context: context,
                          controller: controller,
                          primaryColor: colorPrimary,
                        ),
                  ),

                  const SizedBox(height: 16),
                  DadosCarregamentoCard(
                    dataInicioController: dataInicioController,
                    horarioInicioController: horarioInicioController,
                    dataTerminoController: dataTerminoController,
                    horarioTerminoController: horarioTerminoController,
                    houveContaminacao: houveContaminacao,
                    onContaminacaoChanged:
                        (val) => setState(() => houveContaminacao = val),
                    contaminacaoDescricao: contaminacaoDescricao,
                    onDescricaoChanged:
                        (val) => setState(() => contaminacaoDescricao = val),
                    materialHomogeneo: materialHomogeneo,
                    onMaterialChanged:
                        (val) => setState(() => materialHomogeneo = val),
                    umidadeVisivel: umidadeVisivel,
                    onUmidadeChanged:
                        (val) => setState(() => umidadeVisivel = val),
                    houveChuva: houveChuva,
                    onChuvaChanged: (val) => setState(() => houveChuva = val),
                    fornecedorAcompanhou: fornecedorAcompanhou,
                    onFornecedorChanged:
                        (val) => setState(() => fornecedorAcompanhou = val),
                    observacoesController: observacoesController,
                    images: _images,
                    onAddImage: _addImage,
                    onRemoveImage: _removeImage,
                    onSelectDate:
                        (controller) => selectDate(
                          context: context,
                          controller: controller,
                          primaryColor: colorPrimary,
                        ),

                    onSelectTime:
                        (controller) => selectTime(
                          context: context,
                          controller: controller,
                          primaryColor: colorPrimary,
                        ),
                  ),

                  const SizedBox(height: 16),

                  // Botões condicionais baseados na conectividade
                  if (_hasInternetConnection) ...[
                    // Com conexão: duas opções
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.send),
                            label: const Text('Enviar relatório'),
                            onPressed: submitToServer,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.save),
                            label: const Text('Salvar como Rascunho'),
                            onPressed: saveDraft,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Sem conexão: apenas rascunho
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        border: Border.all(color: Colors.orange),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.wifi_off, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Sem conexão - Apenas rascunho disponível',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('Salvar como Rascunho'),
                        onPressed: saveDraft,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
