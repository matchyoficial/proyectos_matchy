// 📂 lib/widgets/foto_perfil_usuario.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FotoPerfilUsuario extends StatelessWidget {
  final String uid;
  final BoxFit fit;
  final Alignment alignment;

  const FotoPerfilUsuario({
    super.key,
    required this.uid,
    this.fit = BoxFit.cover,
    // 🔥 Por defecto priorizamos la parte superior (Anti-corte de cabezas)
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Si no viene UID, mostramos la foto por defecto
    if (uid.isEmpty) return _buildDefault();

    // 2. Nos conectamos EN VIVO a la colección de usuarios
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {

        // Cargando... (mostramos un fondo gris oscuro sutil)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(color: Colors.grey[900]);
        }

        // Si hay error o el usuario no existe
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return _buildDefault();
        }

        // 3. Extraemos la URL fresca directamente del perfil del usuario
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final url = data?['profilePhotoUrl']?.toString() ?? '';

        // Si el usuario existe pero no tiene foto configurada
        if (url.isEmpty) return _buildDefault();

        // 4. Mostramos la FOTO REAL ACTUALIZADA
        return Image.network(
          url,
          fit: fit,
          alignment: alignment,
          errorBuilder: (_, __, ___) => _buildDefault(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(color: Colors.grey[900]);
          },
        );
      },
    );
  }

  // 🔹 Widget auxiliar para la imagen por defecto
  Widget _buildDefault() {
    return Image.asset(
      'assets/images/perfil1.jpg', // Asegúrate que esta ruta exista en tus assets
      fit: fit,
      alignment: alignment,
    );
  }
}