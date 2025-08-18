import 'package:flutter/material.dart';
import '../constants.dart';

class CustomLoadingWidget extends StatelessWidget {
  final String? message;
  final double? size;
  
  const CustomLoadingWidget({
    super.key,
    this.message,
    this.size = 200.0, // Tamanho maior por padrão
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorPrimary, // Fundo azul
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // GIF de loading
              Image.asset(
                'assets/images/loading.gif',
                width: size,
                height: size,
                fit: BoxFit.contain,
              ),
              
              if (message != null) ...[
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    message!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Widget mais compacto para usar dentro de outros widgets
class CompactLoadingWidget extends StatelessWidget {
  final String? message;
  final double? size;
  final Color? backgroundColor;
  
  const CompactLoadingWidget({
    super.key,
    this.message,
    this.size = 80.0,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor ?? colorPrimary.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/loading.gif',
            width: size,
            height: size,
            fit: BoxFit.contain,
          ),
          
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(
              message!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// Widget para loading em tela cheia com overlay
class FullScreenLoadingWidget extends StatelessWidget {
  final String? message;
  final double? size;
  
  const FullScreenLoadingWidget({
    super.key,
    this.message,
    this.size = 200.0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorPrimary.withOpacity(0.95), // Fundo azul com leve transparência
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // GIF de loading
              Image.asset(
                'assets/images/loading.gif',
                width: size,
                height: size,
                fit: BoxFit.contain,
              ),
              
              if (message != null) ...[
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    message!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
