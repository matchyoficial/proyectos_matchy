// 📂 lib/data/lugares_catalogo.dart
// ✅ Catálogo LOCAL centralizado (ETAPA 1)
// ✅ En ETAPA 2 esto se reemplaza por Firebase/Backend sin tocar UI

import 'package:proyectos_matchy/models/lugar_data.dart';

class LugaresCatalogo {
  // ===========================================================
  // 🔴 CHINCHE DATA 1 — RESTAURANTES
  // ===========================================================
  static const List<LugarData> restaurantes = [
    LugarData(
      id: 'faro',
      nombre: 'EL FARO PIZZERIA',
      direccion: 'Carrera 66 #5-152',
      bio:
      'El Faro Pizzería, fundada en el 2003 brinda una programación especial todos los días. '
          'Es el lugar perfecto para disfrutar buena música, amigos y una excelente pizza.',
      fotos: [
        'assets/images/faro1.jpg',
        'assets/images/faro2.jpg',
        'assets/images/faro3.jpg',
        'assets/images/faro4.jpg',
      ],
      menuPdf: 'faro_pdf.pdf',
      mapsQuery: 'Carrera 66 #5-152, Cali',
    ),
    LugarData(
      id: 'playita',
      nombre: 'LA PLAYITA',
      direccion: 'Carrera 80 #45-22',
      bio: 'Comida de mar con sabor tradicional y ambiente familiar.',
      fotos: ['assets/images/restaurante2.jpg'],
      menuPdf: 'playita_pdf.pdf',
    ),
    LugarData(
      id: 'mrwok',
      nombre: 'MR WOK CHINO',
      direccion: 'Carrera 54 #24-67',
      bio: 'Cocina oriental rápida, fresca y sabrosa.',
      fotos: ['assets/images/restaurante3.jpg'],
      menuPdf: 'mrwok_pdf.pdf',
    ),
    LugarData(
      id: 'burgerhouse',
      nombre: 'BURGER HOUSE',
      direccion: 'Calle 15 #100-45',
      bio: 'Hamburguesas artesanales con ingredientes premium.',
      fotos: ['assets/images/restaurante4.jpg'],
      menuPdf: 'burgerhouse_pdf.pdf',
    ),
  ];

  // ===========================================================
  // 🔴 CHINCHE DATA 2 — BARES
  // ===========================================================
  static const List<LugarData> bares = [
    LugarData(
      id: 'bar_la_noche',
      nombre: 'BAR LA NOCHE',
      direccion: 'Calle 5 #10-23',
      bio: 'Un clásico nocturno para buena música y encuentros.',
      fotos: ['assets/images/bar1.jpg'],
      menuPdf: 'barlanoche_pdf.pdf',
    ),
    LugarData(
      id: 'rumba_room',
      nombre: 'RUMBA ROOM',
      direccion: 'Av. Roosevelt #30-22',
      bio: 'Rumba, baile y energía hasta la madrugada.',
      fotos: ['assets/images/bar2.jpg'],
      menuPdf: 'rumbaroom_pdf.pdf',
    ),
    LugarData(
      id: 'bodega_66',
      nombre: 'BODEGA 66',
      direccion: 'Calle 9 #66-10',
      bio: 'Bar alternativo con ambiente relajado.',
      fotos: ['assets/images/bar3.jpg'],
      menuPdf: 'bodega66_pdf.pdf',
    ),
    LugarData(
      id: 'bar_central',
      nombre: 'BAR CENTRAL',
      direccion: 'Cra 34 #7-89',
      bio: 'Un punto de encuentro en el corazón de la ciudad.',
      fotos: ['assets/images/bar4.jpg'],
      menuPdf: 'barcentral_pdf.pdf',
    ),
  ];

  // ===========================================================
  // 🔴 CHINCHE DATA 3 — CAFÉS
  // ===========================================================
  static const List<LugarData> cafes = [
    LugarData(
      id: 'cafe_del_parque',
      nombre: 'CAFÉ DEL PARQUE',
      direccion: 'Calle 15 #5-33',
      bio: 'Un café tranquilo rodeado de verde y buena compañía.',
      fotos: ['assets/images/cafe1.jpg'],
      menuPdf: 'cafedelparque_pdf.pdf',
    ),
    LugarData(
      id: 'mocha_express',
      nombre: 'MOCHA EXPRESS',
      direccion: 'Carrera 22 #14-18',
      bio: 'Café rápido, moderno y con gran sabor.',
      fotos: ['assets/images/cafe2.jpg'],
      menuPdf: 'mochaexpress_pdf.pdf',
    ),
    LugarData(
      id: 'cafe_libro',
      nombre: 'CAFÉ LIBRO',
      direccion: 'Calle 40 #10-45',
      bio: 'Lectura, café y conversaciones largas.',
      fotos: ['assets/images/cafe3.jpg'],
      menuPdf: 'cafelibro_pdf.pdf',
    ),
    LugarData(
      id: 'cappuccino_house',
      nombre: 'CAPPUCCINO HOUSE',
      direccion: 'Carrera 55 #21-09',
      bio: 'Especialistas en cappuccino y bebidas calientes.',
      fotos: ['assets/images/cafe4.jpg'],
      menuPdf: 'cappuccinohouse_pdf.pdf',
    ),
    LugarData(
      id: 'cafe_roma',
      nombre: 'CAFÉ ROMA',
      direccion: 'Calle 18 #66-20',
      bio: 'Inspiración italiana en cada taza.',
      fotos: ['assets/images/cafe5.jpg'],
      menuPdf: 'caferoma_pdf.pdf',
    ),
    LugarData(
      id: 'cafe_delicias',
      nombre: 'CAFÉ DELICIAS',
      direccion: 'Carrera 33 #12-50',
      bio: 'Postres, café y momentos dulces.',
      fotos: ['assets/images/cafe6.jpg'],
      menuPdf: 'cafedelicias_pdf.pdf',
    ),
    LugarData(
      id: 'cafe_origen',
      nombre: 'CAFÉ ORIGEN',
      direccion: 'Calle 9 #25-60',
      bio: 'Café colombiano de origen seleccionado.',
      fotos: ['assets/images/cafe7.jpg'],
      menuPdf: 'cafeorigen_pdf.pdf',
    ),
    LugarData(
      id: 'cafe_tardes',
      nombre: 'CAFÉ TARDES',
      direccion: 'Carrera 11 #40-15',
      bio: 'El lugar perfecto para una tarde tranquila.',
      fotos: ['assets/images/cafe8.jpg'],
      menuPdf: 'cafetardes_pdf.pdf',
    ),
  ];

  // ===========================================================
  // 🔴 CHINCHE DATA 4 — ACTIVIDADES
  // ===========================================================
  static const List<LugarData> actividades = [
    LugarData(
      id: 'cine_palomitas',
      nombre: 'CINE Y PALOMITAS',
      direccion: 'Centro Comercial Norte',
      bio: 'Una salida clásica para disfrutar películas y snacks.',
      fotos: ['assets/images/actividad1.jpg'],
      menuPdf: 'cinepalomitas_pdf.pdf',
    ),
    LugarData(
      id: 'parque_diversion',
      nombre: 'PARQUE DE DIVERSIÓN',
      direccion: 'Km 5 Vía al Mar',
      bio: 'Juegos, adrenalina y diversión garantizada.',
      fotos: ['assets/images/actividad2.jpg'],
      menuPdf: 'parquediversion_pdf.pdf',
    ),
    LugarData(
      id: 'escape_room',
      nombre: 'ESCAPE ROOM',
      direccion: 'Calle 3 #5-50',
      bio: 'Trabajo en equipo, acertijos y adrenalina.',
      fotos: ['assets/images/actividad3.jpg'],
      menuPdf: 'escaperoom_pdf.pdf',
    ),
    LugarData(
      id: 'concierto_local',
      nombre: 'CONCIERTO LOCAL',
      direccion: 'Plaza Central',
      bio: 'Música en vivo y ambiente cultural.',
      fotos: ['assets/images/actividad4.jpg'],
      menuPdf: 'conciertolocal_pdf.pdf',
    ),
  ];
}
