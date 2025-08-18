import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/data_controller.dart';
import '../../model/api_models.dart';
import '../../widgets/form/dynamic_selectors.dart';

class ReportFormExample extends StatefulWidget {
  const ReportFormExample({super.key});

  @override
  State<ReportFormExample> createState() => _ReportFormExampleState();
}

class _ReportFormExampleState extends State<ReportFormExample> {
  final _formKey = GlobalKey<FormState>();
  
  // Dados do formulário
  Terminal? selectedTerminal;
  Supplier? selectedSupplier;
  Product? selectedProduct;
  int? selectedEmployeeId;
  
  final TextEditingController _observationsController = TextEditingController();
  final TextEditingController _otherSupplierController = TextEditingController();

  @override
  void dispose() {
    _observationsController.dispose();
    _otherSupplierController.dispose();
    super.dispose();
  }

  void _onSupplierChanged(Supplier? supplier) {
    setState(() {
      selectedSupplier = supplier;
      selectedProduct = null; // Reset produto quando fornecedor muda
    });
  }

  void _onProductChanged(Product? product) {
    setState(() {
      selectedProduct = product;
    });
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final authController = Provider.of<AuthController>(context, listen: false);
    
    // Exemplo de dados do formulário
    final reportData = {
      'terminalId': selectedTerminal?.id,
      'supplierId': selectedSupplier?.id,
      'productId': selectedProduct?.id,
      'employeeId': selectedEmployeeId ?? authController.currentUser?.id,
      'observations': _observationsController.text,
      'otherSupplier': selectedSupplier == null ? _otherSupplierController.text : null,
    };

    print('Dados do formulário: $reportData');
    
    // Aqui você chamaria a API para criar o relatório
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Formulário validado com sucesso!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthController, DataController>(
      builder: (context, authController, dataController, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Novo Relatório'),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Informações do usuário logado
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Inspetor Logado',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${authController.currentUser?.name ?? authController.currentUser?.username}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          Text(
                            'Role: ${authController.currentUser?.role}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Seleção de terminal
                  DynamicTerminalSelector(
                    selectedTerminal: selectedTerminal,
                    onChanged: (terminal) => setState(() => selectedTerminal = terminal),
                  ),
                  const SizedBox(height: 16),

                  // Seleção de fornecedor
                  DynamicSupplierSelector(
                    selectedSupplier: selectedSupplier,
                    onChanged: _onSupplierChanged,
                  ),
                  const SizedBox(height: 16),

                  // Campo "Outro fornecedor" (aparece apenas se não selecionou fornecedor)
                  if (selectedSupplier == null) ...[
                    TextFormField(
                      controller: _otherSupplierController,
                      decoration: const InputDecoration(
                        labelText: 'Especificar fornecedor *',
                        prefixIcon: Icon(Icons.edit),
                        border: OutlineInputBorder(),
                        helperText: 'Digite o nome do fornecedor',
                      ),
                      validator: (value) {
                        if (selectedSupplier == null && (value == null || value.isEmpty)) {
                          return 'Especifique o fornecedor';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Seleção de produto
                  DynamicProductSelector(
                    selectedProduct: selectedProduct,
                    selectedSupplier: selectedSupplier,
                    onChanged: _onProductChanged,
                  ),
                  const SizedBox(height: 16),

                  // Seleção de colaborador (apenas para ADMINs)
                  if (authController.isAdmin) ...[
                    DynamicEmployeeSelector(
                      selectedEmployeeId: selectedEmployeeId,
                      onChanged: (employeeId) => setState(() => selectedEmployeeId = employeeId),
                      isRequired: false,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Deixe em branco para usar o usuário logado',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Observações
                  TextFormField(
                    controller: _observationsController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Observações',
                      prefixIcon: Icon(Icons.note),
                      border: OutlineInputBorder(),
                      helperText: 'Observações gerais sobre a inspeção',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Status dos dados carregados
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status dos Dados:',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text('✅ Terminais: ${dataController.terminals.length} carregados'),
                          Text('✅ Fornecedores: ${dataController.suppliers.length} carregados'),
                          Text('✅ Produtos: ${dataController.products.length} carregados'),
                          Text('✅ Colaboradores: ${dataController.users.length} carregados'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Botão de envio
                  ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Validar Formulário'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
