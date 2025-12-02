import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../database/database_service.dart';

class SyncService {
  final DatabaseService _localDb = DatabaseService();
  final SupabaseClient _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  // --- 1. INSERTAR (CREAR) ---
  Future<void> insertar(String tabla, Map<String, dynamic> datos) async {
    // A. Generar ID local si no existe
    final datosConId = Map<String, dynamic>.from(datos);
    if (!datosConId.containsKey('id') || datosConId['id'] == null) {
      datosConId['id'] = _uuid.v4();
    }

    // B. Guardar en Local (Guardamos foto_bytes para que funcione OFFLINE)
    try {
      await _localDb.insertarDirecto(tabla, datosConId);
    } catch (e) {
      debugPrint("⚠️ Error insertando local: $e");
      return;
    }

    // C. Lógica de Nube
    if (await _hayInternet()) {
      await _procesarYSubir(tabla, datosConId, 'INSERT');
    } else {
      debugPrint("📴 Sin internet -> Encolando INSERT...");
      // Encolamos CON los bytes para poder subirlos cuando vuelva el internet
      await _encolar('INSERT', tabla, datosConId);
    }
  }

  // --- 2. ACTUALIZAR (EDITAR) ---
  Future<void> actualizar(String tabla, Map<String, dynamic> datos, String id) async {
    // A. Local
    await _localDb.actualizarDirecto(tabla, datos, id);

    // B. Nube
    if (await _hayInternet()) {
      await _procesarYSubir(tabla, datos, 'UPDATE', id: id);
    } else {
      await _encolar('UPDATE', tabla, datos, id: id);
    }
  }

  // --- 3. ELIMINAR (BORRAR) ---
  Future<void> eliminar(String tabla, String id) async {
    await _localDb.eliminarDirecto(tabla, id);

    if (await _hayInternet()) {
      try {
        // Opcional: Podrías borrar también la imagen del Storage aquí si quisieras limpiar
        await _supabase.from(tabla).delete().eq('id', id);
        debugPrint("☁️ Borrado en Supabase: $id");
      } catch (e) {
        await _encolar('DELETE', tabla, {}, id: id);
      }
    } else {
      await _encolar('DELETE', tabla, {}, id: id);
    }
  }

  // --- LÓGICA CORE: SUBIDA DE IMAGEN Y DATOS ---
  Future<void> _procesarYSubir(String tabla, Map<String, dynamic> datos, String accion, {String? id}) async {
    try {
      final datosParaNube = Map<String, dynamic>.from(datos);
      final registroId = id ?? datosParaNube['id'];

      // PASO 1: ¿Hay imagen nueva para subir? (Solo si es tabla libros y tiene bytes)
      if (tabla == 'libros' && datosParaNube['foto_bytes'] != null) {
        
        final Uint8List bytes = datosParaNube['foto_bytes']; // Sqflite devuelve Uint8List
        final String fileName = 'portada_$registroId.jpg'; // Nombre único
        
        debugPrint("📸 Subiendo imagen a Storage: $fileName...");

        // Subir binario directamente a Supabase Storage
        await _supabase.storage.from('portadas').uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(upsert: true), // Si existe, la reemplaza
        );

        // Obtener URL Pública
        final String publicUrl = _supabase.storage.from('portadas').getPublicUrl(fileName);
        
        // Asignamos la URL y borramos los bytes (Nube quiere URL, no bytes)
        datosParaNube['foto_url'] = publicUrl;
      }

      // Limpieza final: Nunca enviar 'foto_bytes' a la BD de Supabase
      datosParaNube.remove('foto_bytes');

      // PASO 2: Ejecutar la acción en BD Nube
      if (accion == 'INSERT') {
        await _supabase.from(tabla).insert(datosParaNube);
      } else if (accion == 'UPDATE') {
        await _supabase.from(tabla).update(datosParaNube).eq('id', registroId);
      }
      
      debugPrint("✅ Sincronización exitosa ($accion) en Nube.");

    } catch (e) {
      debugPrint("❌ Error subiendo a nube: $e -> Encolando...");
      // Si falla (ej: se cortó internet a mitad de subida), encolamos
      await _encolar(accion, tabla, datos, id: id);
    }
  }

  // --- DESCARGA (Para el Director/Otros PC) ---
  Future<int> descargarDatosNube() async {
    if (!await _hayInternet()) return 0;

    try {
      debugPrint("⬇️ Iniciando descarga inteligente...");
      
      // 1. Libros
      final librosNube = await _supabase.from('libros').select();
      for (var map in librosNube) {
        // TRUCO: Si viene URL de Supabase pero no tengo bytes locales, 
        // podríamos descargar la imagen y guardarla en bytes para tenerla offline.
        // Por ahora, guardamos los datos tal cual.
        await _localDb.insertarDirecto('libros', map);
      }

      // 2. Préstamos
      final prestamosNube = await _supabase.from('prestamos').select();
      for (var map in prestamosNube) {
        final datoLimpio = Map<String, dynamic>.from(map);
        if (datoLimpio['activo'] is bool) {
          datoLimpio['activo'] = (datoLimpio['activo'] == true) ? 1 : 0;
        }
        await _localDb.insertarDirecto('prestamos', datoLimpio);
      }

      return librosNube.length + prestamosNube.length;
    } catch (e) {
      debugPrint("❌ Error descargando: $e");
      return -1;
    }
  }

  // --- UTILIDADES ---
  Future<bool> _hayInternet() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return !connectivityResult.contains(ConnectivityResult.none);
  }

  Future<void> _encolar(String accion, String tabla, Map<String, dynamic> datos, {String? id}) async {
    // Aquí serializamos los bytes a Base64 si existen, para guardarlos en el TEXT de la cola
    // (SQLite maneja esto, pero jsonEncode no soporta Uint8List nativamente, hay que convertirlo)
    
    final datosCola = Map<String, dynamic>.from(datos);
    
    // Si hay bytes, los convertimos a lista de enteros para que JSON no falle
    if (datosCola['foto_bytes'] is Uint8List) {
       datosCola['foto_bytes'] = (datosCola['foto_bytes'] as Uint8List).toList();
    }

    final tarea = {
      'accion': accion,
      'tabla': tabla,
      'datos': jsonEncode(datosCola),
      'registro_id': id ?? datos['id'], 
      'fecha': DateTime.now().toIso8601String()
    };
    await _localDb.insertarCola(tarea);
    debugPrint("📥 Tarea encolada: $accion");
  }
  
  Future<void> sincronizarPendientes() async {
    if (!await _hayInternet()) return;

    final pendientes = await _localDb.obtenerColaPendiente();
    if (pendientes.isEmpty) return;

    debugPrint("🔄 Procesando cola (${pendientes.length})...");

    for (var tarea in pendientes) {
      try {
        final tabla = tarea['tabla'];
        Map<String, dynamic> datos = jsonDecode(tarea['datos']);
        
        // RECONSTRUIR BYTES: JSON los trae como List<dynamic>, pasarlos a Uint8List
        if (datos.containsKey('foto_bytes') && datos['foto_bytes'] != null) {
          List<dynamic> listaInt = datos['foto_bytes'];
          datos['foto_bytes'] = Uint8List.fromList(listaInt.cast<int>());
        }

        final id = tarea['registro_id'];
        final accion = tarea['accion'];

        // Reutilizamos la lógica inteligente
        await _procesarYSubir(tabla, datos, accion, id: id);

        await _localDb.borrarDeCola(tarea['id']);
      } catch (e) {
        debugPrint("❌ Error procesando cola item ${tarea['id']}: $e");
      }
    }
  }
}