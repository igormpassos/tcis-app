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
  

  const DadosRelatorioCard({
    super.key,
    required this.prefixoController,
    required this.selectedTerminal,
    required this.onTerminalChanged,
    required this.colaborador,
    required this.onColaboradorChanged,
    required this.selectedProduto,
    required this.onProdutoChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dados do Relatório',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text('Prefixo *'),
            TextFormField(
              controller: prefixoController,
              decoration: const InputDecoration(hintText: 'ABC-1234'),
              textCapitalization: TextCapitalization.characters,
              validator: (value) =>
                  value == null || value.isEmpty ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 16),
            const Text('Terminal *'),
            DropdownButtonFormField<String>(
              dropdownColor: backgroundColorLight.withAlpha(230),
              borderRadius: BorderRadius.circular(15),
              style: TextStyle(fontSize: 15, color: TextDarkColor),
              hint: Text("Selecione uma opção", style: TextStyle(color: LabelColor)),
              value: selectedTerminal,
              onChanged: onTerminalChanged,
              items: [
                'TSA - Terminal Serra Azul',
                'SZD - Sarzedo Velho (Itaminas)',
                'TCS - Terminal Sarzedo Novo',
                'TCM - Terminal Multitudo',
                'TCI - Terminal de Itutinga',
                'Outro',
              ].map((terminal) {
                return DropdownMenuItem(value: terminal, child: Text(terminal));
              }).toList(),
              validator: (value) => value == null ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 16),
            const Text('Colaborador'),
            DropdownButtonFormField<String>(
              dropdownColor: backgroundColorLight.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
              style: TextStyle(fontSize: 15, color: TextDarkColor),
              hint: Text("Selecione uma opção", style: TextStyle(color: LabelColor)),
              value: colaborador,
              onChanged: onColaboradorChanged,
              items: [
                'Colaborador 1',
                'Colaborador 2',
                'Colaborador 3',
              ].map((colab) {
                return DropdownMenuItem(value: colab, child: Text(colab));
              }).toList(),
              validator: (value) => value == null ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 16),
            const Text('Produto *'),
            DropdownButtonFormField<String>(
              dropdownColor: backgroundColorLight.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
              style: TextStyle(fontSize: 15, color: TextDarkColor),
              hint: Text("Selecione uma opção", style: TextStyle(color: LabelColor)),
              value: selectedProduto,
              onChanged: onProdutoChanged,
              items: [
                'Produto 1',
                'Produto 2',
                'Produto 3',
              ].map((produto) {
                return DropdownMenuItem(value: produto, child: Text(produto));
              }).toList(),
              validator: (value) => value == null ? 'Campo obrigatório' : null,
            ),
          ],
        ),
      ),
    );
  }
}
