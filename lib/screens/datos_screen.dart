// 📂 lib/screens/datos_screen.dart
// ✅ PANTALLA DE EDICIÓN DE PERFIL BLINDADA (MATCHY OS)
// 🔥 ADD: Módulo de Verificación Biométrica (Check Azul) con Nube Persuasiva.
// 🔥 FIX: Escucha en tiempo real de 'isVerified' desde Firestore.
// 🔥 UI FIX: Títulos y secciones estandarizados.
// ⚖️ LEGAL FIX: Ventana emergente nativa con EULA y Políticas de Privacidad.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:proyectos_matchy/widgets/matchy_back_button.dart';
import 'package:proyectos_matchy/screens/panel_screen.dart';
import 'package:proyectos_matchy/state/profile_form_provider.dart';
import 'package:proyectos_matchy/widgets/gestor_fotos_widget.dart';
import 'package:proyectos_matchy/screens/verificacion_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DatosScreen extends ConsumerStatefulWidget {
  static const String routeName = 'datos';
  const DatosScreen({super.key});

  @override
  ConsumerState<DatosScreen> createState() => _DatosScreenState();
}

class _DatosScreenState extends ConsumerState<DatosScreen> {
  static const double kChincheTituloSeccion = 18.0;
  static const double kChincheLabelInput = 16.0;
  static const double kChincheTextoInput = 15.0;

  static const List<Shadow> kTextShadow = [
    Shadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 4))
  ];
  static const List<BoxShadow> kChipShadow = [
    BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 3))
  ];

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _edadCtrl;
  late final TextEditingController _profesionCtrl;
  late final TextEditingController _biografiaCtrl;
  late final TextEditingController _detalleCtrl;
  late final TextEditingController _estaturaCtrl;

  bool _mostrarErrores = false;
  bool _saving = false;
  bool _isLoadingCloudData = true;

  bool _isVerified = false;

  String _preferenciaCitas = 'Ambos';
  String _genero = '';

  String? _paisOrigen;
  String? _ciudadOrigen;
  bool _vivoEnMiOrigen = false;

  final List<String> _estaturas = List.generate(76, (i) {
    final v = 1.40 + (i * 0.01);
    return '${v.toStringAsFixed(2)} m';
  });

  @override
  void initState() {
    super.initState();
    final s = ref.read(profileFormProvider);
    _nombreCtrl = TextEditingController(text: s.nombre);
    _edadCtrl = TextEditingController(text: s.edad);
    _profesionCtrl = TextEditingController(text: s.profesion);
    _biografiaCtrl = TextEditingController(text: s.biografia);
    _detalleCtrl = TextEditingController(text: s.detalle);
    _estaturaCtrl = TextEditingController(text: s.estatura);

    _paisOrigen = s.paisOrigen;
    _ciudadOrigen = s.ciudadOrigen;

    _preferenciaCitas = s.preferenciaCitas.trim().isEmpty ? 'Ambos' : s.preferenciaCitas.trim();
    _genero = s.genero.trim();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ctrl = ref.read(profileFormProvider.notifier);
      await ctrl.loadDraft();
      await _hydrateFromFirestore(ctrl);

      final finalState = ref.read(profileFormProvider);
      _nombreCtrl.text = finalState.nombre;
      _edadCtrl.text = finalState.edad;
      _profesionCtrl.text = finalState.profesion;
      _biografiaCtrl.text = finalState.biografia;
      _detalleCtrl.text = finalState.detalle;
      _estaturaCtrl.text = finalState.estatura;

      if (!mounted) return;
      setState(() {
        _preferenciaCitas = finalState.preferenciaCitas.trim().isEmpty ? 'Ambos' : finalState.preferenciaCitas.trim();
        _genero = finalState.genero.trim();

        _paisOrigen = finalState.paisOrigen;
        _ciudadOrigen = finalState.ciudadOrigen;
        _vivoEnMiOrigen = (_paisOrigen == finalState.paisSeleccionado && _ciudadOrigen == finalState.ciudadSeleccionada && _paisOrigen != null && _paisOrigen!.isNotEmpty);

        _isLoadingCloudData = false;
      });
    });

    _nombreCtrl.addListener(() => ref.read(profileFormProvider.notifier).setNombre(_nombreCtrl.text));
    _edadCtrl.addListener(() => ref.read(profileFormProvider.notifier).setEdad(_edadCtrl.text));
    _profesionCtrl.addListener(() => ref.read(profileFormProvider.notifier).setProfesion(_profesionCtrl.text));
    _biografiaCtrl.addListener(() => ref.read(profileFormProvider.notifier).setBiografia(_biografiaCtrl.text));
    _detalleCtrl.addListener(() => ref.read(profileFormProvider.notifier).setDetalle(_detalleCtrl.text));
    _estaturaCtrl.addListener(() => ref.read(profileFormProvider.notifier).setEstatura(_estaturaCtrl.text));
  }

  void _mostrarBurbuja(String mensaje, Color color, IconData icono) {
    if (!mounted) return;
    final overlayState = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => SafeArea(
        child: Align(
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Material(
              color: Colors.transparent,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2C).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.7), width: 2),
                    boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 5))],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
                        child: Icon(icono, color: color, size: 28),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                          child: Text(
                            mensaje,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Poppins'),
                          )
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlayState.insert(entry);
    Future.delayed(const Duration(seconds: 3), () {
      if (entry.mounted) entry.remove();
    });
  }

  Future<void> _hydrateFromFirestore(ProfileFormController ctrl) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (mounted) setState(() => _isVerified = data['isVerified'] ?? false);

        if (ref.read(profileFormProvider).nombre.isEmpty) {
          ctrl.setNombre(data['nombre'] ?? '');
          if (data['edad'] != null) ctrl.setEdad(data['edad'].toString());
          ctrl.setProfesion(data['profesion'] ?? '');
          ctrl.setBiografia(data['biografia'] ?? '');
          ctrl.setDetalle(data['detalle'] ?? '');
          ctrl.setEstatura(data['estatura'] ?? '');

          if (mounted) {
            setState(() {
              if (data['paisOrigen'] != null && data['paisOrigen'].toString().isNotEmpty) {
                _paisOrigen = data['paisOrigen'];
                _ciudadOrigen = data['ciudadOrigen'];
                ctrl.setPaisOrigen(_paisOrigen);
                ctrl.setCiudadOrigen(_ciudadOrigen);
                ctrl.setPais(data['pais']);
                ctrl.setCiudad(data['ciudad']);
                _vivoEnMiOrigen = (_paisOrigen == data['pais'] && _ciudadOrigen == data['ciudad']);
              } else {
                _paisOrigen = data['pais'];
                _ciudadOrigen = data['ciudad'];
                ctrl.setPaisOrigen(_paisOrigen);
                ctrl.setCiudadOrigen(_ciudadOrigen);
                ctrl.setPais(data['pais']);
                ctrl.setCiudad(data['ciudad']);
                _vivoEnMiOrigen = true;
              }
            });
          }

          ctrl.setGenero(data['genero'] ?? '');
          ctrl.setPreferenciaCitas(data['preferenciaCitas'] ?? 'Ambos');
          if (data['sobreMiSeleccion'] is List) {
            for (var item in data['sobreMiSeleccion']) ctrl.toggleSobreMi(item);
          }
          if (data['buscoSeleccion'] is List) {
            for (var item in data['buscoSeleccion']) ctrl.toggleBusco(item);
          }
          if (data['interesesSeleccion'] is List) {
            for (var item in data['interesesSeleccion']) ctrl.toggleInteres(item);
          }
          if (data['photoUrls'] is List) {
            final urls = List<String>.from(data['photoUrls']);
            ctrl.setFotos(urls);
          }
        }
      }
    } catch (e) { debugPrint("Error Hydrating: $e"); }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose(); _edadCtrl.dispose(); _profesionCtrl.dispose();
    _biografiaCtrl.dispose(); _detalleCtrl.dispose(); _estaturaCtrl.dispose();
    super.dispose();
  }

  bool _nombreOk(ProfileFormState s) => s.nombre.trim().isNotEmpty;
  bool _edadOk(ProfileFormState s) {
    final edadInt = int.tryParse(s.edad.trim());
    return edadInt != null && edadInt >= 18 && edadInt <= 99;
  }
  bool _origenOk() => (_paisOrigen ?? '').isNotEmpty && (_ciudadOrigen ?? '').isNotEmpty;
  bool _residenciaOk(ProfileFormState s) => _vivoEnMiOrigen ? true : (s.paisSeleccionado ?? '').trim().isNotEmpty && (s.ciudadSeleccionada ?? '').trim().isNotEmpty;
  bool _generoOk() => _genero.trim().isNotEmpty;
  bool _preferenciaOk() => _preferenciaCitas.trim().isNotEmpty;
  bool _fotosOk(ProfileFormState s) => s.photoUrls.isNotEmpty || s.fotosCargadas.isNotEmpty;

  bool _formularioValido(ProfileFormState s) {
    return _nombreOk(s) && _edadOk(s) && _origenOk() && _residenciaOk(s) && _generoOk() && _preferenciaOk() && _fotosOk(s);
  }

  Future<void> _syncProfileToFirestore(ProfileFormState s) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No hay usuario autenticado.');
    final uid = user.uid;
    final docRef = FirebaseFirestore.instance.collection('users').doc(uid);

    final payload = <String, dynamic>{
      'uid': uid,
      'email': user.email,
      'nombre': s.nombre.trim(),
      'edad': int.tryParse(s.edad.trim()),
      'profesion': s.profesion.trim(),
      'biografia': s.biografia.trim(),
      'detalle': s.detalle.trim(),
      'estatura': s.estatura.trim(),
      'paisOrigen': _paisOrigen,
      'ciudadOrigen': _ciudadOrigen,
      'pais': _vivoEnMiOrigen ? _paisOrigen : (s.paisSeleccionado ?? '').trim(),
      'ciudad': _vivoEnMiOrigen ? _ciudadOrigen : (s.ciudadSeleccionada ?? '').trim(),
      'genero': _genero,
      'preferenciaCitas': _preferenciaCitas,
      'sobreMiSeleccion': List<String>.from(s.sobreMiSeleccion),
      'buscoSeleccion': List<String>.from(s.buscoSeleccion),
      'interesesSeleccion': List<String>.from(s.interesesSeleccion),
      'onboarding_completed': true,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await docRef.set(payload, SetOptions(merge: true));
  }

  Future<void> _seleccionarEstatura(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
        context: context, backgroundColor: Colors.black87,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
        builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 10), Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20))),
          const SizedBox(height: 12), const Text('Selecciona tu estatura', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          SizedBox(height: 320, child: ListView.builder(itemCount: _estaturas.length, itemBuilder: (_, i) => ListTile(title: Text(_estaturas[i], style: const TextStyle(color: Colors.white)), onTap: () => Navigator.pop(context, _estaturas[i]))))
        ]))
    );
    if (selected != null) _estaturaCtrl.text = selected;
  }

  String _obtenerTextoChipDinamico(String base, List<String> seleccionActual) {
    if (base == '👧 Tengo hija') {
      final found = seleccionActual.where((e) => e.startsWith('👧')).toList();
      return found.isNotEmpty ? found.first : base;
    }
    if (base == '👦 Tengo hijo') {
      final found = seleccionActual.where((e) => e.startsWith('👦')).toList();
      return found.isNotEmpty ? found.first : base;
    }
    return base;
  }

  Future<void> _seleccionarCantidadHijos(BuildContext context, String baseOption, ProfileFormController ctrl, List<String> seleccionActual) async {
    final isNina = baseOption.contains('👧');
    final baseEmoji = isNina ? '👧' : '👦';
    final baseTextSingular = isNina ? 'hija' : 'hijo';
    final baseTextPlural = isNina ? 'hijas' : 'hijos';

    String? currentSelected;
    for (var s in seleccionActual) {
      if (s.startsWith(baseEmoji)) {
        currentSelected = s;
        break;
      }
    }

    final result = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20))),
            const SizedBox(height: 14),
            Text('¿Cuántos $baseTextPlural tienes?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                final num = index + 1;
                return GestureDetector(
                  onTap: () => Navigator.pop(context, num),
                  child: Container(
                    width: 50, height: 50,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: Color(0xFFBEB3FF), shape: BoxShape.circle),
                    child: Text('$num', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18)),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            if (currentSelected != null)
              TextButton(
                onPressed: () => Navigator.pop(context, 0),
                child: const Text('Quitar selección', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );

    if (result != null) {
      if (currentSelected != null) ctrl.toggleSobreMi(currentSelected);
      if (result > 0) {
        final newText = '$baseEmoji Tengo $result ${result == 1 ? baseTextSingular : baseTextPlural}';
        ctrl.toggleSobreMi(newText);
      }
    }
  }

  void _setPreferenciaCitas(ProfileFormController ctrl, String v) { setState(() => _preferenciaCitas = v); ctrl.setPreferenciaCitas(v); }
  void _setGenero(ProfileFormController ctrl, String v) { setState(() => _genero = v); ctrl.setGenero(v); }

  // ⚖️ MÉTODO: MOSTRAR VENTANA EMERGENTE DE EULA Y PRIVACIDAD
  void _mostrarVentanaLegal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFF121212),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 16),
            const Text(
              "TÉRMINOS Y CONDICIONES",
              style: TextStyle(color: Color(0xFFBEB3FF), fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: const Text(
                  """POLÍTICAS DE PRIVACIDAD, TÉRMINOS Y ESTÁNDARES DE SEGURIDAD INFANTIL Y PROTECCIÓN AL MENOR. 

POLÍTICA DE PRIVACIDAD Y TÉRMINOS DE USO – MATCHY
Fecha de entrada en vigor: 27 de febrero de 2026
Sitio Web Oficial: www.matchyapp.co

El presente documento establece las Políticas de Privacidad y los Términos y Condiciones de Uso de la aplicación móvil Matchy (en adelante, "la Aplicación", "la Plataforma" o "Matchy"). Al descargar, instalar, registrarse o utilizar Matchy, el usuario (en adelante, "el Usuario") acepta de manera expresa, voluntaria e inequívoca acepta expresamente las disposiciones descritas. 

PARTE I: POLÍTICA DE PRIVACIDAD
Esta Política de Privacidad describe cómo recopilamos, utilizamos, procesamos y protegemos la información personal del Usuario, en estricto cumplimiento de los lineamientos de Google Play y las normativas de protección de datos aplicables, incluyendo la Ley Estatutaria 1581 de 2012 de la República de Colombia.

1. Información que Recopilamos
Para proporcionar y optimizar nuestros servicios, recopilamos las siguientes categorías de datos:
• Datos de Registro y Perfil: Nombre, fecha de nacimiento (para validar la mayoría de edad), género, orientación sexual, preferencias de citas, fotografías subidas voluntariamente, biografía e intereses.
• Datos de Ubicación (GPS): Recopilamos datos de ubicación precisa del dispositivo.
Justificación: Esta información es estrictamente necesaria para la funcionalidad principal de Matchy, la cual consiste en validar mediante geolocalización la asistencia en tiempo real del Usuario a los establecimientos aliados donde se han programado sus citas.
• Datos de Dispositivo y Uso: Modelo del dispositivo, sistema operativo, dirección IP, interacciones dentro de la app (matches, mensajes, reportes) y registros de fallos (crash logs).

2. Uso de la Información
Los datos se utilizan exclusivamente para:
• Operar y mejorar la Plataforma.
• Facilitar el emparejamiento ("matching") basado en preferencias.
• Verificar la asistencia a las citas mediante la validación del GPS.
• Aplicar el sistema de penalizaciones ("strikes") y calcular el puntaje de confiabilidad.
• Garantizar la seguridad de la comunidad y prevenir el fraude.

3. Integración con Servicios de Terceros
Matchy no vende ni comercializa los datos personales de los Usuarios. Compartimos información de forma segura únicamente con:
• Google Play Services: Para métricas y funcionamiento del sistema.
• Firebase (Google): Para autenticación segura, base de datos (Cloud Firestore) y almacenamiento de imágenes (Storage).

4. Seguridad de los Datos
Implementamos medidas de encriptado de datos en tránsito y en reposo mediante la infraestructura de Google Cloud/Firebase para proteger la información contra acceso no autorizado.

5. Retención y Eliminación de Datos
El Usuario tiene el derecho absoluto de solicitar la eliminación de su cuenta y todos los datos asociados:
• Desde la App: Sección de Configuración de Perfil > "Eliminar Cuenta".
• Por Correo: Enviando una solicitud a contacto@matchyapp.co.
Una vez confirmada, los datos (incluyendo fotos y registros) serán borrados permanentemente de nuestros servidores, salvo registros mínimos obligatorios por ley o para mantener bloqueos por infracciones graves de seguridad.

PARTE II: TÉRMINOS Y CONDICIONES DE USO

1. Requisito Estricto de Edad (Mayores de 18 años)
El uso de Matchy está restringido exclusivamente a personas mayores de 18 años. Si detectamos un perfil de un menor de edad, la cuenta será eliminada de inmediato y sin previo aviso.

2. Limitación de Responsabilidad (Interacciones Offline)
Matchy actúa como una herramienta tecnológica para facilitar la conexión virtual y sugerir lugares de encuentro.
• Exención de responsabilidad: Matchy NO realiza verificaciones de antecedentes penales ni evaluaciones psicológicas.
• Asunción de Riesgo: Los encuentros presenciales se realizan bajo el propio y exclusivo riesgo del Usuario. Matchy no asume responsabilidad civil o penal por cualquier daño, lesión o altercado resultante de la conducta de los Usuarios fuera de la aplicación.

3. Exención de Responsabilidad sobre Establecimientos Aliados
Cualquier incidente ocurrido dentro de los establecimientos sugeridos (restaurantes, bares, sedes físicas) es responsabilidad exclusiva del local comercial. Matchy no tiene control sobre la calidad del servicio, seguridad o infraestructura de estos terceros.

4. Sistema de Comportamiento y Strikes
Matchy se reserva el derecho de suspender o bloquear permanentemente cualquier cuenta que:
• Proporcione información falsa o suplante identidad.
• Incurra en acoso, lenguaje de odio o spam.
• Acumule penalizaciones por inasistencia reiterada a citas programadas ("Sistema de Strikes").

5. Legislación y Jurisdicción
Estos términos se rigen por las leyes de la República de Colombia. Cualquier controversia será sometida a los tribunales competentes en territorio colombiano.

6. Contacto Oficial
Para asuntos legales, ejercicio de derechos de Habeas Data o soporte técnico:
• Correo electrónico: contacto@matchyapp.co
• Sitio Web: www.matchyapp.co

PARTE lll: ESTÁNDARES DE SEGURIDAD INFANTIL Y PROTECCIÓN AL MENOR.
Fecha de entrada en vigor: 1 de marzo de 2026.

En Matchy, operada bajo la premisa de "El que invita paga", nuestra prioridad absoluta es la creación de un entorno seguro, respetuoso y libre de cualquier forma de explotación. Estos estándares detallan nuestras políticas de tolerancia cero y los mecanismos técnicos implementados para la protección de menores de edad.

1. RESTRICCIÓN ESTRICTA DE EDAD (MAYORES DE 18 AÑOS)
Matchy es una plataforma diseñada exclusivamente para adultos.
• Autenticación Obligatoria: Para garantizar la integridad de nuestra comunidad, Matchy solo permite el acceso mediante Google Sign-In. Esto nos permite utilizar las capas de verificación de identidad de Google como un primer filtro de seguridad.
• Prohibición de Menores: El registro o uso de la aplicación por parte de personas menores de 18 años está estrictamente prohibido. Cualquier cuenta que se sospeche pertenece a un menor será suspendida de forma inmediata y permanente.

2. POLÍTICA DE TOLERANCIA CERO (EASI y CSAM)
De acuerdo con la Ley 679 de 2001 (Colombia) y los estándares internacionales de protección, Matchy mantiene una postura de tolerancia cero frente a:
• Explotación y Abuso Sexual Infantil (EASI): Prohibimos cualquier contenido, mensaje o conducta que promueva, facilite o sugiera el abuso sexual de menores.
• Material de Abuso Sexual Infantil (CSAM): El intercambio o posesión de imágenes o videos de abuso infantil resultará en la expulsión inmediata y la denuncia ante las autoridades pertinentes.

3. HERRAMIENTAS DE SEGURIDAD Y CONTROL DEL USUARIO
Hemos diseñado herramientas específicas dentro de la interfaz de Matchy para que nuestros usuarios sean la primera línea de defensa:
• Botón "Eliminar Matchy": Ubicado en el detalle de cada conexión, permite romper cualquier vínculo de forma instantánea, eliminando historiales y previniendo futuros contactos en caso de comportamiento inapropiado.
• Botón de Soporte y Denuncia: En la sección de Perfil, los usuarios tienen acceso directo al botón de "Contáctanos", donde pueden reportar perfiles sospechosos o conductas violatorias de estos estándares.
• Bloqueos Proactivos: Implementamos un sistema de "Strikes" y bloqueos temporales o permanentes basados en el puntaje de confiabilidad del usuario para sancionar conductas que pongan en riesgo la seguridad de la comunidad.

4. COOPERACIÓN CON LAS AUTORIDADES
Matchy cumple rigurosamente con el Artículo 4 de la Ley 679 de 2001:
• Reporte Obligatorio: Informaremos de manera proactiva a la Policía Nacional de Colombia, al ICBF y a organismos internacionales sobre cualquier actividad detectada que involucre la explotación sexual de menores.
• Preservación de Datos: Cooperaremos con las autoridades judiciales proporcionando la información necesaria para la investigación de delitos contra la infancia.

5. CONTACTO OFICIAL DE SEGURIDAD
Si tienes conocimiento de alguna violación a estos estándares o necesitas reportar una situación de riesgo, comunícate inmediatamente con nuestro equipo de seguridad:
• Correo Electrónico: contacto@matchyapp.co.
• Canal Interno: Sección "Contáctanos" dentro de tu Perfil en la aplicación.""",
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5, fontFamily: 'Poppins'),
                  textAlign: TextAlign.justify,
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, -5))],
              ),
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFBEB3FF), Color(0xFF8A80CC)]),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  alignment: Alignment.center,
                  child: const Text('ENTENDIDO Y CERRAR', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileFormProvider);
    final ctrl = ref.read(profileFormProvider.notifier);

    const Map<String, List<String>> grandesCiudadesPorPais = {
      'Colombia': ['Cali', 'Bogotá', 'Medellín', 'Barranquilla', 'Cartagena', 'Bucaramanga', 'Pereira', 'Manizales', 'Armenia', 'Cúcuta', 'Ibagué', 'Santa Marta', 'Villavicencio', 'Pasto', 'Montería', 'Neiva'],
      'Argentina': ['Buenos Aires', 'Córdoba', 'Rosario', 'Mendoza', 'Tucumán', 'La Plata', 'Mar del Plata', 'Salta'],
      'Bolivia': ['La Paz', 'Santa Cruz de la Sierra', 'Cochabamba', 'Sucre'],
      'Brasil': ['São Paulo', 'Río de Janeiro', 'Brasilia', 'Salvador', 'Fortaleza', 'Belo Horizonte', 'Curitiba', 'Manaos'],
      'Chile': ['Santiago', 'Valparaíso', 'Concepción', 'La Serena', 'Antofagasta', 'Temuco', 'Rancagua'],
      'Ecuador': ['Quito', 'Guayaquil', 'Cuenca', 'Santo Domingo', 'Machala'],
      'Paraguay': ['Asunción', 'Ciudad del Este', 'Encarnación'],
      'Perú': ['Lima', 'Arequipa', 'Trujillo', 'Chiclayo', 'Piura', 'Iquitos', 'Cusco', 'Huancayo'],
      'Uruguay': ['Montevideo', 'Punta del Este', 'Salto'],
      'Venezuela': ['Caracas', 'Maracaibo', 'Valencia', 'Barquisimeto', 'Maracay', 'San Cristóbal', 'Mérida'],
      'México': ['Ciudad de México', 'Guadalajara', 'Monterrey', 'Puebla', 'Tijuana', 'Toluca', 'Cancún', 'Mérida', 'Querétaro', 'León'],
      'Costa Rica': ['San José', 'Alajuela', 'Cartago', 'Heredia', 'Puntarenas'],
      'Cuba': ['La Habana', 'Santiago de Cuba', 'Camagüey'],
      'El Salvador': ['San Salvador', 'Santa Ana', 'San Miguel'],
      'Guatemala': ['Ciudad de Guatemala', 'Quetzaltenango', 'Antigua Guatemala'],
      'Honduras': ['Tegucigalpa', 'San Pedro Sula', 'La Ceiba'],
      'Nicaragua': ['Managua', 'León', 'Granada'],
      'Panamá': ['Ciudad de Panamá', 'San Miguelito', 'David', 'Colón'],
      'Puerto Rico': ['San Juan', 'Bayamón', 'Ponce', 'Carolina'],
      'República Dominicana': ['Santo Domingo', 'Santiago de los Caballeros', 'Punta Cana'],
      'Estados Unidos': ['Miami', 'Nueva York', 'Los Ángeles', 'Chicago', 'Houston', 'Phoenix', 'San Antonio', 'San Diego', 'Dallas', 'Orlando', 'Las Vegas', 'San Francisco', 'Seattle'],
      'Canadá': ['Toronto', 'Vancouver', 'Montreal', 'Calgary', 'Ottawa', 'Edmonton', 'Quebec'],
      'España': ['Madrid', 'Barcelona', 'Valencia', 'Sevilla', 'Zaragoza', 'Málaga', 'Murcia', 'Palma', 'Las Palmas', 'Bilbao'],
      'Alemania': ['Berlín', 'Múnich', 'Fráncfort', 'Hamburgo', 'Colonia'],
      'Francia': ['París', 'Marsella', 'Lyon', 'Toulouse', 'Niza'],
      'Italia': ['Roma', 'Milán', 'Nápoles', 'Turín', 'Florencia'],
      'Reino Unido': ['Londres', 'Mánchester', 'Birmingham', 'Edimburgo', 'Glasgow'],
      'Portugal': ['Lisboa', 'Oporto', 'Faro', 'Braga'],
      'Países Bajos': ['Ámsterdam', 'Róterdam', 'La Haya', 'Utrecht'],
      'Suiza': ['Zúrich', 'Ginebra', 'Basilea', 'Berna']
    };

    final List<String> todosLosPaises = grandesCiudadesPorPais.keys.toList();
    todosLosPaises.sort();

    final List<String> ciudadesOrigen = _paisOrigen != null ? List<String>.from(grandesCiudadesPorPais[_paisOrigen!] ?? []) : [];
    if (ciudadesOrigen.isNotEmpty) ciudadesOrigen.sort();

    final String? paisOrigenSafe = todosLosPaises.contains(_paisOrigen) ? _paisOrigen : null;
    final String? ciudadOrigenSafe = ciudadesOrigen.contains(_ciudadOrigen) ? _ciudadOrigen : null;

    final List<String> ciudades = state.paisSeleccionado != null ? List<String>.from(grandesCiudadesPorPais[state.paisSeleccionado!] ?? []) : [];
    if (ciudades.isNotEmpty) ciudades.sort();

    final String? paisSafe = todosLosPaises.contains(state.paisSeleccionado) ? state.paisSeleccionado : null;
    final String? ciudadSafe = ciudades.contains(state.ciudadSeleccionada) ? state.ciudadSeleccionada : null;

    const List<List<String>> sobreMiOpciones = [
      ['💬 Soltero', '❤️ En una relación'],
      ['👶 Con hijo', '🙅‍♂️ Sin hijo'],
      ['👧 Tengo hija', '👦 Tengo hijo'],
      ['🚬 Fumo', '🚭 No fumo'],
      ['🍷 Tomo', '🚫 No tomo'],
      ['🐶 Perros', '🐱 Gatos']
    ];

    const List<String> buscoOpciones = ['💞 Relación estable', '🎉 Citas divertidas', '💬 Conversación', '👫 Amistad', '🌍 Conocer gente nueva', '🔥 Aventura', '💍 Pareja a largo plazo', '👀 Algo casual', '🎶 Compartir gustos', '✈️ Viajar juntos'];
    const List<String> signosOpciones = ['♈ Aries', '♉ Tauro', '♊ Géminis', '♋ Cáncer', '♌ Leo', '♍ Virgo', '♎ Libra', '♏ Escorpio', '♐ Sagitario', '♑ Capricornio', '♒ Acuario', '♓ Piscis'];
    const List<String> interesesOpciones = ['🎬 Cine','🎵 Música','✈️ Viajar','📖 Lectura','☕ Café','🏃‍♂️ Running','🏋️ Gimnasio','🌄 Senderismo','🍷 Vino','🎨 Arte','🎮 Videojuegos','📸 Fotografía','🍳 Cocina','🏖️ Playa','🎭 Teatro','💃 Bailar','🎤 Cantar','🧘 Yoga','🧠 Filosofía','💼 Emprender','💻 Tecnología','💅 Moda','📺 Series','🎙️ Podcasts','🌿 Naturaleza','🏕️ Camping','⚽ Fútbol','🏀 Baloncesto','🚴‍♂️ Ciclismo','🏔️ Escalada','🐠 Buceo','🎯 Juegos de mesa','💫 Astrología','🐾 Voluntariado','🧑‍🍳 Comida gourmet','🎲 Rol','💌 Escritura','📷 Youtube','🌙 Noche','☀️ Amaneceres','🌇 Atardeceres','💃 Salsa','🎧 DJ','🎁 Regalos','🍕 Pizza','🥂 Brindar','📚 Manga','🌌 Meditar','💡 Innovar','🤟 Rock','🎫 Conciertos','⚡ Adrenalina','🏅 Deportes','🎭 Cosplay','🐾 Animalismo','📺 Streaming'];

    if (_isLoadingCloudData) return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Color(0xFFBEB3FF))));

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover)),
          Column(
            children: [
              const SizedBox(height: 35),
              Image.asset('assets/images/logomatchyplano.png', height: 50),
              const SizedBox(height: 15),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      FittedBox(fit: BoxFit.scaleDown, child: const Text('EDITA TU PERFIL', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.0, shadows: kTextShadow))),
                      const SizedBox(height: 24),
                      _buildTextField(label: 'Nombre *', controller: _nombreCtrl, showError: _mostrarErrores && !_nombreOk(state)),
                      const SizedBox(height: 14),
                      _buildTextField(label: 'Edad *', controller: _edadCtrl, keyboardType: TextInputType.number, showError: _mostrarErrores && !_edadOk(state)),
                      const SizedBox(height: 6),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text('Debes ser mayor de edad (18 años o más) para usar Matchy.', style: TextStyle(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic)),
                      ),
                      const SizedBox(height: 14),
                      _buildTextField(label: 'Profesión', controller: _profesionCtrl),
                      const SizedBox(height: 14),
                      _buildTextField(label: 'Biografía', controller: _biografiaCtrl, maxLines: 4),
                      const SizedBox(height: 14),
                      _buildTextField(label: 'Un detalle que me enamora', controller: _detalleCtrl, maxLines: 3),
                      const SizedBox(height: 14),
                      GestureDetector(onTap: () => _seleccionarEstatura(context), child: AbsorbPointer(child: _buildTextField(label: 'Estatura (selección)', controller: _estaturaCtrl, suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.white)))),
                      const SizedBox(height: 25),

                      Text('MIS RAÍCES (De dónde soy) *', style: const TextStyle(color: Color(0xFFBEB3FF), fontSize: kChincheTituloSeccion, fontWeight: FontWeight.w900, shadows: kTextShadow)),
                      const SizedBox(height: 15),
                      _buildPaisCiudadOrigenSection(
                          paisSeleccionado: paisOrigenSafe,
                          ciudadSeleccionada: ciudadOrigenSafe,
                          paises: todosLosPaises,
                          ciudades: ciudadesOrigen,
                          showError: _mostrarErrores && !_origenOk(),
                          onPaisChanged: (v) {
                            setState(() {
                              _paisOrigen = v;
                              _ciudadOrigen = null;
                              ctrl.setPaisOrigen(v);
                              ctrl.setCiudadOrigen(null);
                              if (_vivoEnMiOrigen) {
                                ctrl.setPais(v);
                                ctrl.setCiudad(null);
                              }
                            });
                          },
                          onCiudadChanged: (v) {
                            setState(() {
                              _ciudadOrigen = v;
                              ctrl.setCiudadOrigen(v);
                              if (_vivoEnMiOrigen) ctrl.setCiudad(v);
                            });
                          }
                      ),
                      const SizedBox(height: 10),

                      Theme(
                        data: ThemeData(unselectedWidgetColor: Colors.white54),
                        child: CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          activeColor: const Color(0xFFBEB3FF),
                          checkColor: Colors.black,
                          title: const Text('📍 Actualmente vivo en mi ciudad de origen', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                          value: _vivoEnMiOrigen,
                          onChanged: (bool? value) {
                            setState(() {
                              _vivoEnMiOrigen = value ?? false;
                              if (_vivoEnMiOrigen) {
                                ctrl.setPais(_paisOrigen);
                                ctrl.setCiudad(_ciudadOrigen);
                              }
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ),
                      const SizedBox(height: 15),

                      if (!_vivoEnMiOrigen) ...[
                        Text('¿DÓNDE ESTÁS AHORA? *', style: const TextStyle(color: Color(0xFFBEB3FF), fontSize: kChincheTituloSeccion, fontWeight: FontWeight.w900, shadows: kTextShadow)),
                        const SizedBox(height: 15),
                        _buildPaisCiudadSection(
                            paisSeleccionado: paisSafe,
                            ciudadSeleccionada: ciudadSafe,
                            paises: todosLosPaises,
                            ciudades: ciudades,
                            showPaisError: _mostrarErrores && !_residenciaOk(state) && (state.paisSeleccionado ?? '').isEmpty,
                            showCiudadError: _mostrarErrores && !_residenciaOk(state) && (state.ciudadSeleccionada ?? '').isEmpty,
                            onPaisChanged: (v) => ctrl.setPais(v),
                            onCiudadChanged: (v) => ctrl.setCiudad(v)
                        ),
                        const SizedBox(height: 30),
                      ],

                      Align(alignment: Alignment.centerLeft, child: Text('GÉNERO *', style: TextStyle(color: (_mostrarErrores && !_generoOk()) ? Colors.redAccent : Colors.white70, fontWeight: FontWeight.bold, fontSize: kChincheTituloSeccion))),
                      const SizedBox(height: 10),
                      _GeneroSelector(value: _genero, showError: _mostrarErrores && !_generoOk(), onChanged: _saving ? null : (v) => _setGenero(ctrl, v)),
                      const SizedBox(height: 25),
                      Align(alignment: Alignment.centerLeft, child: Text('PREFERENCIA DE CITAS *', style: TextStyle(color: (_mostrarErrores && !_preferenciaOk()) ? Colors.redAccent : Colors.white70, fontWeight: FontWeight.bold, fontSize: kChincheTituloSeccion))),
                      const SizedBox(height: 10),
                      _PreferenciaCitasSelector(value: _preferenciaCitas, onChanged: _saving ? null : (v) => _setPreferenciaCitas(ctrl, v)),
                      const SizedBox(height: 30),

                      FittedBox(fit: BoxFit.scaleDown, child: Text('TUS FOTOS (MÁX 5) *', style: TextStyle(color: _mostrarErrores && !_fotosOk(state) ? Colors.redAccent : Colors.white, fontSize: kChincheTituloSeccion, fontWeight: FontWeight.w900))),
                      const SizedBox(height: 15),
                      const GestorFotosWidget(),
                      const SizedBox(height: 24),

                      if (!_isVerified) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Icon(Icons.verified, color: Color(0xFF00B4DB), size: 28),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "¡Destaca en el radar! Los perfiles con Check Azul generan confianza instantánea y al demostrar que eres 100% real multiplica tus citas exitosas. Se comparará con tu foto de perfil actual.",
                                  style: TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Poppins', height: 1.3, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                        GestureDetector(
                          onTap: () async {
                            if (!state.photoUrls.isNotEmpty && !state.fotosCargadas.isNotEmpty) {
                              _mostrarBurbuja("Sube tu foto de perfil principal antes de verificar tu identidad.", Colors.orangeAccent, Icons.photo_camera_front_rounded);
                              return;
                            }
                            final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const VerificacionScreen()));
                            if (result == true && mounted) {
                              setState(() => _isVerified = true);
                            }
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.85,
                            height: 55,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF00B4DB), Color(0xFF0083B0)]),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: kChipShadow,
                            ),
                            alignment: Alignment.center,
                            child: const Text('VERIFICA TU PERFIL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.0)),
                          ),
                        ),
                      ] else ...[
                        Container(
                          width: MediaQuery.of(context).size.width * 0.85,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF040E1B).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: const Color(0xFF07013E).withOpacity(0.5)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.verified, color: Color(0xFF1664DA), size: 22),
                              SizedBox(width: 8),
                              Text('TU PERFIL ESTÁ VERIFICADO', style: TextStyle(color: Color(
                                  0xFFFFFFFF), fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.0)),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 40),

                      Text('SOBRE MÍ', style: const TextStyle(color: Color(0xFFBEB3FF), fontSize: kChincheTituloSeccion, fontWeight: FontWeight.w900, shadows: kTextShadow)),
                      const SizedBox(height: 10),

                      Column(
                        children: sobreMiOpciones.map((grupo) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(children: grupo.map((opcion) {
                              final textoMostrar = (opcion == '👧 Tengo hija' || opcion == '👦 Tengo hijo') ? _obtenerTextoChipDinamico(opcion, state.sobreMiSeleccion) : opcion;
                              final sel = state.sobreMiSeleccion.contains(textoMostrar);
                              return Expanded(
                                  child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: GestureDetector(
                                          onTap: _saving ? null : () {
                                            if (opcion == '👧 Tengo hija' || opcion == '👦 Tengo hijo') {
                                              _seleccionarCantidadHijos(context, opcion, ctrl, state.sobreMiSeleccion);
                                            } else {
                                              ctrl.toggleSobreMi(opcion);
                                            }
                                          },
                                          child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              decoration: BoxDecoration(color: sel ? const Color(0xFFBEB3FF) : const Color(0x1FFFFFFF), borderRadius: BorderRadius.circular(20), boxShadow: kChipShadow, border: Border.all(color: sel ? Colors.transparent : Colors.white12)),
                                              child: Text(textoMostrar, textAlign: TextAlign.center, style: TextStyle(color: sel ? Colors.black : Colors.white, fontSize: 13, fontWeight: FontWeight.w600))
                                          )
                                      )
                                  )
                              );
                            }).toList())
                        )).toList(),
                      ),

                      const SizedBox(height: 45),
                      _SeccionBotonesChipsSimetricos(titulo: 'BUSCO...', opciones: buscoOpciones, seleccionActual: state.buscoSeleccion, onToggle: (op) => _saving ? null : ctrl.toggleBusco(op)),
                      const SizedBox(height: 45),

                      _SeccionBotonesChipsSimetricos(titulo: 'SIGNO ZODIACAL', opciones: signosOpciones, seleccionActual: state.sobreMiSeleccion, onToggle: (op) => _saving ? null : ctrl.toggleSobreMi(op)),
                      const SizedBox(height: 45),

                      _SeccionBotonesChipsSimetricos(titulo: 'INTERESES Y HOBBIES', opciones: interesesOpciones, seleccionActual: state.interesesSeleccion, onToggle: (op) => _saving ? null : ctrl.toggleInteres(op)),
                      const SizedBox(height: 40),

                      GestureDetector(
                        onTap: _saving ? null : () async {
                          if (_formularioValido(ref.read(profileFormProvider))) {
                            setState(() => _saving = true);
                            try {
                              await _syncProfileToFirestore(ref.read(profileFormProvider));
                              await ctrl.saveDraft(); await ctrl.publishProfile(); await ctrl.setOnboardingCompleted(true);
                              PaintingBinding.instance.imageCache.clear(); PaintingBinding.instance.imageCache.clearLiveImages();
                              if (!mounted) return;
                              Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const PanelScreen()), (route) => false);
                            } catch (e) {
                              if (mounted) _mostrarBurbuja('Error al guardar: $e', const Color(0xFFFF5252), Icons.error_outline_rounded);
                            }
                            finally { if (mounted) setState(() => _saving = false); }
                          } else {
                            setState(() => _mostrarErrores = true);
                            final edadStr = ref.read(profileFormProvider).edad.trim();
                            final edadInt = int.tryParse(edadStr);
                            if (edadStr.isNotEmpty && edadInt != null && edadInt < 18) {
                              _mostrarBurbuja("Acceso denegado: Debes tener al menos 18 años para usar Matchy.", const Color(0xFFFF5252), Icons.block_flipped);
                            } else {
                              _mostrarBurbuja("Faltan datos obligatorios. Por favor revisa los campos en rojo.", const Color(0xFFFF5252), Icons.error_outline_rounded);
                            }
                          }
                        },
                        child: Container(width: MediaQuery.of(context).size.width * 0.7, height: 55, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFBEB3FF), Color(0xFF8A80CC)]), borderRadius: BorderRadius.circular(30), boxShadow: kChipShadow), alignment: Alignment.center, child: _saving ? const CircularProgressIndicator(color: Colors.black) : const Text('GUARDAR PERFIL', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16))),
                      ),

                      const SizedBox(height: 20),

                      // ⚖️ BOTÓN EULA (NUEVO)
                      GestureDetector(
                        onTap: () => _mostrarVentanaLegal(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.gavel_rounded, color: Colors.white54, size: 18),
                              SizedBox(width: 8),
                              Text(
                                "TÉRMINOS Y CONDICIONES (EULA)",
                                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(bottom: 0, left: 0, right: 0, height: 100, child: IgnorePointer(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.9)]))))),
          const MatchyBackButton(top: 10, left: 16),
        ],
      ),
    );
  }

  Widget _buildTextField({required String label, required TextEditingController controller, int maxLines = 1, TextInputType? keyboardType, bool showError = false, Widget? suffixIcon}) {
    return Container(
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(15), border: Border.all(color: showError ? Colors.redAccent : Colors.white12)),
      child: TextField(
        controller: controller, maxLines: maxLines, keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: kChincheTextoInput),
        decoration: InputDecoration(labelText: label, labelStyle: TextStyle(color: showError ? Colors.redAccent : Colors.white60, fontSize: kChincheLabelInput), contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), border: InputBorder.none, suffixIcon: suffixIcon),
      ),
    );
  }

  Widget _buildPaisCiudadOrigenSection({required String? paisSeleccionado, required String? ciudadSeleccionada, required List<String> paises, required List<String> ciudades, required ValueChanged<String?> onPaisChanged, required ValueChanged<String?> onCiudadChanged, required bool showError}) {
    final bool errPais = showError && (paisSeleccionado ?? '').isEmpty;
    final bool errCiudad = showError && (ciudadSeleccionada ?? '').isEmpty;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('PAÍS DE ORIGEN', style: TextStyle(color: errPais ? Colors.redAccent : Colors.white70, fontWeight: FontWeight.bold, fontSize: kChincheLabelInput)),
      const SizedBox(height: 8),
      Container(padding: const EdgeInsets.symmetric(horizontal: 15), decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(15), border: Border.all(color: errPais ? Colors.redAccent : Colors.white12)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(hint: const Text('Selecciona tu país de origen', style: TextStyle(color: Colors.white38)), value: paisSeleccionado, dropdownColor: const Color(0xFF222222), iconEnabledColor: Colors.white, isExpanded: true, style: const TextStyle(color: Colors.white, fontSize: kChincheTextoInput), items: paises.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(), onChanged: onPaisChanged))),
      const SizedBox(height: 20),
      Text('CIUDAD DE ORIGEN', style: TextStyle(color: errCiudad ? Colors.redAccent : Colors.white70, fontWeight: FontWeight.bold, fontSize: kChincheLabelInput)),
      const SizedBox(height: 8),
      Container(padding: const EdgeInsets.symmetric(horizontal: 15), decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(15), border: Border.all(color: errCiudad ? Colors.redAccent : Colors.white12)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(hint: const Text('Selecciona tu ciudad de origen', style: TextStyle(color: Colors.white38)), value: ciudadSeleccionada, dropdownColor: const Color(0xFF222222), iconEnabledColor: Colors.white, isExpanded: true, style: const TextStyle(color: Colors.white, fontSize: kChincheTextoInput), items: ciudades.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: onCiudadChanged))),
    ]);
  }

  Widget _buildPaisCiudadSection({required String? paisSeleccionado, required String? ciudadSeleccionada, required List<String> paises, required List<String> ciudades, required ValueChanged<String?> onPaisChanged, required ValueChanged<String?> onCiudadChanged, required bool showPaisError, required bool showCiudadError}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('PAÍS *', style: TextStyle(color: showPaisError ? Colors.redAccent : Colors.white70, fontWeight: FontWeight.bold, fontSize: kChincheLabelInput)),
      const SizedBox(height: 8),
      Container(padding: const EdgeInsets.symmetric(horizontal: 15), decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(15), border: Border.all(color: showPaisError ? Colors.redAccent : Colors.white12)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: paisSeleccionado, dropdownColor: const Color(0xFF222222), iconEnabledColor: Colors.white, isExpanded: true, style: const TextStyle(color: Colors.white, fontSize: kChincheTextoInput), items: paises.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(), onChanged: onPaisChanged))),
      const SizedBox(height: 20),
      Text('CIUDAD *', style: TextStyle(color: showCiudadError ? Colors.redAccent : Colors.white70, fontWeight: FontWeight.bold, fontSize: kChincheLabelInput)),
      const SizedBox(height: 8),
      Container(padding: const EdgeInsets.symmetric(horizontal: 15), decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(15), border: Border.all(color: showCiudadError ? Colors.redAccent : Colors.white12)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: ciudadSeleccionada, dropdownColor: const Color(0xFF222222), iconEnabledColor: Colors.white, isExpanded: true, style: const TextStyle(color: Colors.white, fontSize: kChincheTextoInput), items: ciudades.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: onCiudadChanged))),
    ]);
  }
}

class _GeneroSelector extends StatelessWidget {
  final String value; final ValueChanged<String>? onChanged; final bool showError;
  const _GeneroSelector({required this.value, required this.onChanged, required this.showError});
  @override Widget build(BuildContext context) {
    final opciones = [{'label': 'Hombre', 'value': 'Hombre'}, {'label': 'Mujer', 'value': 'Mujer'}, {'label': 'Otro', 'value': 'Otro'}, {'label': 'No decir', 'value': 'NoDecir'}];
    return Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: opciones.map((op) {
      final bool sel = op['value'] == value;
      return GestureDetector(onTap: onChanged == null ? null : () => onChanged!(op['value']!), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: sel ? const Color(0xFFBEB3FF) : const Color(0x1FFFFFFF), borderRadius: BorderRadius.circular(50), boxShadow: _DatosScreenState.kChipShadow, border: showError && !sel && value.isEmpty ? Border.all(color: Colors.redAccent) : null), child: Text(op['label']!, style: TextStyle(color: sel ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 13))));
    }).toList());
  }
}

class _PreferenciaCitasSelector extends StatelessWidget {
  final String value; final ValueChanged<String>? onChanged;
  const _PreferenciaCitasSelector({required this.value, required this.onChanged});
  @override Widget build(BuildContext context) {
    const opciones = ['Hombres', 'Mujeres', 'Ambos'];
    return Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: opciones.map((op) {
      final bool sel = op == value;
      return GestureDetector(onTap: onChanged == null ? null : () => onChanged!(op), child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), decoration: BoxDecoration(color: sel ? const Color(0xFFBEB3FF) : const Color(0x1FFFFFFF), borderRadius: BorderRadius.circular(50), boxShadow: _DatosScreenState.kChipShadow), child: Text(op, style: TextStyle(color: sel ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 13))));
    }).toList());
  }
}

class _SeccionBotonesChipsSimetricos extends StatelessWidget {
  final String titulo; final List<String> opciones; final List<String> seleccionActual; final ValueChanged<String> onToggle;
  const _SeccionBotonesChipsSimetricos({required this.titulo, required this.opciones, required this.seleccionActual, required this.onToggle});

  List<List<String>> _chunk(List<String> list, int size) {
    final List<List<String>> chunks = [];
    for (var i = 0; i < list.length; i += size) {
      chunks.add(list.sublist(i, i + size > list.length ? list.length : i + size));
    }
    return chunks;
  }

  @override Widget build(BuildContext context) {
    final chunks = _chunk(opciones, 2);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(titulo, style: const TextStyle(color: Color(0xFFBEB3FF), fontSize: 18, fontWeight: FontWeight.w900, shadows: _DatosScreenState.kTextShadow)),
      const SizedBox(height: 12),
      Column(children: chunks.map((fila) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: fila.map((opcion) { final sel = seleccionActual.contains(opcion); return Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: GestureDetector(onTap: () => onToggle(opcion), child: Container(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8), decoration: BoxDecoration(color: sel ? const Color(0xFFBEB3FF) : const Color(0x1FFFFFFF), borderRadius: BorderRadius.circular(20), boxShadow: _DatosScreenState.kChipShadow, border: Border.all(color: sel ? Colors.transparent : Colors.white12)), child: Center(child: Text(opcion, textAlign: TextAlign.center, softWrap: true, style: TextStyle(color: sel ? Colors.black : Colors.white, fontSize: 12, fontWeight: FontWeight.w600))))))); }).toList()))).toList())
    ]);
  }
}