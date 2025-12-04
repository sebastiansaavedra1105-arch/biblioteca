import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../database/database_service.dart';

class SyncService {
  final DatabaseService _localDb = DatabaseService();
  
  // Usamos getter para obtener la instancia inicializada en main
  SupabaseClient get _supabase => Supabase.instance.client;
  
  final _uuid = const Uuid();

  // UUID "Nulo" válido para comparaciones en PostgreSQL
  static const String _nilUuid = '00000000-0000-0000-0000-000000000000';

  // --- 1. INSERTAR (CREAR) ---
  Future<void> insertar(String tabla, Map<String, dynamic> datos) async {
    final datosConId = Map<String, dynamic>.from(datos);
    if (!datosConId.containsKey('id') || datosConId['id'] == null) {
      datosConId['id'] = _uuid.v4();
    }

    try {
      await _localDb.insertarDirecto(tabla, datosConId);
    } catch (e) {
      debugPrint("⚠️ Error insertando local: $e");
      return;
    }

    if (await _hayInternet()) {
      await _procesarYSubir(tabla, datosConId, 'INSERT');
    } else {
      debugPrint("📴 Sin internet -> Encolando INSERT...");
      await _encolar('INSERT', tabla, datosConId);
    }
  }

  // --- 2. ACTUALIZAR (EDITAR) ---
  Future<void> actualizar(String tabla, Map<String, dynamic> datos, String id) async {
    await _localDb.actualizarDirecto(tabla, datos, id);

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

      if (tabla == 'prestamos' && datosParaNube['activo'] is int) {
      datosParaNube['activo'] = (datosParaNube['activo'] == 1);
    }

      // SUBIDA DE FOTO (Solo para libros)
      if (tabla == 'libros' && datosParaNube['foto_bytes'] != null) {
        final Uint8List bytes = datosParaNube['foto_bytes']; 
        final String fileName = 'portada_$registroId.jpg'; 
        
        debugPrint("📸 Subiendo imagen a Storage: $fileName...");

        try {
          // Intentamos subir
          await _supabase.storage.from('portadas').uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
          
          final String publicUrl = _supabase.storage.from('portadas').getPublicUrl(fileName);
          datosParaNube['foto_url'] = publicUrl;
        } catch (e) {
          // Si falla por permisos (RLS), lo ignoramos para no bloquear el resto de datos
          debugPrint("⚠️ Advertencia Storage: $e");
        }
      }

      // Limpieza: Nunca enviar bytes a la tabla SQL
      datosParaNube.remove('foto_bytes');

      if (accion == 'INSERT') {
        await _supabase.from(tabla).insert(datosParaNube);
      } else if (accion == 'UPDATE') {
        await _supabase.from(tabla).update(datosParaNube).eq('id', registroId);
      }
      
      debugPrint("✅ Sincronización exitosa ($accion) en Nube.");

    } catch (e) {
      debugPrint("❌ Error subiendo a nube: $e -> Encolando...");
      await _encolar(accion, tabla, datos, id: id);
    }
  }

  // --- DESCARGA ---
  Future<int> descargarDatosNube() async {
    if (!await _hayInternet()) return 0;

    try {
      debugPrint("⬇️ Iniciando descarga inteligente...");
      
      // 1. Libros
      final librosNube = await _supabase.from('libros').select();
      for (var map in librosNube) {
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

      // 👇 3. ALUMNOS (AGREGA ESTO)
      try {
        final alumnosNube = await _supabase.from('alumnos').select();
        for (var map in alumnosNube) {
          await _localDb.insertarDirecto('alumnos', map);
        }
        debugPrint("✅ Alumnos descargados: ${alumnosNube.length}");
      } catch (e) {
        debugPrint("⚠️ Error descargando alumnos: $e");
      }
      
      // 4. Usuarios
      try {
         final usuariosNube = await _supabase.from('usuarios').select();
         for (var map in usuariosNube) {
            await _localDb.insertarDirecto('usuarios', map);
         }
      } catch(e) { /*...*/ }

      return librosNube.length + prestamosNube.length;
    } catch (e) {
      debugPrint("❌ Error descargando: $e");
      return -1;
    }
  }

  // --- UTILIDADES ---
  Future<bool> _hayInternet() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return !connectivityResult.contains(ConnectivityResult.none);
    } catch(e) {
      return false;
    }
  }

  Future<void> _encolar(String accion, String tabla, Map<String, dynamic> datos, {String? id}) async {
    final datosCola = Map<String, dynamic>.from(datos);
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
        
        if (datos.containsKey('foto_bytes') && datos['foto_bytes'] != null) {
          List<dynamic> listaInt = datos['foto_bytes'];
          datos['foto_bytes'] = Uint8List.fromList(listaInt.cast<int>());
        }

        final id = tarea['registro_id'];
        final accion = tarea['accion'];

        await _procesarYSubir(tabla, datos, accion, id: id);
        await _localDb.borrarDeCola(tarea['id']);
      } catch (e) {
        debugPrint("❌ Error procesando cola item ${tarea['id']}: $e");
      }
    }
  }

  // --- MÉTODOS DE LIMPIEZA MASIVA (CORREGIDOS) ---
  
  Future<void> nukePrestamos() async {
    // Local
    await _localDb.database.then((db) => db.delete('prestamos'));
    
    // Nube
    if (await _hayInternet()) {
      try { 
        // 🔥 CORRECCIÓN: Usamos un UUID válido pero inexistente en lugar de "0"
        await _supabase.from('prestamos').delete().neq('id', _nilUuid); 
        debugPrint("☁️ Nube: Préstamos borrados.");
      } catch (e) { 
        debugPrint("❌ Error borrando prestamos nube: $e"); 
      }
    }
  }

  Future<void> nukeLibros() async {
    // Primero borramos préstamos dependientes
    await nukePrestamos(); 

    // Local
    await _localDb.database.then((db) => db.delete('libros'));

    // Nube
    if (await _hayInternet()) {
      try { 
        // 🔥 CORRECCIÓN: Usamos un UUID válido
        await _supabase.from('libros').delete().neq('id', _nilUuid); 
        debugPrint("☁️ Nube: Libros borrados.");
      } catch (e) { 
        debugPrint("❌ Error borrando libros nube: $e"); 
      }
    }
  }

  Future<void> nukeTodo() async {
    await nukeLibros(); 
  }
}