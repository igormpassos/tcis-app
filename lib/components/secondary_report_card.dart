import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';

class SecondaryreportCard extends StatelessWidget {
  const SecondaryreportCard({
    super.key,
    required this.title,
    required this.iconSrc,
    required this.data,
    required this.usuario,
    required this.fornecedor,
    required this.produto,
    required this.terminal,
    required this.pathPdf,
    this.colorl = const Color(0xFF003C92),
    this.status = "",
    this.onEdit,
    // Novos campos para listas
    this.fornecedores = const [],
    this.produtos = const [],
  });

  final String title, iconSrc, data, usuario, fornecedor, produto, terminal, status;
  final Color colorl;
  final VoidCallback? onEdit;
  final dynamic pathPdf;
  
  // Novos campos multi-select
  final List<String> fornecedores;
  final List<String> produtos;

  Color _getStatusColor() {
    switch (status) {
      case "0":
        return Colors.orange; // Rascunho
      case "1":
        return Colors.blue; // Em Revisão
      case "2":
        return Colors.green; // Concluído
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (status) {
      case "0":
        return "Rascunho";
      case "1":
        return "Em Revisão";
      case "2":
        return "Concluído";
      default:
        return "Desconhecido";
    }
  }

  bool _canEdit() {
    // Pode editar se não estiver concluído (status != "2")
    return status != "2";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: colorl,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$terminal • ${_getDisplayFornecedores()} • ${_getDisplayProdutos()}',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  usuario,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.ios_share_outlined, color: Colors.white),
            onPressed: () async {
              if (pathPdf is String && pathPdf.startsWith('http')) {
                // É uma URL do servidor - abrir no navegador
                print('📱 Abrindo PDF do servidor: $pathPdf');
                try {
                  final uri = Uri.parse(pathPdf);

                  if (await canLaunchUrl(uri)) {
                    bool success = await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );

                    if (!success) {
                      success = await launchUrl(
                        uri,
                        mode: LaunchMode.inAppWebView,
                      );
                    }

                    if (!success) {
                      success = await launchUrl(uri);
                    }

                    print('✅ PDF aberto com sucesso: $success');
                  } else {
                    print('❌ Não foi possível abrir o URL');
                  }
                } catch (e) {
                  print('❌ Erro ao abrir URL: $e');
                }
              } else if (pathPdf is String && pathPdf.isNotEmpty) {
                // É um arquivo local - abrir com OpenFile
                print('📄 Abrindo arquivo local: $pathPdf');
                OpenFile.open(pathPdf);
              } else {
                print('⚠️ PDF não disponível (URL vazia)');
              }
            },
          ),
          if (_canEdit() && onEdit != null) ...[
            // Ícone de edição - só aparece se não estiver concluído e callback foi fornecida
            const SizedBox(
              height: 40,
              child: VerticalDivider(color: Colors.white70),
            ),
            IconButton(
              icon: Icon(Icons.edit, color: Colors.white),
              onPressed: onEdit,
              tooltip: 'Editar relatório',
            ),
          ],
          const SizedBox(width: 8),
          // CircleAvatar(
          //   backgroundImage: NetworkImage(iconSrc),
          //   radius: 20,
          // ),
        ],
      ),
    );
  }
  
  // Métodos helper para exibir listas
  String _getDisplayFornecedores() {
    if (fornecedores.isNotEmpty) {
      return fornecedores.join('/');
    }
    return fornecedor.isNotEmpty ? fornecedor : 'N/A';
  }
  
  String _getDisplayProdutos() {
    if (produtos.isNotEmpty) {
      return produtos.join('/');
    }
    return produto.isNotEmpty ? produto : 'N/A';
  }
}
