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
    // A. Generar ID local
    final datosConId = Map<String, dynamic>.from(datos);
    if (!datosConId.containsKey('id') || datosConId['id'] == null) {
      datosConId['id'] = _uuid.v4();
    }

    // B. Guardar en Local (Aquí SI guardamos foto_bytes si existe)
    try {
      await _localDb.insertarDirecto(tabla, datosConId); 
    } catch (e) {
      debugPrint("⚠️ Error insertando local: $e");
      return;
    }

    // C. Preparar datos para la Nube (LIMPIEZA DE DATOS)
    // Quitamos 'foto_bytes' porque Supabase no tiene esa columna, tiene 'foto_url'
    final datosParaNube = Map<String, dynamic>.from(datosConId);
    datosParaNube.remove('foto_bytes'); 

    // D. Intentar subir a la Nube
    if (await _hayInternet()) {
      try {
        await _supabase.from(tabla).insert(datosParaNube); // <--- Enviamos datos limpios
        debugPrint("☁️ Subido a Supabase: $tabla");
      } catch (e) {
        debugPrint("❌ Falló subida nube: $e -> Encolando...");
        await _encolar('INSERT', tabla, datosParaNube); // Encolamos sin bytes para que no pese
      }
    } else {
      debugPrint("📴 Sin internet -> Encolando...");
      await _encolar('INSERT', tabla, datosParaNube);
    }
  }

  // --- 2. ACTUALIZAR (EDITAR) ---
  Future<void> actualizar(String tabla, Map<String, dynamic> datos, String id) async {
    // A. Local
    await _localDb.actualizarDirecto(tabla, datos, id);

    // B. Preparar datos Nube (LIMPIEZA)
    final datosParaNube = Map<String, dynamic>.from(datos);
    datosParaNube.remove('foto_bytes');

    // C. Nube
    if (await _hayInternet()) {
      try {
        await _supabase.from(tabla).update(datosParaNube).eq('id', id);
        debugPrint("☁️ Actualizado en Supabase: $id");
      } catch (e) {
        debugPrint("❌ Error actualizando nube: $e");
        await _encolar('UPDATE', tabla, datosParaNube, id: id);
      }
    } else {
      await _encolar('UPDATE', tabla, datosParaNube, id: id);
    }
  }

  // --- 3. ELIMINAR (BORRAR) ---
  Future<void> eliminar(String tabla, String id) async {
    // A. Local
    await _localDb.eliminarDirecto(tabla, id);

    // B. Nube
    if (await _hayInternet()) {
      try {
        await _supabase.from(tabla).delete().eq('id', id);
        debugPrint("☁️ Borrado en Supabase: $id");
      } catch (e) {
        debugPrint("❌ Error borrando nube: $e");
        await _encolar('DELETE', tabla, {}, id: id);
      }
    } else {
      await _encolar('DELETE', tabla, {}, id: id);
    }
  }

  // --- 4. DESCARGAR DE LA NUBE (PARA EL DIRECTOR) ---
  Future<int> descargarDatosNube() async {
    if (!await _hayInternet()) {
      debugPrint("📴 No hay internet para descargar.");
      return 0; // 0 cambios
    }

    try {
      debugPrint("⬇️ Iniciando descarga masiva...");
      
      // A. Descargar Libros
      final librosNube = await _supabase.from('libros').select();
      for (var map in librosNube) {
        // Guardamos en local (replace sobrescribe si ya existe)
        await _localDb.insertarDirecto('libros', map);
      }

      // B. Descargar Préstamos
      final prestamosNube = await _supabase.from('prestamos').select();
      for (var map in prestamosNube) {
        await _localDb.insertarDirecto('prestamos', map);
      }

      debugPrint("✅ Descarga completada: ${librosNube.length} libros, ${prestamosNube.length} préstamos.");
      return librosNube.length + prestamosNube.length;

    } catch (e) {
      debugPrint("❌ Error descargando datos: $e");
      return -1; // Error
    }
  }
  
  // --- UTILIDADES ---

  Future<bool> _hayInternet() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return !connectivityResult.contains(ConnectivityResult.none);
  }

  Future<void> _encolar(String accion, String tabla, Map<String, dynamic> datos, {String? id}) async {
    final tarea = {
      'accion': accion,
      'tabla': tabla,
      'datos': jsonEncode(datos),
      'registro_id': id ?? datos['id'], 
      'fecha': DateTime.now().toIso8601String()
    };
    await _localDb.insertarCola(tarea);
    debugPrint("📥 Tarea encolada: $accion en $tabla");
  }
  
  Future<void> sincronizarPendientes() async {
    if (!await _hayInternet()) return;

    final pendientes = await _localDb.obtenerColaPendiente();
    if (pendientes.isEmpty) return;

    debugPrint("🔄 Sincronizando ${pendientes.length} tareas pendientes...");

    for (var tarea in pendientes) {
      try {
        final tabla = tarea['tabla'];
        final datos = jsonDecode(tarea['datos']);
        final id = tarea['registro_id'];
        final accion = tarea['accion'];

        if (accion == 'INSERT') {
          await _supabase.from(tabla).insert(datos);
        } else if (accion == 'UPDATE') {
          await _supabase.from(tabla).update(datos).eq('id', id);
        } else if (accion == 'DELETE') {
          await _supabase.from(tabla).delete().eq('id', id);
        }

        await _localDb.borrarDeCola(tarea['id']);
      } catch (e) {
        debugPrint("❌ Error sincronizando tarea ${tarea['id']}: $e");
        // Nota: Si el error es "foreign key violation" (porque intentó subir un préstamo antes que el libro),
        // en la siguiente vuelta del bucle o reinicio se arreglará solo si el libro ya subió.
      }
    }
    debugPrint("✅ Sincronización terminada.");
  }
}