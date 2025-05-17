import 'package:flutter/material.dart';
import 'package:tcis_app/components/choiseChipGroup.dart';
import 'package:tcis_app/components/imageSelectorGrid.dart';

class DadosCarregamentoCard extends StatelessWidget {
  final TextEditingController dataInicioController;
  final TextEditingController horarioInicioController;
  final TextEditingController dataTerminoController;
  final TextEditingController horarioTerminoController;

  final bool? houveContaminacao;
  final ValueChanged<bool> onContaminacaoChanged;
  final String contaminacaoDescricao;
  final ValueChanged<String> onDescricaoChanged;

  final String? materialHomogeneo;
  final ValueChanged<String> onMaterialChanged;

  final String? umidadeVisivel;
  final ValueChanged<String> onUmidadeChanged;

  final String? houveChuva;
  final ValueChanged<String> onChuvaChanged;

  final String? fornecedorAcompanhou;
  final ValueChanged<String> onFornecedorChanged;

  final TextEditingController observacoesController;

  final List<Map<String, dynamic>> images;
  final VoidCallback onAddImage;
  final Function(int) onRemoveImage;

  final Future<void> Function(TextEditingController) onSelectDate;
  final Future<void> Function(TextEditingController) onSelectTime;

  const DadosCarregamentoCard({
    super.key,
    required this.dataInicioController,
    required this.horarioInicioController,
    required this.dataTerminoController,
    required this.horarioTerminoController,
    required this.houveContaminacao,
    required this.onContaminacaoChanged,
    required this.contaminacaoDescricao,
    required this.onDescricaoChanged,
    required this.materialHomogeneo,
    required this.onMaterialChanged,
    required this.umidadeVisivel,
    required this.onUmidadeChanged,
    required this.houveChuva,
    required this.onChuvaChanged,
    required this.fornecedorAcompanhou,
    required this.onFornecedorChanged,
    required this.observacoesController,
    required this.images,
    required this.onAddImage,
    required this.onRemoveImage,
    required this.onSelectDate,
    required this.onSelectTime,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Dados do Carregamento',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),

          _buildDataHoraRow(
            'Data Início *',
            dataInicioController,
            Icons.calendar_today,
            onSelectDate,
            'Horário de Início',
            horarioInicioController,
            Icons.access_time,
            onSelectTime,
          ),

          const SizedBox(height: 16),

          _buildDataHoraRow(
            'Data Término *',
            dataTerminoController,
            Icons.calendar_today,
            onSelectDate,
            'Horário de Término',
            horarioTerminoController,
            Icons.access_time,
            onSelectTime,
          ),

          const SizedBox(height: 16),

          const Text('Houve registro de contaminação? *'),
          Row(
            children: [
              ChoiceChip(
                label: const Text('Sim'),
                selected: houveContaminacao == true,
                onSelected: (_) => onContaminacaoChanged(true),
              ),
              const SizedBox(width: 5),
              ChoiceChip(
                label: const Text('Não'),
                selected: houveContaminacao == false,
                onSelected: (_) => onContaminacaoChanged(false),
              ),
            ],
          ),

          if (houveContaminacao == true)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Descreva o contaminante, onde foi encontrado e se foi retirado *',
                ),
                TextFormField(
                  initialValue: contaminacaoDescricao,
                  maxLines: 3,
                  onChanged: onDescricaoChanged,
                  validator: (value) {
                    if ((houveContaminacao ?? false) &&
                        (value == null || value.isEmpty)) {
                      return 'Campo obrigatório';
                    }
                    return null;
                  },
                ),
              ],
            ),

          const SizedBox(height: 16),

          ChoiceChipGroup(
            label:
                'Material homogêneo (mesmo material, mesma cor, mesmo tipo)?',
            options: ['Sim', 'Não', 'Não, mas carregado em vagões separados'],
            selectedOption: materialHomogeneo,
            onSelected: onMaterialChanged,
          ),
          ChoiceChipGroup(
            label: 'Umidade visível?',
            options: ['Sim', 'Não'],
            selectedOption: umidadeVisivel,
            onSelected: onUmidadeChanged,
          ),
          ChoiceChipGroup(
            label: 'Houve chuva durante o carregamento?',
            options: ['Sim', 'Não'],
            selectedOption: houveChuva,
            onSelected: onChuvaChanged,
          ),
          ChoiceChipGroup(
            label: 'Fornecedor acompanhou a carga e a preparação das amostras?',
            options: [
              'Sim',
              'Não',
              'Somente parte da carga',
              'Somente a carga',
              'Somente a preparação das amostras',
            ],
            selectedOption: fornecedorAcompanhou,
            onSelected: onFornecedorChanged,
          ),

          const Text('Observações'),
          TextFormField(controller: observacoesController, maxLines: 3),

          const SizedBox(height: 16),
          const Text('Imagens',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ImageGrid(
            images: images,
            onAddImage: onAddImage,
            onRemoveImage: onRemoveImage,
          ),
        ]),
      ),
    );
  }

  Widget _buildDataHoraRow(
    String dataLabel,
    TextEditingController dataController,
    IconData dataIcon,
    Future<void> Function(TextEditingController) onDataSelect,
    String horaLabel,
    TextEditingController horaController,
    IconData horaIcon,
    Future<void> Function(TextEditingController) onHoraSelect,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dataLabel),
              TextFormField(
                controller: dataController,
                decoration: InputDecoration(suffixIcon: Icon(dataIcon)),
                readOnly: true,
                onTap: () => onDataSelect(dataController),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Campo obrigatório' : null,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(horaLabel),
              TextFormField(
                controller: horaController,
                decoration: InputDecoration(suffixIcon: Icon(horaIcon)),
                readOnly: true,
                onTap: () => onHoraSelect(horaController),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Campo obrigatório' : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
