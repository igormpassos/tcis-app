import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tcis_app/components/custom_loading_dialog.dart';
import 'package:tcis_app/constants.dart';
import 'package:tcis_app/controllers/report/report_pdf.dart';
import 'package:tcis_app/model/full_report_model.dart';
import 'package:tcis_app/utils/utils.dart';
import 'package:exif/exif.dart';
import 'package:tcis_app/controllers/report/report_mananger.dart';

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
  String? selectedValue;
  bool? houveContaminacao;
  String contaminacaoDescricao = '';
  String? materialHomogeneo;
  String? umidadeVisivel;
  String? houveChuva;
  String? fornecedorAcompanhou;

  void limparDropdownsVazios() {
    if (selectedTerminal?.isEmpty ?? false) selectedTerminal = null;
    if (selectedProduto?.isEmpty ?? false) selectedProduto = null;
    if (selectedValue?.isEmpty ?? false) selectedValue = null;
    if (selectedVagao?.isEmpty ?? false) selectedVagao = null;
    if (colaborador?.isEmpty ?? false) colaborador = null;
  }

  @override
  void initState() {
    super.initState();
    final r = widget.report;
    prefixoController.text = r.prefixo;
    selectedTerminal = r.terminal;
    selectedProduto = r.produto;
    colaborador = r.colaborador;
    selectedValue = r.tipoVagao;
    dataInicioController.text = r.dataInicio;
    horarioInicioController.text = r.horarioInicio;
    dataTerminoController.text = r.dataTermino;
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

    for (var path in r.imagens) {
      final file = File(path);
      if (file.existsSync()) {
        _images.add({
          'file': file,
          'timestamp': file.lastModifiedSync(),
        });
      }
    }
  }

  Future<void> saveAsDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final updatedReport = widget.report.copyWith(
      prefixo: prefixoController.text,
      terminal: selectedTerminal ?? '',
      produto: selectedProduto ?? '',
      colaborador: colaborador ?? '',
      tipoVagao: selectedValue ?? '',
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
      imagens: _images.map((img) => img['file'].path.toString()).toList(),
      status: 0,
    );

    final existing = prefs.getStringList('full_reports') ?? [];
    final updated =
        existing.where((e) => !e.contains(widget.report.id)).toList();
    updated.add(jsonEncode(updatedReport.toJson()));
    await prefs.setStringList('full_reports', updated);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rascunho atualizado com sucesso!')),
    );
    Navigator.pop(context);
  }

  Future<void> generateFinalReport() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const CustomLoadingDialog(message: "Gerando relatório..."),
    );

    try {
      final updatedBase = widget.report.copyWith(
        prefixo: prefixoController.text,
        terminal: selectedTerminal ?? '',
        produto: selectedProduto ?? '',
        colaborador: colaborador ?? '',
        tipoVagao: selectedValue ?? '',
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
        imagens: _images.map((img) => img['file'].path.toString()).toList(),
        status: 1,
        dataCriacao: DateTime.now(),
      );

      final pdfPath = await generatePdf(
        prefixoController: prefixoController,
        selectedTerminal: selectedTerminal,
        selectedProduto: selectedProduto,
        selectedVagao: selectedVagao,
        colaborador: colaborador,
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
            context, (route) => route.isFirst); // volta para a home
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // fecha loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao gerar relatório: $e")),
        );
      }
    }
  }

  // Seletor de data
  Future<void> _selectDate(TextEditingController controller) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: colorPrimary,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      setState(() {
        controller.text = formatDate(pickedDate);
      });
    }
  }

// Seletor de horário
  Future<void> _selectTime(TextEditingController controller) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.inputOnly,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: colorPrimary,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedTime != null) {
      controller.text =
          '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
    }
  }

// Chips reutilizáveis
  Widget buildChoiceChips(String label, List<String> options,
      String? selectedOption, Function(String) onSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Wrap(
          spacing: 2.0,
          runSpacing: 0.0,
          children: options.map((option) {
            return ChoiceChip(
              label: Text(option),
              selected: selectedOption == option,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    onSelected(option);
                  });
                }
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<DateTime?> getImageCreationDate(File file) async {
    final bytes = await file.readAsBytes();
    final tags = await readExifFromBytes(bytes);

    if (tags.containsKey('Image DateTime')) {
      final dateTimeString = tags['Image DateTime']!.printable;
      // O formato padrão do EXIF é "YYYY:MM:DD HH:MM:SS"
      final parts = dateTimeString.split(' ');
      if (parts.length == 2) {
        final date = parts[0].replaceAll(':', '-');
        final time = parts[1];
        return DateTime.tryParse('$date $time');
      }
    }
    return null; // Não encontrou a data
  }

  // Função para selecionar várias imagens da galeria
  Future<void> _addImage() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      List<Map<String, dynamic>> newImages = [];

      for (var pickedFile in pickedFiles) {
        final file = File(pickedFile.path);
        final creationDate = await getImageCreationDate(file) ??
            DateTime.now(); // Se não achar no EXIF, usa a data atual
        newImages.add({
          'file': file,
          'timestamp': creationDate,
        });
      }

      setState(() {
        _images.addAll(newImages);
      });
    }
  }

  // Função para remover uma imagem
  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

// Galeria de imagens
  Widget _buildImageGrid() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        // Botão para adicionar imagem
        GestureDetector(
          onTap: _addImage,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey),
            ),
            child: const Icon(Icons.add_a_photo, color: Colors.grey, size: 30),
          ),
        ),
        // Exibir imagens adicionadas com data e hora

        ..._images.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, dynamic> image = entry.value;
          return Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(
                    image: FileImage(image['file']),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => setState(() => _images.removeAt(index)),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(4),
                    child:
                        const Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(prefixoController.text),
        actions: [
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
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dados do Relatório',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        const Text('Prefixo *'),
                        TextFormField(
                          controller: prefixoController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Campo obrigatório';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text('Terminal *'),
                        DropdownButtonFormField<String>(
                          dropdownColor: backgroundColorLight
                              .withAlpha((0.9 * 255).toInt()),
                          borderRadius: BorderRadius.circular(15),
                          style: TextStyle(fontSize: 15, color: TextDarkColor),
                          hint: Text("Selecione uma opção",
                              style: TextStyle(color: LabelColor)),
                          value: selectedTerminal,
                          onChanged: (value) =>
                              setState(() => selectedTerminal = value),
                          items: [
                            'TSA - Terminal Serra Azul',
                            'SZD - Sarzedo Velho (Itaminas)',
                            'TCS - Terminal Sarzedo Novo',
                            'TCM - Terminal Multitudo',
                            'TCI - Terminal de Itutinga',
                            'Outro',
                          ].map((terminal) {
                            return DropdownMenuItem(
                              value: terminal,
                              child: Text(terminal),
                            );
                          }).toList(),
                          validator: (value) =>
                              value == null ? 'Campo obrigatório' : null,
                        ),
                        const SizedBox(height: 16),
                        const Text('Colaborador'),
                        DropdownButtonFormField<String>(
                          dropdownColor: backgroundColorLight.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                          style: TextStyle(fontSize: 15, color: TextDarkColor),
                          hint: Text("Selecione uma opção",
                              style: TextStyle(color: LabelColor)),
                          value: colaborador,
                          onChanged: (value) =>
                              setState(() => colaborador = value),
                          items: [
                            'Colaborador 1',
                            'Colaborador 2',
                            'Colaborador 3'
                          ].map((colab) {
                            return DropdownMenuItem(
                              value: colab,
                              child: Text(colab),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        const Text('Produto *'),
                        DropdownButtonFormField<String>(
                          dropdownColor: backgroundColorLight.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                          style: TextStyle(fontSize: 15, color: TextDarkColor),
                          hint: Text("Selecione uma opção",
                              style: TextStyle(color: LabelColor)),
                          value: selectedProduto,
                          onChanged: (value) =>
                              setState(() => selectedProduto = value),
                          items: ['Produto 1', 'Produto 2', 'Produto 3']
                              .map((produto) {
                            return DropdownMenuItem(
                              value: produto,
                              child: Text(produto),
                            );
                          }).toList(),
                          validator: (value) =>
                              value == null ? 'Campo obrigatório' : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Dados da Locomotiva
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dados da Locomotiva',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Horário Chegada'),
                                  TextFormField(
                                    controller: horarioChegadaController,
                                    decoration: const InputDecoration(
                                      suffixIcon: Icon(Icons.train),
                                    ),
                                    readOnly: true,
                                    onTap: () =>
                                        _selectTime(horarioChegadaController),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Horário Saída'),
                                  TextFormField(
                                    controller: horarioSaidaController,
                                    decoration: const InputDecoration(
                                      suffixIcon: Icon(Icons.train),
                                    ),
                                    readOnly: true,
                                    onTap: () =>
                                        _selectTime(horarioSaidaController),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text('Tipo de Vagão'),
                        DropdownButtonFormField<String>(
                          dropdownColor: backgroundColorLight.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                          style: TextStyle(fontSize: 15, color: TextDarkColor),
                          hint: Text("Selecione uma opção",
                              style: TextStyle(color: LabelColor)),
                          value: selectedVagao,
                          onChanged: (value) =>
                              setState(() => selectedVagao = value),
                          items: ['Vagão 1', 'Vagão 2', 'Vagão 3', 'Vagão 4']
                              .map((vagao) {
                            return DropdownMenuItem(
                              value: vagao,
                              child: Text(vagao),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dados do Carregamento',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Data Início *'),
                                  TextFormField(
                                    controller: dataInicioController,
                                    decoration: InputDecoration(
                                      suffixIcon: Icon(Icons.calendar_today),
                                    ),
                                    readOnly: true,
                                    onTap: () =>
                                        _selectDate(dataInicioController),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Campo obrigatório';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Horário de Início'),
                                  TextFormField(
                                    controller: horarioInicioController,
                                    decoration: const InputDecoration(
                                      suffixIcon: Icon(Icons.access_time),
                                    ),
                                    readOnly: true,
                                    onTap: () =>
                                        _selectTime(horarioInicioController),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Data Término *'),
                                  TextFormField(
                                    controller: dataTerminoController,
                                    decoration: const InputDecoration(
                                      suffixIcon: Icon(Icons.calendar_today),
                                    ),
                                    readOnly: true,
                                    onTap: () =>
                                        _selectDate(dataTerminoController),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Campo obrigatório';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Horário de Término'),
                                  TextFormField(
                                    controller: horarioTerminoController,
                                    decoration: const InputDecoration(
                                      suffixIcon: Icon(Icons.access_time),
                                    ),
                                    readOnly: true,
                                    onTap: () =>
                                        _selectTime(horarioTerminoController),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text('Houve registro de contaminação? *'),
                        Row(
                          children: [
                            ChoiceChip(
                              label: const Text('Sim'),
                              selected: houveContaminacao == true,
                              onSelected: (selected) =>
                                  setState(() => houveContaminacao = true),
                            ),
                            const SizedBox(width: 5),
                            ChoiceChip(
                              label: const Text('Não'),
                              selected: houveContaminacao == false,
                              onSelected: (selected) =>
                                  setState(() => houveContaminacao = false),
                            ),
                          ],
                        ),
                        if (houveContaminacao == true)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                  'Descreva o contaminante, onde foi encontrado e se foi retirado *'),
                              TextFormField(
                                controller: TextEditingController(
                                    text: contaminacaoDescricao),
                                maxLines: 3,
                                validator: (value) {
                                  if (houveContaminacao == true &&
                                      (value == null || value.isEmpty)) {
                                    return 'Campo obrigatório';
                                  }
                                  return null;
                                },
                                onChanged: (value) =>
                                    contaminacaoDescricao = value,
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        // Material homogêneo
                        buildChoiceChips(
                          'Material homogêneo (mesmo material, mesma cor, mesmo tipo)?',
                          [
                            'Sim',
                            'Não',
                            'Não, mas carregado em vagões separados'
                          ],
                          materialHomogeneo,
                          (value) => materialHomogeneo = value,
                        ),

                        // Umidade visível
                        buildChoiceChips(
                          'Umidade visível?',
                          ['Sim', 'Não'],
                          umidadeVisivel,
                          (value) => umidadeVisivel = value,
                        ),

                        // Houve chuva durante a carga?
                        buildChoiceChips(
                          'Houve chuva durante a carga?',
                          ['Sim', 'Não', 'Somente em partes da carga'],
                          houveChuva,
                          (value) => houveChuva = value,
                        ),

                        // Fornecedor acompanhou a carga e a preparação das amostras?
                        buildChoiceChips(
                          'Fornecedor acompanhou a carga e a preparação das amostras?',
                          [
                            'Sim',
                            'Não',
                            'Somente parte da carga',
                            'Somente a carga',
                            'Somente a preparação das amostras'
                          ],
                          fornecedorAcompanhou,
                          (value) => fornecedorAcompanhou = value,
                        ),

                        const Text('Observações'),
                        TextFormField(
                          controller: observacoesController,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),

                        const SizedBox(height: 16),
                        const Text(
                          'Imagens',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        _buildImageGrid(),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.picture_as_pdf),
                              label: const Text('Gerar PDF e Criar relatório'),
                              onPressed: () async {
                                if (_formKey.currentState?.validate() ??
                                    false) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Relatório enviado com sucesso!')),
                                  );
                                  await generateFinalReport();
                                  (); // Agora funciona
                                  //_resetForm();
                                  Navigator.popUntil(
                                      context, (route) => route.isFirst);
                                }
                              },
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.save),
                              label: const Text('Salvar em Rascunho'),
                              onPressed: saveAsDraft,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
