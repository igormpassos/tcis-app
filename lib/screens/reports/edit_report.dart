import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tcis_app/constants.dart';
import 'package:tcis_app/utils/utils.dart';
import 'package:tcis_app/model/full_report_model.dart';
import 'package:tcis_app/controllers/report/report_pdf.dart';
import 'package:tcis_app/controllers/data_controller.dart';
import 'package:tcis_app/controllers/auth_controller.dart';
import 'package:tcis_app/components/custom_loading_dialog.dart';
import 'package:tcis_app/controllers/report/report_mananger.dart';
import 'package:tcis_app/widgets/reports/dados_relatorio_card_api.dart';
import 'package:tcis_app/widgets/reports/dados_locomotiva_card.dart';
import 'package:tcis_app/widgets/reports/dados_carregamento_card.dart';
import 'package:tcis_app/services/connectivity_service.dart';
import 'package:tcis_app/services/report_api_service.dart';
import 'package:tcis_app/services/image_upload_service.dart';
import 'package:tcis_app/utils/datetime_utils.dart';

class EditReportScreen extends StatefulWidget {
  final FullReportModel report;

  const EditReportScreen({super.key, required this.report});

  @override
  State<EditReportScreen> createState() => _EditReportScreenState();
}

class _EditReportScreenState extends State<EditReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<Map<String, dynamic>> _images = [];

  final TextEditingController prefixoController = TextEditingController();
  final TextEditingController dataInicioController = TextEditingController();
  final TextEditingController horarioChegadaController =
      TextEditingController();
  final TextEditingController horarioInicioController = TextEditingController();
  final TextEditingController horarioTerminoController =
      TextEditingController();
  final TextEditingController horarioSaidaController = TextEditingController();
  final TextEditingController dataTerminoController = TextEditingController();
  final TextEditingController observacoesController = TextEditingController();

  String? selectedTerminal;
  String? selectedProduto;
  String? selectedVagao;
  String? colaborador;
  String? fornecedor;
  String? selectedCliente;
  String? selectedValue;
  bool? houveContaminacao;
  String contaminacaoDescricao = '';
  String? materialHomogeneo;
  String? umidadeVisivel;
  String? houveChuva;
  String? fornecedorAcompanhou;
  
  // Estado de conectividade
  bool _hasInternetConnection = false;

  void limparDropdownsVazios() {
    if (selectedTerminal?.isEmpty ?? false) selectedTerminal = null;
    if (selectedProduto?.isEmpty ?? false) selectedProduto = null;
    if (selectedValue?.isEmpty ?? false) selectedValue = null;
    if (selectedVagao?.isEmpty ?? false) selectedVagao = null;
    if (colaborador?.isEmpty ?? false) colaborador = null;
    if (selectedCliente?.isEmpty ?? false) selectedCliente = null;
  }

  @override
  void initState() {
    super.initState();
    
    // Carregar dados existentes primeiro
    _loadExistingData();
    
    // Depois carregar dados da API e verificar conectividade
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DataController>().loadAllData();
      _checkConnectivity();
      
      // Se não há colaborador definido e não é admin, define o usuário logado
      final authController = context.read<AuthController>();
      if ((colaborador?.isEmpty ?? true) && authController.currentUser?.role != 'ADMIN') {
        setState(() {
          colaborador = authController.currentUser?.name ?? authController.currentUser?.username;
        });
      }
      
      // Para não-admins, sempre define CSN como cliente padrão se não houver um selecionado
      if (authController.currentUser?.role != 'ADMIN' && (selectedCliente?.isEmpty ?? true)) {
        setState(() {
          selectedCliente = 'CSN - Companhia Siderúrgica Nacional';
        });
      } else if (authController.currentUser?.role == 'ADMIN' && (selectedCliente?.isEmpty ?? true)) {
        setState(() {
          selectedCliente = 'CSN - Companhia Siderúrgica Nacional';
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

  void _loadExistingData() {
    final r = widget.report;
    prefixoController.text = r.prefixo;
    selectedTerminal = r.terminal;
    selectedProduto = r.produto;
    colaborador = r.colaborador;
    fornecedor = r.fornecedor;
    selectedCliente = r.cliente;
    selectedValue = null; // Campo removido
    
    // Converter datas para formato brasileiro (dd/MM/yyyy) se necessário
    dataInicioController.text = _convertToBrazilianDate(r.dataInicio);
    horarioInicioController.text = r.horarioInicio;
    dataTerminoController.text = _convertToBrazilianDate(r.dataTermino);
    horarioTerminoController.text = r.horarioTermino;
    horarioChegadaController.text = r.horarioChegada;
    horarioSaidaController.text = r.horarioSaida;
    
    houveContaminacao = r.houveContaminacao;
    contaminacaoDescricao = r.contaminacaoDescricao;
    materialHomogeneo = r.materialHomogeneo;
    umidadeVisivel = r.umidadeVisivel;
    houveChuva = r.houveChuva;
    fornecedorAcompanhou = r.fornecedorAcompanhou;
    observacoesController.text = r.observacoes;

    limparDropdownsVazios();

    print('   Processing ${r.imagens.length} images...');
    for (var path in r.imagens) {
      print('   Checking image path: $path');
      final file = File(path);
      if (file.existsSync()) {
        print('   ✅ Local file exists: $path');
        _images.add({'file': file, 'timestamp': file.lastModifiedSync()});
      } else {
        print('   ❌ Local file not found: $path');
        // Para URLs de servidor, converter caminho relativo em URL completa
        if (path.startsWith('uploads/')) {
          // É uma URL do servidor, converter para URL completa
          final fullUrl = '$API_BASE_URL/$path';
          print('   📡 Adding as server URL: $fullUrl');
          _images.add({'url': fullUrl, 'timestamp': DateTime.now()});
        } else if (path.startsWith('http')) {
          print('   📡 Adding as complete URL: $path');
          _images.add({'url': path, 'timestamp': DateTime.now()});
        }
      }
    }
    setState(() {}); // Força atualização da UI após carregar os dados
  }

    // Verifica se é um relatório do servidor (UUID format)
  bool _isServerReport() {
    // UUID tem 36 caracteres no formato 8-4-4-4-12
    return widget.report.id.length == 36 && widget.report.id.contains('-');
  }

  // Extrai o nome da pasta existente a partir das URLs das imagens
  String _getExistingFolderName() {
    // Procurar por uma imagem existente para extrair o nome da pasta
    for (var imageData in _images) {
      String? url = imageData['url'];
      if (url != null && url.startsWith('uploads/')) {
        // URL formato: uploads/reports/PASTA_NAME/image.jpg
        final parts = url.split('/');
        if (parts.length >= 3 && parts[0] == 'uploads' && parts[1] == 'reports') {
          print('📁 Usando pasta existente: ${parts[2]}');
          return parts[2]; // Nome da pasta
        }
      }
    }
    
    // Se não conseguiu extrair da imagem, usar o pathPdf se disponível
    if (widget.report.pathPdf.isNotEmpty && widget.report.pathPdf.startsWith('uploads/')) {
      final parts = widget.report.pathPdf.split('/');
      if (parts.length >= 3 && parts[0] == 'uploads' && parts[1] == 'reports') {
        print('📁 Usando pasta existente do PDF: ${parts[2]}');
        return parts[2]; // Nome da pasta
      }
    }
    
    // Para relatórios do servidor, tentar usar padrão baseado no prefixo + ID
    if (widget.report.id.isNotEmpty) {
      print('📁 Usando pasta baseada no prefixo + ID: ${widget.report.prefixo}-${widget.report.id}');
      return '${widget.report.prefixo}-${widget.report.id}';
    }
    
    // Fallback: gerar nova pasta (não deveria acontecer para relatórios existentes)
    print('⚠️ Não foi possível determinar pasta existente, criando nova');
    return ImageUploadService.generateFolderName(widget.report.prefixo);
  }

  // Converte data do formato ISO (yyyy-MM-dd) para formato brasileiro (dd/MM/yyyy)
  String _convertToBrazilianDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    
    try {
      // Se já estiver no formato brasileiro, retornar como está
      if (dateStr.contains('/') && dateStr.length == 10) {
        return dateStr;
      }
      
      // Se estiver no formato ISO, converter para brasileiro
      if (dateStr.contains('-')) {
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          final year = parts[0];
          final month = parts[1].padLeft(2, '0');
          final day = parts[2].padLeft(2, '0');
          return '$day/$month/$year';
        }
      }
      
      return dateStr; // Retornar original se não conseguir converter
    } catch (e) {
      print('Erro ao converter data: $dateStr - $e');
      return dateStr;
    }
  }

  Future<void> saveAsDraft() async {
    if (_isServerReport()) {
      // Relatório do servidor - usar API
      await _saveServerReportAsDraft();
    } else {
      // Relatório local - usar SharedPreferences
      await _saveLocalReportAsDraft();
    }
  }

  Future<void> _saveLocalReportAsDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final updatedReport = widget.report.copyWith(
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
      houveContaminacao: houveContaminacao ?? false,
      contaminacaoDescricao: contaminacaoDescricao,
      materialHomogeneo: materialHomogeneo ?? '',
      umidadeVisivel: umidadeVisivel ?? '',
      houveChuva: houveChuva ?? '',
      fornecedorAcompanhou: fornecedorAcompanhou ?? '',
      observacoes: observacoesController.text,
      imagens: _images.map<String>((img) => 
        img['file'] != null ? img['file'].path.toString() : (img['url'] ?? '')
      ).toList(),
      status: 0,
    );

    final existing = prefs.getStringList('full_reports') ?? [];
    final updated =
        existing.where((e) => !e.contains(widget.report.id)).toList();
    updated.add(jsonEncode(updatedReport.toJson()));
    await prefs.setStringList('full_reports', updated);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rascunho atualizado com sucesso!')),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _saveServerReportAsDraft() async {
    try {
      final updatedReport = widget.report.copyWith(
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
        houveContaminacao: houveContaminacao ?? false,
        contaminacaoDescricao: contaminacaoDescricao,
        materialHomogeneo: materialHomogeneo ?? '',
        umidadeVisivel: umidadeVisivel ?? '',
        houveChuva: houveChuva ?? '',
        fornecedorAcompanhou: fornecedorAcompanhou ?? '',
        observacoes: observacoesController.text,
        status: 0, // Rascunho
      );

      final dataController = Provider.of<DataController>(context, listen: false);
      
      // Separar imagens existentes (URLs) e novas (Files)
      List<File> newImageFiles = [];
      List<String> existingImagePaths = [];
      
      for (var img in _images) {
        if (img['file'] != null) {
          newImageFiles.add(img['file'] as File);
        } else if (img['url'] != null) {
          existingImagePaths.add(img['url']);
        }
      }

      await ReportApiService.updateReport(
        reportId: widget.report.id,
        report: updatedReport,
        dataController: dataController,
        newImageFiles: newImageFiles.isNotEmpty ? newImageFiles : null,
        existingImagePaths: existingImagePaths,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Relatório atualizado no servidor!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar no servidor: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> generateFinalReport() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => const CustomLoadingDialog(message: "Gerando relatório..."),
    );

    try {
      final updatedBase = widget.report.copyWith(
        prefixo: prefixoController.text,
        terminal: selectedTerminal ?? '',
        produto: selectedProduto ?? '',
        colaborador: colaborador ?? '',
        fornecedor: fornecedor ?? '',
        dataInicio: dataInicioController.text,
        horarioInicio: horarioInicioController.text,
        dataTermino: dataTerminoController.text,
        horarioTermino: horarioTerminoController.text,
        horarioChegada: horarioChegadaController.text,
        horarioSaida: horarioSaidaController.text,
        houveContaminacao: houveContaminacao ?? false,
        contaminacaoDescricao: contaminacaoDescricao,
        materialHomogeneo: materialHomogeneo ?? '',
        umidadeVisivel: umidadeVisivel ?? '',
        houveChuva: houveChuva ?? '',
        fornecedorAcompanhou: fornecedorAcompanhou ?? '',
        observacoes: observacoesController.text,
        imagens: _images.map<String>((img) => 
          img['file'] != null ? img['file'].path.toString() : (img['url'] ?? '')
        ).toList(),
        status: 1,
        dataCriacao: DateTime.now(),
      );

      final pdfPath = await generatePdf(
        prefixoController: prefixoController,
        selectedTerminal: selectedTerminal,
        selectedProduto: selectedProduto,
        selectedVagao: selectedVagao,
        colaborador: colaborador,
        fornecedor: fornecedor,
        selectedValue: selectedValue,
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

      // Salva o relatório final com o path atualizado
      final updatedFinal = updatedBase.copyWith(pathPdf: pdfPath);
      await saveOrUpdateReport(updatedFinal);

      if (mounted) {
        Navigator.of(context).pop(); // fecha loading
        Navigator.popUntil(
          context,
          (route) => route.isFirst,
        ); // volta para a home
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // fecha loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erro ao gerar relatório: $e")));
      }
    }
  }

  /// Envia relatório para o servidor (com conexão)
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
      await saveAsDraft();
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CustomLoadingDialog(message: "Enviando relatório..."),
    );

    try {
      // Separar imagens existentes (URLs) e novas (Files) 
      final existingImageUrls = <String>[];
      final newImageFiles = <File>[];
      
      for (var imageData in _images) {
        if (imageData['file'] != null) {
          final file = imageData['file'] as File;
          if (await file.exists()) {
            newImageFiles.add(file);
          }
        } else if (imageData['url'] != null) {
          String url = imageData['url'];
          // Converter URL completa para caminho relativo se necessário
          if (url.startsWith('$API_BASE_URL/')) {
            url = url.replaceFirst('$API_BASE_URL/', '');
          }
          existingImageUrls.add(url);
        }
      }

      // Gerar PDF com imagens combinadas (existentes + novas)
      final updatedReport = widget.report.copyWith(
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
        houveContaminacao: houveContaminacao ?? false,
        contaminacaoDescricao: contaminacaoDescricao,
        materialHomogeneo: materialHomogeneo ?? '',
        umidadeVisivel: umidadeVisivel ?? '',
        houveChuva: houveChuva ?? '',
        fornecedorAcompanhou: fornecedorAcompanhou ?? '',
        observacoes: observacoesController.text,
        status: 1, // Status finalizado
        dataCriacao: DateTime.now(),
      );

      final dataController = context.read<DataController>();

      // Se é relatório do servidor, usar updateReport para manter pasta existente
      if (_isServerReport()) {
        // Determinar nome da pasta existente a partir do ID ou prefixo
        final existingFolderName = _getExistingFolderName();
        
        final result = await ReportApiService.updateReport(
          reportId: widget.report.id,
          report: updatedReport,
          dataController: dataController,
          newImageFiles: newImageFiles.isNotEmpty ? newImageFiles : null,
          existingImagePaths: existingImageUrls,
          existingFolderName: existingFolderName,
        );

        if (mounted) {
          Navigator.of(context).pop(); // fecha loading

          if (result['success'] == true) {
            // Mostrar mensagem de sucesso
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Relatório atualizado com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );

            // Abrir PDF usando a URL do servidor
            final pdfUrl = result['data']['pdf_url'];
            if (pdfUrl != null && pdfUrl.isNotEmpty) {
              await _openServerPdf(pdfUrl);
            }

            // Voltar para home
            Navigator.popUntil(context, (route) => route.isFirst);
          } else {
            // Erro: mostrar mensagem
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Erro ao atualizar relatório: ${result['message']}"),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // Para relatórios locais, usar o método original
        final result = await ReportApiService.submitReport(
          report: updatedReport,
          dataController: dataController,
          imageFiles: newImageFiles,
        );

        if (mounted) {
          Navigator.of(context).pop(); // fecha loading

          if (result['success'] == true) {
            // Sucesso - remover do armazenamento local e mostrar mensagem
            final prefs = await SharedPreferences.getInstance();
            final existing = prefs.getStringList('full_reports') ?? [];
            final updated = existing.where((e) => !e.contains(widget.report.id)).toList();
            await prefs.setStringList('full_reports', updated);

            // Mostrar mensagem de sucesso
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

            // Voltar para home
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
      // Construir URL completa se necessário
      String fullUrl;
      if (pdfUrl.startsWith('http')) {
        fullUrl = pdfUrl;
      } else {
        fullUrl = '$API_BASE_URL/$pdfUrl';
      }
      
      print('📱 Abrindo PDF do servidor: $fullUrl');
      
      final uri = Uri.parse(fullUrl);
      if (await canLaunchUrl(uri)) {
        bool success = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        
        if (!success) {
          success = await launchUrl(
            uri,
            mode: LaunchMode.inAppWebView,
          );
        }
        
        if (!success) {
          success = await launchUrl(uri);
        }
        
        print('✅ PDF aberto com sucesso: $success');
      } else {
        print('❌ Não foi possível abrir o URL');
      }
      
    } catch (e) {
      print('Erro ao abrir PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao abrir PDF: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(prefixoController.text),
        actions: [
          // Só mostra botão de rascunho se for relatório local ou rascunho
          if (!_isServerReport())
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Salvar Rascunho',
              onPressed: saveAsDraft,
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
                  selectedProduto: selectedProduto,
                  onProdutoChanged:
                      (val) => setState(() => selectedProduto = val),
                  fornecedor: fornecedor,
                  onFornecedorChanged:
                      (val) => setState(() => fornecedor = val),
                  selectedCliente: selectedCliente,
                  onClienteChanged:
                      (val) => setState(() => selectedCliente = val),
                  isEditMode: true,
                ),
                const SizedBox(height: 16),
                DadosLocomotivaCard(
                  horarioChegadaController: horarioChegadaController,
                  horarioSaidaController: horarioSaidaController,
                  selectedVagao: selectedVagao,
                  onVagaoChanged: (val) => setState(() => selectedVagao = val),
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
                  // Com conexão
                  if (_isServerReport()) ...[
                    // Relatório do servidor - apenas atualizar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.update),
                        label: const Text('Atualizar Relatório'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: submitToServer,
                      ),
                    ),
                  ] else ...[
                    // Relatório local - enviar e salvar rascunho
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.send),
                            label: const Text('Enviar ao Servidor'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: submitToServer,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.save),
                            label: const Text('Salvar Rascunho'),
                            onPressed: saveAsDraft,
                          ),
                        ),
                      ],
                    ),
                  ],
                ] else ...[
                  // Sem conexão
                  if (_isServerReport()) ...[
                    // Relatório do servidor sem conexão - não é possível editar
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.wifi_off, color: Colors.red.shade700, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            'Sem conexão',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Não é possível editar relatórios do servidor sem conexão à internet',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Relatório local sem conexão - apenas rascunho
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
                          Text(
                            'Sem conexão - Apenas rascunho disponível',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
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
                        label: const Text('Salvar Rascunho'),
                        onPressed: saveAsDraft,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
