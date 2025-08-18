import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tcis_app/constants.dart';
import '../../controllers/data_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../model/api_models.dart';

class DadosRelatorioCardApi extends StatefulWidget {
  final TextEditingController prefixoController;
  final String? selectedTerminal;
  final ValueChanged<String?> onTerminalChanged;
  final String? colaborador;
  final ValueChanged<String?> onColaboradorChanged;
  final String? selectedProduto;
  final ValueChanged<String?> onProdutoChanged;
  final String? fornecedor;
  final ValueChanged<String?> onFornecedorChanged;
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
    required this.selectedProduto,
    required this.onProdutoChanged,
    required this.fornecedor,
    required this.onFornecedorChanged,
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
        
        // Para não-admins, sempre define CSN como cliente padrão se não houver um selecionado
        if (widget.selectedCliente?.isEmpty ?? true) {
          widget.onClienteChanged('CSN - Companhia Siderúrgica Nacional');
        }
      } else {
        // Se é admin e não há colaborador selecionado, seleciona o usuário logado por padrão
        // Mas só se não houver um colaborador já definido (modo criação)
        if (widget.colaborador == null || widget.colaborador!.isEmpty) {
          final userName = authController.currentUser?.name ?? authController.currentUser?.username;
          widget.onColaboradorChanged(userName);
        }
        
        // Para admins, também define CSN como padrão se não houver cliente selecionado
        if (widget.selectedCliente?.isEmpty ?? true) {
          widget.onClienteChanged('CSN - Companhia Siderúrgica Nacional');
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
            
            // Cliente Selector - desabilitado para não-admins
            const Text('Cliente *'),
            Consumer<AuthController>(
              builder: (context, authController, child) {
                final isAdmin = authController.currentUser?.role == 'ADMIN';
                
                return Consumer<DataController>(
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

                    // Para não-admins, mostra apenas a CSN selecionada como texto não editável
                    if (!isAdmin) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.grey.shade50,
                        ),
                        child: Text(
                          widget.selectedCliente ?? 'CSN - Companhia Siderúrgica Nacional',
                          style: TextStyle(fontSize: 15, color: TextDarkColor),
                        ),
                      );
                    }

                    return DropdownButtonFormField<String>(
                      value: clientes.contains(widget.selectedCliente) ? widget.selectedCliente : null,
                      hint: Text("Selecione uma opção", style: TextStyle(color: LabelColor)),
                      style: TextStyle(fontSize: 15, color: TextDarkColor),
                      borderRadius: BorderRadius.circular(15),
                      dropdownColor: backgroundColorLight.withAlpha(230),
                      onChanged: (value) {
                        if (value == 'Outro') {
                          _showCustomDialog(
                            context,
                            title: 'Qual o Cliente?',
                            onSubmit: (custom) => widget.onClienteChanged(custom),
                          );
                        } else {
                          widget.onClienteChanged(value);
                        }
                      },
                      items: clientes.map((cliente) {
                        return DropdownMenuItem<String>(
                          value: cliente,
                          child: Text(cliente),
                        );
                      }).toList(),
                      validator: (value) => (widget.selectedCliente?.isEmpty ?? true) ? 'Campo obrigatório' : null,
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 16),
            
            // Fornecedor Selector com design original
            const Text('Fornecedor *'),
            Consumer<DataController>(
              builder: (context, dataController, child) {
                if (dataController.isLoadingSuppliers) {
                  return DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      hintText: "Carregando fornecedores...",
                      hintStyle: TextStyle(color: LabelColor),
                    ),
                    items: const [],
                    onChanged: null,
                  );
                }

                final fornecedores = dataController.suppliers.map((s) => s.name).toList();
                //fornecedores.add('Outro');

                return DropdownButtonFormField<String>(
                  value: fornecedores.contains(widget.fornecedor) ? widget.fornecedor : null,
                  hint: Text("Selecione uma opção", style: TextStyle(color: LabelColor)),
                  style: TextStyle(fontSize: 15, color: TextDarkColor),
                  borderRadius: BorderRadius.circular(15),
                  dropdownColor: backgroundColorLight.withAlpha(230),
                  onChanged: (value) {
                    if (value == 'Outro') {
                      _showCustomDialog(
                        context,
                        title: 'Qual o Fornecedor?',
                        onSubmit: (custom) => widget.onFornecedorChanged(custom),
                      );
                    } else {
                      // Reset product when supplier changes
                      selectedSupplierObj = dataController.suppliers.firstWhere((s) => s.name == value);
                      selectedProductObj = null;
                      widget.onFornecedorChanged(value);
                      widget.onProdutoChanged(null); // Reset product selection
                    }
                  },
                  items: fornecedores.map((fornecedor) {
                    return DropdownMenuItem<String>(
                      value: fornecedor,
                      child: Text(fornecedor),
                    );
                  }).toList(),
                  validator: (value) => (widget.fornecedor?.isEmpty ?? true) ? 'Campo obrigatório' : null,
                );
              },
            ),

            const SizedBox(height: 16),
            
            // Produto Selector com design original (filtrado pelo fornecedor)
            const Text('Produto *'),
            Consumer<DataController>(
              builder: (context, dataController, child) {
                if (dataController.isLoadingProducts) {
                  return DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      hintText: "Carregando produtos...",
                      hintStyle: TextStyle(color: LabelColor),
                    ),
                    items: const [],
                    onChanged: null,
                  );
                }

                // Filtrar produtos pelo fornecedor selecionado
                List<Product> availableProducts = [];
                if (selectedSupplierObj != null) {
                  availableProducts = dataController
                      .getProductsBySupplier(selectedSupplierObj!.id)
                      .where((product) => product.active)
                      .toList();
                } else {
                  availableProducts = dataController.products
                      .where((product) => product.active)
                      .toList();
                }

                final produtos = availableProducts.map((p) => p.name).toList();
                //produtos.add('Outro');

                return DropdownButtonFormField<String>(
                  value: produtos.contains(widget.selectedProduto) ? widget.selectedProduto : null,
                  hint: Text(
                    selectedSupplierObj != null 
                        ? "Selecione um produto (${availableProducts.length} disponíveis)"
                        : "Selecione um fornecedor primeiro", 
                    style: TextStyle(color: LabelColor)
                  ),
                  style: TextStyle(fontSize: 15, color: TextDarkColor),
                  borderRadius: BorderRadius.circular(15),
                  dropdownColor: backgroundColorLight.withAlpha(230),
                  onChanged: availableProducts.isEmpty ? null : (value) {
                    if (value == 'Outro') {
                      _showCustomDialog(
                        context,
                        title: 'Qual o Produto?',
                        onSubmit: (custom) => widget.onProdutoChanged(custom),
                      );
                    } else {
                      widget.onProdutoChanged(value);
                    }
                  },
                  items: produtos.map((produto) {
                    return DropdownMenuItem<String>(
                      value: produto,
                      child: Text(produto),
                    );
                  }).toList(),
                  validator: (value) => (widget.selectedProduto?.isEmpty ?? true) ? 'Campo obrigatório' : null,
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
