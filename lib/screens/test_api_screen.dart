import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/data_controller.dart';
import '../widgets/form/dynamic_selectors.dart';
import '../model/api_models.dart';

class TestApiScreen extends StatefulWidget {
  const TestApiScreen({super.key});

  @override
  State<TestApiScreen> createState() => _TestApiScreenState();
}

class _TestApiScreenState extends State<TestApiScreen> {
  Terminal? selectedTerminal;
  Supplier? selectedSupplier;
  Product? selectedProduct;

  @override
  void initState() {
    super.initState();
    // Carrega dados iniciais
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DataController>().loadTerminals();
      context.read<DataController>().loadSuppliers();
      context.read<DataController>().loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste de Integração API'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Verifica se pode voltar, senão vai para home
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informações do usuário logado
            Consumer<AuthController>(
              builder: (context, authController, child) {
                final user = authController.currentUser;
                if (user != null) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Usuário Logado:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text('Nome: ${user.name}'),
                          Text('Username: ${user.username}'),
                          Text('Email: ${user.email}'),
                          Text('Role: ${user.role}'),
                        ],
                      ),
                    ),
                  );
                }
                return const Text('Nenhum usuário logado');
              },
            ),
            
            const SizedBox(height: 20),
            
            // Contadores de dados
            Consumer<DataController>(
              builder: (context, dataController, child) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dados Carregados:',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text('Terminais: ${dataController.terminals.length}'),
                        Text('Fornecedores: ${dataController.suppliers.length}'),
                        Text('Produtos: ${dataController.products.length}'),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 20),
            
            // Teste dos seletores dinâmicos
            const Text(
              'Seletores Dinâmicos:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            
            const SizedBox(height: 16),
            
            // Selector de Terminal
            DynamicTerminalSelector(
              selectedTerminal: selectedTerminal,
              onChanged: (terminal) {
                setState(() {
                  selectedTerminal = terminal;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Selector de Fornecedor
            DynamicSupplierSelector(
              selectedSupplier: selectedSupplier,
              onChanged: (supplier) {
                setState(() {
                  selectedSupplier = supplier;
                  // Reset product when supplier changes
                  selectedProduct = null;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Selector de Produto
            DynamicProductSelector(
              selectedProduct: selectedProduct,
              selectedSupplier: selectedSupplier,
              onChanged: (product) {
                setState(() {
                  selectedProduct = product;
                });
              },
            ),
            
            const SizedBox(height: 20),
            
            // Mostra os valores selecionados
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selecionados:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('Terminal: ${selectedTerminal?.name ?? "Nenhum"}'),
                    Text('Fornecedor: ${selectedSupplier?.name ?? "Nenhum"}'),
                    Text('Produto: ${selectedProduct?.name ?? "Nenhum"}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
