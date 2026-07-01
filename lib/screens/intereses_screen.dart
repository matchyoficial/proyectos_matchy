// 📂 lib/screens/intereses_screen.dart
// 🚧 PLACEHOLDER TEMPORAL — pantalla de destino cuando el usuario desliza a la derecha en Comunidad.
// Recibe el uid del perfil al que se le dio "me interesa". Se diseñará por completo en el siguiente paso.

import 'package:flutter/material.dart';

class InteresesScreen extends StatelessWidget {
  static const String routeName = 'intereses';
  final String uid;
  const InteresesScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover)),
          Column(
            children: [
              const SizedBox(height: 45),
              SizedBox(height: 45, child: Image.asset('assets/images/logomatchyplano.png')),
              const Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    child: Text(
                      '¡Le diste "me interesa" a este perfil! 💜\nEsta pantalla se completará muy pronto.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Poppins', fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 50, left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 1)),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}