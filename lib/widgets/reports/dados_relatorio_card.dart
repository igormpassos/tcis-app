import 'package:flutter/material.dart';
import 'package:tcis_app/constants.dart';

class DadosRelatorioCard extends StatelessWidget {
  final TextEditingController prefixoController;
  final String? selectedTerminal;
  final ValueChanged<String?> onTerminalChanged;
  final String? colaborador;
  final ValueChanged<String?> onColaboradorChanged;
  final String? selectedProduto;
  final ValueChanged<String?> onProdutoChanged;
  final String? fornecedor;
  final ValueChanged<String?> onFornecedorChanged;

  const DadosRelatorioCard({
    super.key,
    required this.prefixoController,
    required this.selectedTerminal,
    required this.onTerminalChanged,
    required this.colaborador,
    required this.onColaboradorChanged,
    required this.selectedProduto,
    required this.onProdutoChanged,
    required this.fornecedor,
    required this.onFornecedorChanged,
  });

  @override
  Widget build(BuildContext context) {
    final terminais = [
      'TSA - Terminal Serra Azul',
      'SZD - Sarzedo Velho (Itaminas)',
      'TCS - Terminal Sarzedo Novo',
      'TCM - Terminal Multitudo',
      'TCI - Terminal de Itutinga',
      'Outro',
    ];

    final colaboradores = [
      'Lucas Euzébio',
      'Luan Pereira',
      'Gabriel Gonzaga',
      'Willian',
      'Rogério Gonçalves',
      'Moizes Ferreira',
      'Paulo Rezende',
      'João Paulo Lacerda',
      'Alexandre Neuton',
      'Warlley Lopes',
    ];

    final produtos = [
      'FFVG (AVG)',
      'FLVG (AVG)',
      'FSEC (EKO)',
      'FSE2 (EKO)',
      'GRANULADO (EKO)',
      'GRANULADO (LHG)',
      'FMFM (FERRO+)',
      'FFJM (J.MENDES)',
      'FFJM/FMFM (J.MENDES)',
      'FHJM/FMFM (J MENDES)',
      'F1MH (HERCULANO)',
      'FSIT (ITAMINAS)',
      'FFSL (SERRA LESTE)',
      'FSML (SERRA DO LOPES)',
      'GRANULADO (VETRIA)',
      'GRANULADO (4B)',
      'GRANULADO (3A)',
      'GRANULADO (LHG)',
      'GRANULADO/SINTER (LHG)',
      'FMBE (BEMISA)',
      'FNMT (MINERITA)',
      'Outro',
    ];

    final fornecedores = [
      'ECKOMINING',
      'ITAMINAS',
      'HERCULANO',
      'SERRA LESTE',
      'JMENDES',
      'LHG',
      'SERRA LOPES',
      'AVG',
      'BEMISA',
      '4B',
      'VETRIA',
      '3A',
      'Outro',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dados do Relatório', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),

            const Text('Prefixo *'),
            TextFormField(
              controller: prefixoController,
              decoration: const InputDecoration(hintText: 'ABC-1234'),
              textCapitalization: TextCapitalization.characters,
              validator: (value) => value == null || value.isEmpty ? 'Campo obrigatório' : null,
            ),

            const SizedBox(height: 16),
            const Text('Terminal *'),
            DropdownButtonFormField<String>(
              value: terminais.contains(selectedTerminal) ? selectedTerminal : null,
              hint: Text("Selecione uma opção", style: TextStyle(color: LabelColor)),
              style: TextStyle(fontSize: 15, color: TextDarkColor),
              borderRadius: BorderRadius.circular(15),
              dropdownColor: backgroundColorLight.withAlpha(230),
              onChanged: (value) {
                if (value == 'Outro') {
                  showDialog(
                    context: context,
                    builder: (_) {
                      String custom = '';
                      return AlertDialog(
                        title: Text('Qual o Terminal?'),
                        content: TextField(
                          autofocus: true,
                          onChanged: (val) => custom = val,
                          decoration: InputDecoration(hintText: 'SIGLA - NOME'),
                          textCapitalization: TextCapitalization.characters,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              onTerminalChanged(custom);
                              Navigator.pop(context);
                            },
                            child: Text('Confirmar'),
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  onTerminalChanged(value);
                }
              },
              items: terminais.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              validator: (value) => (selectedTerminal?.isEmpty ?? true) ? 'Campo obrigatório' : null,
            ),

            const SizedBox(height: 16),
            const Text('Colaborador'),
            DropdownButtonFormField<String>(
              value: colaborador,
              hint: Text("Selecione uma opção", style: TextStyle(color: LabelColor)),
              style: TextStyle(fontSize: 15, color: TextDarkColor),
              borderRadius: BorderRadius.circular(16),
              dropdownColor: backgroundColorLight.withOpacity(0.9),
              onChanged: onColaboradorChanged,
              items: colaboradores.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              validator: (value) => value == null ? 'Campo obrigatório' : null,
            ),

            const SizedBox(height: 16),
            const Text('Produto *'),
            DropdownButtonFormField<String>(
              value: produtos.contains(selectedProduto) ? selectedProduto : null,
              hint: Text("Selecione uma opção", style: TextStyle(color: LabelColor)),
              style: TextStyle(fontSize: 15, color: TextDarkColor),
              borderRadius: BorderRadius.circular(16),
              dropdownColor: backgroundColorLight.withOpacity(0.9),
              onChanged: (value) {
                if (value == 'Outro') {
                  showDialog(
                    context: context,
                    builder: (_) {
                      String custom = '';
                      return AlertDialog(
                        title: Text('Qual o Produto?'),
                        content: TextField(
                          autofocus: true,
                          onChanged: (val) => custom = val,
                          decoration: InputDecoration(hintText: 'Produto'),
                          textCapitalization: TextCapitalization.characters,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              onProdutoChanged(custom);
                              Navigator.pop(context);
                            },
                            child: Text('Confirmar'),
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  onProdutoChanged(value);
                }
              },
              items: produtos.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              validator: (value) => (selectedProduto?.isEmpty ?? true) ? 'Campo obrigatório' : null,
            ),

            const SizedBox(height: 16),
            const Text('Fornecedor *'),
            DropdownButtonFormField<String>(
              value: fornecedores.contains(fornecedor) ? fornecedor : null,
              hint: Text("Selecione uma opção", style: TextStyle(color: LabelColor)),
              style: TextStyle(fontSize: 15, color: TextDarkColor),
              borderRadius: BorderRadius.circular(16),
              dropdownColor: backgroundColorLight.withOpacity(0.9),
              onChanged: (value) {
                if (value == 'Outro') {
                  showDialog(
                    context: context,
                    builder: (_) {
                      String custom = '';
                      return AlertDialog(
                        title: Text('Qual o Fornecedor?'),
                        content: TextField(
                          autofocus: true,
                          onChanged: (val) => custom = val,
                          decoration: InputDecoration(hintText: 'Fornecedor'),
                          textCapitalization: TextCapitalization.characters,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              onFornecedorChanged(custom);
                              Navigator.pop(context);
                            },
                            child: Text('Confirmar'),
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  onFornecedorChanged(value);
                }
              },
              items: fornecedores.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              validator: (value) => (fornecedor?.isEmpty ?? true) ? 'Campo obrigatório' : null,
            ),
          ],
        ),
      ),
    );
  }
}