import 'package:flutter/material.dart';
import 'package:tcis_app/constants.dart';

class DadosLocomotivaCard extends StatelessWidget {
  final TextEditingController horarioChegadaController;
  final TextEditingController horarioSaidaController;
  final String? selectedVagao;
  final ValueChanged<String?> onVagaoChanged;
  final Future<void> Function(TextEditingController controller) onSelectTime;

  const DadosLocomotivaCard({
    super.key,
    required this.horarioChegadaController,
    required this.horarioSaidaController,
    required this.selectedVagao,
    required this.onVagaoChanged,
    required this.onSelectTime,
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
              'Dados da Locomotiva',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                        onTap: () => onSelectTime(horarioChegadaController),
                        validator: (value) =>
                            value == null || value.isEmpty
                                ? 'Campo obrigatório'
                                : null,
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
                        onTap: () => onSelectTime(horarioSaidaController),
                        validator: (value) =>
                            value == null || value.isEmpty
                                ? 'Campo obrigatório'
                                : null,
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
              hint: Text("Selecione uma opção", style: TextStyle(color: LabelColor)),
              value: selectedVagao,
              onChanged: onVagaoChanged,
              items: [
                'Vagão 1',
                'Vagão 2',
                'Vagão 3',
                'Vagão 4',
              ].map((vagao) {
                return DropdownMenuItem(value: vagao, child: Text(vagao));
              }).toList(),
              validator: (value) =>
                  value == null ? 'Campo obrigatório' : null,
            ),
          ],
        ),
      ),
    );
  }
}
