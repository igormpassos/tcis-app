import 'package:flutter/material.dart';
class SecondaryreportCard extends StatelessWidget {
  const SecondaryreportCard({
    super.key,
    required this.title,
    required this.iconSrc,
    required this.data,
    required this.cliente,
    required this.produto,
    required this.terminal,
    this.colorl = const Color(0xFF003C92),
    this.status = "",
  });

  final String title, iconSrc, data, cliente, produto, terminal, status;
  final Color colorl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
          color: colorl,
          borderRadius: const BorderRadius.all(Radius.circular(20))),
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
                  '$cliente • $produto • $terminal',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                  color: status == "Em Revisão" ? Colors.orangeAccent : Colors.lightGreen,
                  borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                  status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  ),
                )
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.ios_share_outlined, color: Colors.white),
            onPressed: () {
              // Add your onPressed code here!
              print('Exportar');
            },
          ),
          const SizedBox(
            height: 40,
            child: VerticalDivider(
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundImage: NetworkImage(iconSrc),
            radius: 20,
          ),
          
        ],
      ),
    );
  }
}
