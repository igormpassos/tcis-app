import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/data_controller.dart';
import '../../model/api_models.dart';

class DynamicTerminalSelector extends StatelessWidget {
  final Terminal? selectedTerminal;
  final Function(Terminal?) onChanged;
  final String? errorText;

  const DynamicTerminalSelector({
    super.key,
    this.selectedTerminal,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<DataController>(
      builder: (context, dataController, child) {
        if (dataController.isLoadingTerminals) {
          return DropdownButtonFormField<Terminal>(
            decoration: const InputDecoration(
              labelText: 'Carregando terminais...',
              prefixIcon: Icon(Icons.location_city),
            ),
            items: const [],
            onChanged: null,
          );
        }

        return DropdownButtonFormField<Terminal>(
          value: selectedTerminal,
          decoration: InputDecoration(
            labelText: 'Terminal *',
            prefixIcon: const Icon(Icons.location_city),
            errorText: errorText,
            border: const OutlineInputBorder(),
          ),
          items: dataController.terminals.map((terminal) {
            return DropdownMenuItem<Terminal>(
              value: terminal,
              child: Text('${terminal.code} - ${terminal.name}'),
            );
          }).toList(),
          onChanged: onChanged,
          validator: (value) {
            if (value == null) {
              return 'Selecione um terminal';
            }
            return null;
          },
        );
      },
    );
  }
}

class DynamicSupplierSelector extends StatelessWidget {
  final Supplier? selectedSupplier;
  final Function(Supplier?) onChanged;
  final String? errorText;

  const DynamicSupplierSelector({
    super.key,
    this.selectedSupplier,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<DataController>(
      builder: (context, dataController, child) {
        if (dataController.isLoadingSuppliers) {
          return DropdownButtonFormField<Supplier>(
            decoration: const InputDecoration(
              labelText: 'Carregando fornecedores...',
              prefixIcon: Icon(Icons.business),
            ),
            items: const [],
            onChanged: null,
          );
        }

        final suppliers = List<Supplier>.from(dataController.suppliers)
          ..sort((a, b) => a.name.compareTo(b.name));

        return DropdownButtonFormField<Supplier>(
          value: selectedSupplier,
          decoration: InputDecoration(
            labelText: 'Fornecedor *',
            prefixIcon: const Icon(Icons.business),
            errorText: errorText,
            border: const OutlineInputBorder(),
          ),
          items: [
            ...suppliers.map((supplier) {
              return DropdownMenuItem<Supplier>(
                value: supplier,
                child: Text(supplier.name),
              );
            }),
            const DropdownMenuItem<Supplier>(
              value: null,
              child: Text('Outro (especificar)'),
            ),
          ],
          onChanged: onChanged,
          validator: (value) {
            // Permitir null para "Outro"
            return null;
          },
        );
      },
    );
  }
}

class DynamicProductSelector extends StatelessWidget {
  final Product? selectedProduct;
  final Function(Product?) onChanged;
  final Supplier? selectedSupplier;
  final String? errorText;

  const DynamicProductSelector({
    super.key,
    this.selectedProduct,
    required this.onChanged,
    this.selectedSupplier,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<DataController>(
      builder: (context, dataController, child) {
        if (dataController.isLoadingProducts) {
          return DropdownButtonFormField<Product>(
            decoration: const InputDecoration(
              labelText: 'Carregando produtos...',
              prefixIcon: Icon(Icons.inventory),
            ),
            items: const [],
            onChanged: null,
          );
        }

        // Filtrar produtos pelo fornecedor selecionado
        List<Product> availableProducts = [];
        if (selectedSupplier != null) {
          availableProducts = dataController
              .getProductsBySupplier(selectedSupplier!.id)
              .where((product) => product.active)
              .toList();
        } else {
          availableProducts = dataController.products
              .where((product) => product.active)
              .toList();
        }

        availableProducts.sort((a, b) => a.name.compareTo(b.name));

        return DropdownButtonFormField<Product>(
          value: selectedProduct,
          decoration: InputDecoration(
            labelText: selectedSupplier != null 
                ? 'Produto - ${selectedSupplier!.name} *'
                : 'Produto *',
            prefixIcon: const Icon(Icons.inventory),
            errorText: errorText,
            border: const OutlineInputBorder(),
            helperText: selectedSupplier != null 
                ? '${availableProducts.length} produtos disponíveis'
                : 'Selecione um fornecedor primeiro',
          ),
          items: availableProducts.map((product) {
            return DropdownMenuItem<Product>(
              value: product,
              child: Text(product.name),
            );
          }).toList(),
          onChanged: availableProducts.isEmpty ? null : onChanged,
          validator: (value) {
            if (selectedSupplier != null && value == null && availableProducts.isNotEmpty) {
              return 'Selecione um produto';
            }
            return null;
          },
        );
      },
    );
  }
}

class DynamicEmployeeSelector extends StatelessWidget {
  final int? selectedEmployeeId;
  final Function(int?) onChanged;
  final String? errorText;
  final bool isRequired;

  const DynamicEmployeeSelector({
    super.key,
    this.selectedEmployeeId,
    required this.onChanged,
    this.errorText,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<DataController>(
      builder: (context, dataController, child) {
        if (dataController.isLoadingUsers) {
          return DropdownButtonFormField<int>(
            decoration: const InputDecoration(
              labelText: 'Carregando colaboradores...',
              prefixIcon: Icon(Icons.person),
            ),
            items: const [],
            onChanged: null,
          );
        }

        final users = List.from(dataController.users)
          ..sort((a, b) => a.name.compareTo(b.name));

        return DropdownButtonFormField<int>(
          value: selectedEmployeeId,
          decoration: InputDecoration(
            labelText: isRequired ? 'Colaborador *' : 'Colaborador',
            prefixIcon: const Icon(Icons.person),
            errorText: errorText,
            border: const OutlineInputBorder(),
            helperText: 'Selecione o inspetor responsável',
          ),
          items: users.map((user) {
            return DropdownMenuItem<int>(
              value: user.id,
              child: Text(user.name ?? user.username),
            );
          }).toList(),
          onChanged: onChanged,
          validator: (value) {
            if (isRequired && value == null) {
              return 'Selecione um colaborador';
            }
            return null;
          },
        );
      },
    );
  }
}
