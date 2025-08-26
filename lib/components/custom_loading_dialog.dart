import 'package:flutter/material.dart';
import '../constants.dart';

class CustomLoadingDialog extends StatelessWidget {
  final String message;

  const CustomLoadingDialog({super.key, this.message = "Carregando..."});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: colorPrimary,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // GIF de loading
            Image.asset(
              'assets/images/loading.gif',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 25),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
