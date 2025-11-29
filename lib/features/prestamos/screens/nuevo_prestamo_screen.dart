import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/libro.dart';
import '../../dashboard/providers/libros_provider.dart';

class NuevoPrestamoScreen extends StatefulWidget {
  const NuevoPrestamoScreen({super.key});

  @override
  State<NuevoPrestamoScreen> createState() => _NuevoPrestamoScreenState();
}

class _NuevoPrestamoScreenState extends State<NuevoPrestamoScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores
  final _codLibroCtrl = TextEditingController();
  final _docSolicitanteCtrl = TextEditingController(); // Antes Codigo Alumno
  final _nomSolicitanteCtrl = TextEditingController(); // Antes Nombre Alumno
  DateTime _fecha = DateTime.now().add(const Duration(days: 7));

  // FocusNode para regresar el cursor al libro automáticamente tras guardar
  final FocusNode _libroFocus = FocusNode();

  // Estado Local
  Libro? _libro;
  String? _errorLibro;
  bool _buscando = false;

  @override
  void initState() {
    super.initState();
    // Ponemos el foco en el libro apenas entra a la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _libroFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _libroFocus.dispose();
    _codLibroCtrl.dispose();
    _docSolicitanteCtrl.dispose();
    _nomSolicitanteCtrl.dispose();
    super.dispose();
  }

  Future<void> _buscarLibro(String codigo) async {
    if (codigo.isEmpty) return;
    
    setState(() { _buscando = true; _errorLibro = null; _libro = null; });

    final encontrado = await context.read<LibrosProvider>().buscarLibroPorCodigo(codigo);

    if (!mounted) return;
    setState(() {
      _buscando = false;
      if (encontrado == null) {
        _errorLibro = '❌ Libro no encontrado';
        _codLibroCtrl.clear(); // Limpiamos para que intente de nuevo
        _libroFocus.requestFocus(); // Mantenemos el foco ahí
      } else if (encontrado.copiasDisponibles < 1) {
        _errorLibro = '⚠️ Sin stock disponible';
        _libro = encontrado; // Mostramos el libro aunque no haya stock para que vea cuál es
      } else {
        _libro = encontrado;
        _errorLibro = null;
      }
    });
  }

  Future<void> _procesarPrestamo() async {
    if (!_formKey.currentState!.validate()) return;
    if (_libro == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escanea un libro primero')));
      _libroFocus.requestFocus();
      return;
    }
    if (_libro!.copiasDisponibles < 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Este libro no tiene stock para prestar')));
      return;
    }

    final exito = await context.read<LibrosProvider>().registrarPrestamo(
      libro: _libro!,
      codigoAlumno: _docSolicitanteCtrl.text, // Puede ser DNI o Código Aula
      nombreAlumno: _nomSolicitanteCtrl.text, // Puede ser "1er Grado A"
      fechaEntrega: _fecha,
    );

    if (mounted && exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Préstamo registrado: ${_libro!.titulo}'), backgroundColor: Colors.green)
      );
      
      // --- FLUJO MASIVO ---
      // 1. Limpiamos SOLO el libro, mantenemos al solicitante (Profesor/Aula)
      _codLibroCtrl.clear();
      setState(() {
        _libro = null;
        _errorLibro = null;
      });
      
      // 2. Regresamos el cursor al campo de libro para escanear el siguiente al toque
      _libroFocus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dorado = Theme.of(context).colorScheme.primary;
    final loading = context.select<LibrosProvider, bool>((p) => p.isLoading);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- SECCIÓN 1: DATOS DEL SOLICITANTE (Ahora persistentes) ---
            const Text("DATOS DEL SOLICITANTE / AULA", style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.5)),
            const SizedBox(height: 10),
            
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: _Input(
                    label: 'DNI / Cod.', 
                    ctrl: _docSolicitanteCtrl, 
                    icon: Icons.badge
                  )
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _Input(
                    label: 'Nombre / Grado y Sección', 
                    ctrl: _nomSolicitanteCtrl, 
                    icon: Icons.class_
                  )
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            const Divider(color: Colors.white24),
            const SizedBox(height: 20),

            // --- SECCIÓN 2: ESCANEO DE LIBRO ---
            Text('ESCANEAR LIBRO', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: dorado)),
            const SizedBox(height: 10),
            
            TextFormField(
              controller: _codLibroCtrl,
              focusNode: _libroFocus, // Foco automático aquí
              autofocus: true,        // Apenas abre la pantalla, escribe aquí
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              decoration: _deco('Dispara al código aquí...', Icons.qr_code_scanner, dorado),
              
              // ESTO ES LO QUE PIDES: Al dar Enter (pistola), busca inmediatamente
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (valor) => _buscarLibro(valor),
            ),
            
            // Mensajes de estado
            if (_buscando)
              const Padding(padding: EdgeInsets.only(top: 20), child: Center(child: CircularProgressIndicator())),

            if (_errorLibro != null) 
              Padding(
                padding: const EdgeInsets.only(top: 15),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  color: Colors.red.withOpacity(0.2),
                  child: Row(children: [const Icon(Icons.error, color: Colors.red), const SizedBox(width: 10), Expanded(child: Text(_errorLibro!, style: const TextStyle(color: Colors.red)))]),
                )
              ),

            // TARJETA DEL LIBRO ENCONTRADO
            if (_libro != null && !_buscando)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 20),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: _libro!.copiasDisponibles > 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1), 
                  border: Border.all(color: _libro!.copiasDisponibles > 0 ? Colors.green : Colors.red),
                  borderRadius: BorderRadius.circular(10)
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _libro!.fotoBytes != null 
                      ? Image.memory(_libro!.fotoBytes!, width: 60, height: 90, fit: BoxFit.cover)
                      : const Icon(Icons.book, size: 60, color: Colors.grey),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_libro!.titulo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 5),
                        Text("Autor: ${_libro!.autor}", style: TextStyle(color: Colors.grey[400])),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            "DISPONIBLES: ${_libro!.copiasDisponibles}", 
                            style: TextStyle(color: _libro!.copiasDisponibles > 0 ? dorado : Colors.red, fontWeight: FontWeight.bold)
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 10),
            
            // SELECTOR DE FECHA EN ESPAÑOL
            InkWell(
              onTap: () async {
                final d = await showDatePicker(
                  context: context, 
                  initialDate: _fecha, 
                  firstDate: DateTime.now(), 
                  lastDate: DateTime(2030),
                  locale: const Locale('es', 'ES'), // <--- FUERZA ESPAÑOL
                  builder: (c, child) => Theme(data: Theme.of(c).copyWith(colorScheme: ColorScheme.dark(primary: dorado, onPrimary: Colors.black)), child: child!)
                );
                if (d != null) setState(() => _fecha = d);
              },
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white24)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Fecha de Devolución", style: TextStyle(color: Colors.grey[400])),
                    Row(children: [
                      Icon(Icons.calendar_today, color: dorado, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        // Formato simple manual o usar intl si quieres "Lunes 10..."
                        "${_fecha.day}/${_fecha.month}/${_fecha.year}", 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                      )
                    ])
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: dorado, foregroundColor: Colors.black, minimumSize: const Size.fromHeight(60)
              ),
              onPressed: (_libro != null && _libro!.copiasDisponibles > 0 && !loading) ? _procesarPrestamo : null,
              icon: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check_circle, size: 28),
              label: Text(loading ? "PROCESANDO..." : "CONFIRMAR PRÉSTAMO", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            
            const SizedBox(height: 10),
            const Center(child: Text("Al confirmar, el campo de libro se limpiará para el siguiente.", style: TextStyle(color: Colors.grey, fontSize: 10))),
          ],
        ),
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final String label; final TextEditingController ctrl; final IconData icon;
  const _Input({required this.label, required this.ctrl, required this.icon});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl, style: const TextStyle(color: Colors.white),
      validator: (v) => v!.isEmpty ? 'Requerido' : null,
      decoration: InputDecoration(
        labelText: label, prefixIcon: Icon(icon, color: Colors.grey, size: 18),
        filled: true, fillColor: Colors.white10,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
      ),
    );
  }
}

InputDecoration _deco(String label, IconData icon, Color color) {
  return InputDecoration(
    hintText: label, prefixIcon: Icon(icon, color: color),
    filled: true, fillColor: Colors.white10,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: color)),
  );
}