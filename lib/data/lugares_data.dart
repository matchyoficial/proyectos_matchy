// 📂 lib/data/lugares_data.dart
// ✅ FUENTE ÚNICA DE DATOS PARA MATCHY
// ✅ Restaurantes / Bares / Cafés / Actividades
// ✅ Usa LugarData como modelo universal
// ✅ Lista para migrar a Firebase sin romper pantallas

import 'package:proyectos_matchy/models/lugar_data.dart';

// ===========================================================
// 🍽️ RESTAURANTES
// ===========================================================
const List<LugarData> restaurantesData = [
  LugarData(
    id: 'faro', // 🔴 CHINCHE DATA REST 1
    nombre: 'EL FARO PIZZERIA',
    direccion: 'Carrera 66 #5-152',
    bio:
    'El Faro Pizzería, fundada en el 2003 brinda una programación especial todos los días. '
        'Es el ambiente perfecto para disfrutar de buena música, pizza y cócteles.',
    fotos: [
      'assets/images/faro1.jpg',
      'assets/images/faro2.jpg',
      'assets/images/faro3.jpg',
      'assets/images/faro4.jpg',
      'assets/images/faro5.jpg',
      'assets/images/faro6.jpg',
      'assets/images/faro7.jpg',
      'assets/images/faro8.jpg',
    ],
    menuPdf: 'faro_pdf.pdf',
    mapsQuery: 'Carrera 66 #5-152, Cali',
  ),

  LugarData(
    id: 'playita', // 🔴 CHINCHE DATA REST 2
    nombre: 'LA PLAYITA',
    direccion: 'Carrera 80 #45-22',
    bio: 'Restaurante informal ideal para compartir con amigos y disfrutar platos tradicionales.',
    fotos: ['assets/images/restaurante2.jpg'],
    menuPdf: '',
  ),

  LugarData(
    id: 'mr_wok',
    nombre: 'MR WOK CHINO',
    direccion: 'Carrera 54 #24-67',
    bio: 'Cocina oriental rápida y deliciosa.',
    fotos: ['assets/images/restaurante3.jpg'],
    menuPdf: '',
  ),

  LugarData(
    id: 'burger_house',
    nombre: 'BURGER HOUSE',
    direccion: 'Calle 15 #100-45',
    bio: 'Hamburguesas artesanales con ingredientes frescos.',
    fotos: ['assets/images/restaurante4.jpg'],
    menuPdf: '',
  ),

  LugarData(
    id: 'sushi_master',
    nombre: 'SUSHI MASTER',
    direccion: 'Carrera 10 #20-50',
    bio: 'Sushi y cocina japonesa moderna.',
    fotos: ['assets/images/restaurante5.jpg'],
    menuPdf: '',
  ),

  LugarData(
    id: 'parrilla_argenta',
    nombre: 'PARRILLA ARGENTA',
    direccion: 'Calle 34 #45-18',
    bio: 'Carnes a la parrilla al estilo argentino.',
    fotos: ['assets/images/restaurante6.jpg'],
    menuPdf: '',
  ),

  LugarData(
    id: 'tacos_mex',
    nombre: 'TACOS MEX',
    direccion: 'Carrera 70 #12-34',
    bio: 'Auténticos tacos mexicanos.',
    fotos: ['assets/images/restaurante7.jpg'],
    menuPdf: '',
  ),

  LugarData(
    id: 'veggie_garden',
    nombre: 'VEGGIE GARDEN',
    direccion: 'Carrera 25 #30-15',
    bio: 'Opciones vegetarianas y saludables.',
    fotos: ['assets/images/restaurante8.jpg'],
    menuPdf: '',
  ),
];

// ===========================================================
// 🍸 BARES
// ===========================================================
const List<LugarData> baresData = [
  LugarData(
    id: 'bar_la_noche',
    nombre: 'BAR LA NOCHE',
    direccion: 'Calle 5 #10-23',
    bio: 'Bar nocturno con música variada.',
    fotos: ['assets/images/bar1.jpg'],
    menuPdf: '',
  ),
  LugarData(
    id: 'rumba_room',
    nombre: 'RUMBA ROOM',
    direccion: 'Av. Roosevelt #30-22',
    bio: 'Ambiente de fiesta y baile.',
    fotos: ['assets/images/bar2.jpg'],
    menuPdf: '',
  ),
  LugarData(
    id: 'bodega_66',
    nombre: 'BODEGA 66',
    direccion: 'Calle 9 #66-10',
    bio: 'Bar con estilo urbano.',
    fotos: ['assets/images/bar3.jpg'],
    menuPdf: '',
  ),
  LugarData(
    id: 'bar_central',
    nombre: 'BAR CENTRAL',
    direccion: 'Cra 34 #7-89',
    bio: 'Clásico bar de encuentro.',
    fotos: ['assets/images/bar4.jpg'],
    menuPdf: '',
  ),
];

// ===========================================================
// ☕ CAFÉS
// ===========================================================
const List<LugarData> cafesData = [
  LugarData(
    id: 'cafe_parque',
    nombre: 'CAFÉ DEL PARQUE',
    direccion: 'Calle 15 #5-33',
    bio: 'Café tranquilo para charlar.',
    fotos: ['assets/images/cafe1.jpg'],
    menuPdf: '',
  ),
  LugarData(
    id: 'mocha_express',
    nombre: 'MOCHA EXPRESS',
    direccion: 'Carrera 22 #14-18',
    bio: 'Café rápido y moderno.',
    fotos: ['assets/images/cafe2.jpg'],
    menuPdf: '',
  ),
  LugarData(
    id: 'cafe_libro',
    nombre: 'CAFÉ LIBRO',
    direccion: 'Calle 40 #10-45',
    bio: 'Café y lectura.',
    fotos: ['assets/images/cafe3.jpg'],
    menuPdf: '',
  ),
  LugarData(
    id: 'cappuccino_house',
    nombre: 'CAPPUCCINO HOUSE',
    direccion: 'Carrera 55 #21-09',
    bio: 'Especialistas en cappuccinos.',
    fotos: ['assets/images/cafe4.jpg'],
    menuPdf: '',
  ),
];

// ===========================================================
// 🎯 ACTIVIDADES
// ===========================================================
const List<LugarData> actividadesData = [
  LugarData(
    id: 'cine',
    nombre: 'CINE Y PALOMITAS',
    direccion: 'Centro Comercial Norte',
    bio: 'Plan clásico de cine.',
    fotos: ['assets/images/actividad1.jpg'],
    menuPdf: '',
  ),
  LugarData(
    id: 'parque_diversion',
    nombre: 'PARQUE DE DIVERSIÓN',
    direccion: 'Km 5 Vía al Mar',
    bio: 'Atracciones y juegos.',
    fotos: ['assets/images/actividad2.jpg'],
    menuPdf: '',
  ),
  LugarData(
    id: 'escape_room',
    nombre: 'ESCAPE ROOM',
    direccion: 'Calle 3 #5-50',
    bio: 'Desafíos y acertijos.',
    fotos: ['assets/images/actividad3.jpg'],
    menuPdf: '',
  ),
  LugarData(
    id: 'concierto',
    nombre: 'CONCIERTO LOCAL',
    direccion: 'Plaza Central',
    bio: 'Música en vivo.',
    fotos: ['assets/images/actividad4.jpg'],
    menuPdf: '',
  ),
];
