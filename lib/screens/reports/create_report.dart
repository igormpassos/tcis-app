import 'package:flutter/material.dart';
import 'package:tcis_app/constants.dart';
import 'package:tcis_app/utils/rive_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:tcis_app/controllers/report/report_pdf.dart';
import 'package:exif/exif.dart';
import 'package:tcis_app/components/custom_loading_dialog.dart';
import 'package:uuid/uuid.dart';
import 'package:tcis_app/model/full_report_model.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ReportEntryScreen extends StatefulWidget {
  const ReportEntryScreen({super.key});

  @override
  State<ReportEntryScreen> createState() => _ReportEntryScreenState();
}

class _ReportEntryScreenState extends State<ReportEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<Map<String, dynamic>> _images =
      []; // Lista para armazenar as imagens e metadados

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
                  onTap: () => _removeImage(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(4),
                    child:
                        const Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'Registrado em: ${image['timestamp'].day}/${image['timestamp'].month}/${image['timestamp'].year} ${image['timestamp'].hour}:${image['timestamp'].minute}',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  // Controllers and variables to store form data
  final TextEditingController prefixoController = TextEditingController();
  String? selectedTerminal;
  String? selectedProduto;
  String? selectedVagao;
  String? colaborador;
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

  void onSubmitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Mostrar loading usando componente
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            const CustomLoadingDialog(message: "Gerando relatório..."),
      );

      try {
        await generatePdf(
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
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao gerar relatório: $e")),
        );
      } finally {
        Navigator.of(context).pop(); // Fecha o loading
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
      pathPdf: '', // ainda não foi gerado
      dataCriacao: DateTime.now(),
      status: 0, // Rascunho
    );

    final savedReports = prefs.getStringList('full_reports') ?? [];
    savedReports.add(jsonEncode(reportData.toJson()));
    await prefs.setStringList('full_reports', savedReports);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Rascunho salvo com sucesso.')),
    );

    Navigator.popUntil(context, (route) => route.isFirst);
  }
  
  // Function to select date with formatted output
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
              primary: colorPrimary, // header background color
              onSurface: Colors.black, // body text color
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      setState(() {
        controller.text = formatDate(
            pickedDate); // Usando a função formatDate para formatar a data
      });
    }
  }

  // Function to select time with formatted output
  Future<void> _selectTime(TextEditingController controller) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.inputOnly,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: colorPrimary, // header background color
              onSurface: Colors.black, // body text color
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

  // Reset form fields
  void _resetForm() {
    prefixoController.clear();
    selectedTerminal = null;
    selectedProduto = null;
    selectedVagao = null;
    colaborador = null;
    dataInicioController.clear();
    horarioChegadaController.clear();
    horarioInicioController.clear();
    horarioTerminoController.clear();
    horarioSaidaController.clear();
    dataTerminoController.clear();
    houveContaminacao = null;
    contaminacaoDescricao = '';
    materialHomogeneo = null;
    umidadeVisivel = null;
    houveChuva = null;
    materialHomogeneo = null;
    umidadeVisivel = null;
    houveChuva = null;
    fornecedorAcompanhou = null;
    observacoesController.clear();
    _formKey.currentState?.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Relatório'),
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

                        ElevatedButton(
                          // onPressed: () {
                          //   if (_formKey.currentState?.validate() ?? false) {
                          //     // Mostrar mensagem de confirmação
                          //     ScaffoldMessenger.of(context).showSnackBar(
                          //       const SnackBar(
                          //           content:
                          //               Text('Relatório enviado com sucesso!')),
                          //     );
                          //     onSubmitForm();
                          //     //_resetForm(); // Limpar campos após envio
                          //   }
                          // },
                          onPressed: onSubmitForm,
                          child: const Text('Gerar Relatório'),
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
