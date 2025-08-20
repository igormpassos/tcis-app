import 'package:flutter/material.dart';
import 'package:tcis_app/constants.dart';

class MultiSelectDropdown<T> extends StatefulWidget {
  final List<T> items;
  final List<T> selectedItems;
  final Function(List<T>) onSelectionChanged;
  final String Function(T) displayText;
  final String hintText;
  final String? Function(List<T>?)? validator;
  final bool enabled;

  const MultiSelectDropdown({
    super.key,
    required this.items,
    required this.selectedItems,
    required this.onSelectionChanged,
    required this.displayText,
    required this.hintText,
    this.validator,
    this.enabled = true,
  });

  @override
  State<MultiSelectDropdown<T>> createState() => _MultiSelectDropdownState<T>();
}

class _MultiSelectDropdownState<T> extends State<MultiSelectDropdown<T>> {
  FormFieldState<List<T>>? _fieldState;

  void _showMultiSelectDialog() async {
    final List<T>? result = await showDialog<List<T>>(
      context: context,
      builder: (BuildContext context) {
        return _MultiSelectDialog<T>(
          items: widget.items,
          selectedItems: List.from(widget.selectedItems),
          displayText: widget.displayText,
          title: widget.hintText,
        );
      },
    );

    if (result != null) {
      widget.onSelectionChanged(result);
      _fieldState?.didChange(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<List<T>>(
      validator: widget.validator,
      initialValue: widget.selectedItems,
      builder: (FormFieldState<List<T>> state) {
        _fieldState = state;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: widget.enabled ? _showMultiSelectDialog : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: widget.enabled ? Colors.grey[100] : Colors.grey[200],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: widget.selectedItems.isEmpty
                          ? Text(
                              widget.hintText,
                              style: TextStyle(color: LabelColor, fontSize: 14, fontWeight: FontWeight.w400),
                            )
                          : Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: widget.selectedItems.map((item) {
                                return Chip(
                                  label: Text(
                                    widget.displayText(item),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  backgroundColor: colorPrimary.withValues(alpha: 0.1),
                                  labelStyle: TextStyle(color: colorPrimary),
                                  deleteIcon: const Icon(Icons.close, size: 15),
                                  onDeleted: () {
                                    final newSelection = List<T>.from(widget.selectedItems);
                                    newSelection.remove(item);
                                    widget.onSelectionChanged(newSelection);
                                    _fieldState?.didChange(newSelection);
                                  },
                                );
                              }).toList(),
                            ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: widget.enabled ? Colors.grey : Colors.grey[400],
                    ),
                  ],
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  state.errorText!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MultiSelectDialog<T> extends StatefulWidget {
  final List<T> items;
  final List<T> selectedItems;
  final String Function(T) displayText;
  final String title;

  const _MultiSelectDialog({
    required this.items,
    required this.selectedItems,
    required this.displayText,
    required this.title,
  });

  @override
  State<_MultiSelectDialog<T>> createState() => _MultiSelectDialogState<T>();
}

class _MultiSelectDialogState<T> extends State<_MultiSelectDialog<T>> {
  late List<T> _tempSelectedItems;

  @override
  void initState() {
    super.initState();
    _tempSelectedItems = List.from(widget.selectedItems);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: ListView.builder(
          itemCount: widget.items.length,
          itemBuilder: (context, index) {
            final item = widget.items[index];
            final isSelected = _tempSelectedItems.contains(item);

            return CheckboxListTile(
              title: Text(widget.displayText(item)),
              value: isSelected,
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _tempSelectedItems.add(item);
                  } else {
                    _tempSelectedItems.remove(item);
                  }
                });
              },
              activeColor: colorPrimary,
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            foregroundColor: colorPrimary,
          ),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_tempSelectedItems),
          style: TextButton.styleFrom(
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        foregroundColor: Colors.white,
        backgroundColor: colorPrimary,
          ),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
