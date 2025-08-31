import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tcis_app/constants.dart';
import '../../controllers/data_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../model/api_models.dart';
import '../common/multi_select_dropdown.dart';

class DadosRelatorioCardApi extends StatefulWidget {
  final TextEditingController prefixoController;
  final String? selectedTerminal;
  final ValueChanged<String?> onTerminalChanged;
  final String? colaborador;
  final ValueChanged<String?> onColaboradorChanged;
  final List<String> selectedProdutos;
  final ValueChanged<List<String>> onProdutosChanged;
  final List<String> selectedFornecedores;
  final ValueChanged<List<String>> onFornecedoresChanged;
  final String? selectedCliente;
  final ValueChanged<String?> onClienteChanged;
  final bool isEditMode;

  const DadosRelatorioCardApi({
    super.key,
    required this.prefixoController,
    required this.selectedTerminal,
    required this.onTerminalChanged,
    required this.colaborador,
    required this.onColaboradorChanged,
    required this.selectedProdutos,
    required this.onProdutosChanged,
    required this.selectedFornecedores,
    required this.onFornecedoresChanged,
    required this.selectedCliente,
    required this.onClienteChanged,
    this.isEditMode = false,
  });

  @override
  State<DadosRelatorioCardApi> createState() => _DadosRelatorioCardApiState();
}

class _DadosRelatorioCardApiState extends State<DadosRelatorioCardApi> {
  Terminal? selectedTerminalObj;
  Supplier? selectedSupplierObj;
  Product? selectedProductObj;

  @override
  void initState() {
    super.initState();
    // Carrega dados da API quando o widget é inicializado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DataController>().loadAllData();
      
      // Se não é admin, define o colaborador como o usuário logado
      final authController = context.read<AuthController>();
      if (authController.currentUser?.role != 'ADMIN') {
        final userName = authController.currentUser?.name ?? authController.currentUser?.username;
        // Só define se não há valor ou se está vazio
        if (widget.colaborador?.isEmpty ?? true) {
          widget.onColaboradorChanged(userName);
        }
      } else {
        // Se é admin e não há colaborador selecionado, seleciona o usuário logado por padrão
        // Mas só se não houver um colaborador já definido (modo criação)
        if (widget.colaborador == null || widget.colaborador!.isEmpty) {
          final userName = authController.currentUser?.name ?? authController.currentUser?.username;
          widget.onColaboradorChanged(userName);
        }
      }
      
      // Selecionar automaticamente o primeiro cliente APENAS no modo de criação
      if (!widget.isEditMode && (widget.selectedCliente?.isEmpty ?? true)) {
        final dataController = context.read<DataController>();
        if (dataController.clients.isNotEmpty) {
          widget.onClienteChanged(dataController.clients.first.name);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dados do Relatório', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),

            // Prefixo - comportamento baseado no modo e role do usuário
            Consumer<AuthController>(
              builder: (context, authController, child) {
                final isAdmin = authController.currentUser?.role == 'ADMIN';
                
                // Em modo criação: oculta completamente para não-admins
                if (!widget.isEditMode && !isAdmin) {
                  return const SizedBox.shrink();
                }
                
                // Em modo edição: mostra desabilitado para não-admins
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Prefixo'),
                    TextFormField(
                      controller: widget.prefixoController,
                      enabled: isAdmin, // Só admins podem editar
                      decoration: InputDecoration(
                        hintText: widget.isEditMode 
                            ? (isAdmin ? 'Prefixo do relatório' : 'Somente administradores podem alterar')
                            : 'Deixe vazio para gerar automaticamente',
                        filled: !isAdmin,
                        fillColor: !isAdmin ? Colors.grey.shade100 : null,
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
            
            // Terminal Selector com design original
            const Text('Terminal *'),
            Consumer<DataController>(
              builder: (context, dataController, child) {
                if (dataController.isLoadingTerminals) {
                  return DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      hintText: "Carregando terminais...",
                      hintStyle: TextStyle(color: LabelColor),
                    ),
                    items: const [],
                    onChanged: null,
                  );
                }

                final terminais = dataController.terminals.map((t) => '${t.code} - ${t.name}').toList();
                //terminais.add('Outro');

                // Encontrar o terminal correspondente pelo nome
                String? selectedValue;
                if (widget.selectedTerminal != null && widget.selectedTerminal!.isNotEmpty) {
                  // Procurar pelo formato completo primeiro
                  if (terminais.contains(widget.selectedTerminal)) {
                    selectedValue = widget.selectedTerminal;
                  } else {
                    // Se não encontrar, procurar pelo nome
                    final matchingTerminal = terminais.firstWhere(
                      (terminal) => terminal.contains(widget.selectedTerminal!),
                      orElse: () => '',
                    );
                    selectedValue = matchingTerminal.isNotEmpty ? matchingTerminal : null;
                  }
                }

                return DropdownButtonFormField<String>(
                  value: selectedValue,
                  hint: Text("Selecione uma opção", style: TextStyle(color: LabelColor)),
                  style: TextStyle(fontSize: 15, color: TextDarkColor),
                  borderRadius: BorderRadius.circular(15),
                  dropdownColor: backgroundColorLight.withAlpha(230),
                  onChanged: (value) {
                    if (value == 'Outro') {
                      _showCustomDialog(
                        context,
                        title: 'Qual o Terminal?',
                        onSubmit: (custom) => widget.onTerminalChanged(custom),
                      );
                    } else {
                      widget.onTerminalChanged(value);
                    }
                  },
                  items: terminais.map((terminal) {
                    return DropdownMenuItem<String>(
                      value: terminal,
                      child: Text(terminal),
                    );
                  }).toList(),
                  validator: (value) => (widget.selectedTerminal?.isEmpty ?? true) ? 'Campo obrigatório' : null,
                );
              },
            ),

            const SizedBox(height: 16),
            
            // Colaborador - lógica baseada no role
            const Text('Colaborador *'),
            Consumer<AuthController>(
              builder: (context, authController, child) {
                final user = authController.currentUser;
                final isAdmin = user?.role == 'ADMIN';

                if (!isAdmin) {
                  // Se não é admin, mostra o nome do usuário logado como texto
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.grey.shade50,
                    ),
                    child: Text(
                      user?.name ?? 'Usuário não identificado',
                      style: TextStyle(fontSize: 15, color: TextDarkColor),
                    ),
                  );
                }

                // Se é admin, mostra dropdown com usuários cadastrados
                return Consumer<DataController>(
                  builder: (context, dataController, child) {
                    // Lista de todos os colaboradores da API (inclui ADMIN e USER)
                    final colaboradores = dataController.users
                        .map((user) => user.name ?? user.username)
                        .toList();

                    // Se não há colaboradores, exibe mensagem
                    if (colaboradores.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.grey.shade50,
                        ),
                        child: Text(
                          'Nenhum colaborador encontrado',
                          style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                        ),
                      );
                    }

                    // Garantir que o usuário logado esteja na lista, mas sem duplicar
                    final currentUserName = user?.name ?? user?.username ?? 'Usuário não identificado';
                    final opcoesColaboradores = List<String>.from(colaboradores);
                    
                    // Só adiciona o usuário logado se não estiver na lista
                    if (!opcoesColaboradores.contains(currentUserName)) {
                      opcoesColaboradores.insert(0, currentUserName);
                    }

                    return DropdownButtonFormField<String>(
                      value: opcoesColaboradores.contains(widget.colaborador) ? widget.colaborador : currentUserName,
                      hint: Text("Selecione uma opção", style: TextStyle(color: LabelColor)),
                      style: TextStyle(fontSize: 15, color: TextDarkColor),
                      borderRadius: BorderRadius.circular(15),
                      dropdownColor: backgroundColorLight.withAlpha(230),
                      items: opcoesColaboradores.map((colaborador) {
                        return DropdownMenuItem<String>(
                          value: colaborador,
                          child: Text(colaborador),
                        );
                      }).toList(),
                      onChanged: (value) {
                        widget.onColaboradorChanged(value);
                      },
                      validator: (value) => (value?.isEmpty ?? true) ? 'Campo obrigatório' : null,
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 16),
            
            // Cliente Selector
            const Text('Cliente *'),
            Consumer<DataController>(
              builder: (context, dataController, child) {
                if (dataController.isLoadingClients) {
                  return DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      hintText: "Carregando clientes...",
                      hintStyle: TextStyle(color: LabelColor),
                    ),
                    items: const [],
                    onChanged: null,
                  );
                }

                final clientes = dataController.clients.map((c) => c.name).toList();

                // Em modo de edição, preserva o valor atual. Em modo de criação, usa o primeiro se não há seleção
                String? currentValue;
                if (widget.isEditMode) {
                  // Modo de edição: preserva o valor selecionado se válido
                  currentValue = clientes.contains(widget.selectedCliente) ? widget.selectedCliente : null;
                } else {
                  // Modo de criação: usa primeiro cliente se não há seleção
                  currentValue = clientes.contains(widget.selectedCliente) ? widget.selectedCliente : (clientes.isNotEmpty ? clientes.first : null);
                }

                return DropdownButtonFormField<String>(
                  value: currentValue,
                  hint: Text("Selecione uma opção", style: TextStyle(color: LabelColor)),
                  style: TextStyle(fontSize: 15, color: TextDarkColor),
                  borderRadius: BorderRadius.circular(15),
                  dropdownColor: backgroundColorLight.withAlpha(230),
                  onChanged: (value) {
                    widget.onClienteChanged(value);
                  },
                  items: clientes.map((cliente) {
                    return DropdownMenuItem<String>(
                      value: cliente,
                      child: Text(cliente),
                    );
                  }).toList(),
                  validator: (value) => (value?.isEmpty ?? true) ? 'Campo obrigatório' : null,
                );
              },
            ),

            const SizedBox(height: 16),
            
            // Fornecedor Multi-Select
            const Text('Fornecedores *'),
            Consumer<DataController>(
              builder: (context, dataController, child) {
                if (dataController.isLoadingSuppliers) {
                  return const CircularProgressIndicator();
                }

                final fornecedoresDisponiveis = dataController.suppliers
                    .where((s) => s.active)
                    .toList();

                return MultiSelectDropdown<Supplier>(
                  items: fornecedoresDisponiveis,
                  selectedItems: fornecedoresDisponiveis
                      .where((s) => widget.selectedFornecedores.contains(s.name))
                      .toList(),
                  onSelectionChanged: (List<Supplier> selected) {
                    final selectedNames = selected.map((s) => s.name).toList();
                    widget.onFornecedoresChanged(selectedNames);
                    
                    // Reset product selection quando fornecedores mudam
                    widget.onProdutosChanged([]);
                  },
                  displayText: (supplier) => supplier.name,
                  hintText: "Selecione um ou mais fornecedores",
                  validator: (value) => 
                      (value == null || value.isEmpty) ? 'Campo obrigatório' : null,
                );
              },
            ),

            const SizedBox(height: 16),
            
            // Produto Multi-Select (filtrado pelos fornecedores selecionados)
            const Text('Produtos *'),
            Consumer<DataController>(
              builder: (context, dataController, child) {
                if (dataController.isLoadingProducts) {
                  return const CircularProgressIndicator();
                }

                // Filtrar produtos pelos fornecedores selecionados
                List<Product> availableProducts = [];
                if (widget.selectedFornecedores.isNotEmpty) {
                  final selectedSupplierIds = dataController.suppliers
                      .where((s) => widget.selectedFornecedores.contains(s.name))
                      .map((s) => s.id)
                      .toList();
                  
                  for (final supplierId in selectedSupplierIds) {
                    availableProducts.addAll(
                      dataController.getProductsBySupplier(supplierId)
                          .where((product) => product.active)
                    );
                  }
                  // Remove duplicatas
                  availableProducts = availableProducts.toSet().toList();
                } else {
                  availableProducts = dataController.products
                      .where((product) => product.active)
                      .toList();
                }

                return MultiSelectDropdown<Product>(
                  items: availableProducts,
                  selectedItems: availableProducts
                      .where((p) => widget.selectedProdutos.contains(p.name))
                      .toList(),
                  onSelectionChanged: (List<Product> selected) {
                    final selectedNames = selected.map((p) => p.name).toList();
                    widget.onProdutosChanged(selectedNames);
                  },
                  displayText: (product) => product.name,
                  hintText: widget.selectedFornecedores.isNotEmpty 
                      ? "Selecione um ou mais produtos (${availableProducts.length} disponíveis)"
                      : "Selecione fornecedores primeiro",
                  validator: (value) => 
                      (value == null || value.isEmpty) ? 'Campo obrigatório' : null,
                  enabled: widget.selectedFornecedores.isNotEmpty,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomDialog(BuildContext context, {required String title, required Function(String) onSubmit}) {
    showDialog(
      context: context,
      builder: (_) {
        String custom = '';
        return AlertDialog(
          title: Text(title),
          content: TextField(
            autofocus: true,
            onChanged: (val) => custom = val,
            decoration: const InputDecoration(hintText: 'Digite aqui...'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (custom.isNotEmpty) {
                  onSubmit(custom);
                  Navigator.pop(context);
                }
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }
}
