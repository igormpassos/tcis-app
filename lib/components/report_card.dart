import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';


class reportCard extends StatelessWidget {
  const reportCard({
    super.key,
    required this.title,
    required this.data,
    required this.cliente,
    required this.produto,
    required this.terminal,
    this.color = const Color(0xFF003C92),
    this.iconSrc = "assets/icons/ios.svg", required String pathPdf,
  });

  final String title, iconSrc, data, cliente, produto, terminal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      height: 230,
      width: 230,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.all(Radius.circular(30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6, right: 8),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      data,
                      style: TextStyle(
                        color: Colors.white38,
                        fontWeight: FontWeight.w500
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                        cliente,
                        style: TextStyle(
                          color: Colors.white38,
                          fontWeight: FontWeight.w500
                        ),
                      ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                        produto,
                        style: TextStyle(
                          color: Colors.white38,
                          fontWeight: FontWeight.w500
                        ),
                      ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      terminal,
                      style: TextStyle(
                        color: Colors.white38,
                        fontWeight: FontWeight.w500
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Row(
                  //   children: List.generate(
                  //     1,
                  //     (index) => Transform.translate(
                  //       offset: Offset((-10 * index).toDouble(), 0),
                  //       child: CircleAvatar(
                  //         radius: 20,
                  //         backgroundImage: AssetImage(
                  //           "assets/avaters/Avatar ${index + 1}.jpg",
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        PopupMenuButton<String>(
          itemBuilder: (BuildContext context) {
            return [
              PopupMenuItem(
                child: Text('Editar'),
                onTap: () => print('Editar'),
              ),
              PopupMenuItem(
                child: Text('Deletar'),
                onTap: () => print('Delete'),
              ),
            ];
          },
          icon: Icon(Icons.more_vert_outlined, color: Colors.white),
        )
        ],
      ),
    );
  }
}