import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:proyectos_matchy/models/lugar_data.dart';

class CitaCreadaScreen extends ConsumerStatefulWidget {
  final String citaId;
  final LugarData lugar;
  final String fecha;
  final String hora;
  final String preferencia;
  final String intencion;

  const CitaCreadaScreen({
    super.key,
    required this.citaId,
    required this.lugar,
    required this.fecha,
    required this.hora,
    required this.preferencia,
    required this.intencion,
  });

  @override
  ConsumerState<CitaCreadaScreen> createState() => _CitaCreadaScreenState();
}

class _CitaCreadaScreenState extends ConsumerState<CitaCreadaScreen> {
  late final String _codigoCita;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _codigoCita = _generarCodigo();
  }

  String _generarCodigo() {
    const letras = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const numeros = '0123456789';
    final r = Random();

    return List.generate(3, (_) => letras[r.nextInt(letras.length)]).join() +
        List.generate(5, (_) => numeros[r.nextInt(numeros.length)]).join();
  }

  String _fotoLugar() {
    if (widget.lugar.fotos.isEmpty) return 'assets/images/faro1.jpg';
    final f = widget.lugar.fotos.first.trim();
    if (f.startsWith('http')) return f;
    return f.isEmpty ? 'assets/images/faro1.jpg' : f;
  }

  Future<void> _cancelarCita() async {
    if (_cancelling) return;
    setState(() => _cancelling = true);

    await FirebaseFirestore.instance
        .collection('citas')
        .doc(widget.citaId)
        .set({
      'status': 'cancelled',
      'cancelledAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Image.asset(
                  'assets/images/logomatchyplano.png',
                  height: 50,
                ),
                const SizedBox(height: 20),

                // FOTO DEL LUGAR
                Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _fotoLugar().startsWith('http')
                      ? Image.network(_fotoLugar(), fit: BoxFit.cover)
                      : Image.asset(_fotoLugar(), fit: BoxFit.cover),
                ),

                const SizedBox(height: 20),

                const Text(
                  'TU CITA ESTÁ CREADA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 18),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'LUGAR: ${widget.lugar.nombre}\n'
                        'DIRECCIÓN: ${widget.lugar.direccion}\n'
                        'FECHA: ${widget.fecha}\n'
                        'HORA: ${widget.hora}\n'
                        'PREFERENCIA: ${widget.preferencia}\n'
                        'INTENCIÓN: ${widget.intencion}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // 🔶 TEXTO AMARILLO BIEN JUSTIFICADO
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 28),
                  child: Text(
                    'RECUERDA QUE SI HACES MATCHY CON ALGUIEN\n'
                        'TIENES UN MÁXIMO DE 12 HORAS PARA\n'
                        'CANCELAR TU CITA.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFFFC107),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'RECUERDA QUE EN MATCHY\nEL QUE INVITA PAGA.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFFF5252),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 22),

                const Text(
                  'CÓDIGO DE LA CITA:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  _codigoCita,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 22),

                // 🔴 BOTÓN CANCELAR — TEXTO BLANCO
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _cancelarCita,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'CANCELAR TU CITA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 🔵 BOTÓN REGRESAR — TEXTO BLANCO
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.of(context).popUntil((r) => r.isFirst),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A5ACD),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'REGRESAR AL PANEL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
