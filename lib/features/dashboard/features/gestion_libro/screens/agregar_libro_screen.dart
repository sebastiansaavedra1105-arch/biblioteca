import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Imports absolutos
import 'package:biblio/core/models/libro.dart';
import 'package:biblio/features/dashboard/features/gestion_libro/providers/form_libro_provider.dart';
import 'package:biblio/features/dashboard/features/gestion_libro/widgets/libro_image_picker.dart';
import 'package:biblio/features/dashboard/features/gestion_libro/widgets/libro_form_inputs.dart';
import 'package:biblio/features/dashboard/features/gestion_libro/widgets/libro_action_buttons.dart';

class AgregarLibroScreen extends StatefulWidget {
  final Libro? libroParaEditar;

  const AgregarLibroScreen({super.key, this.libroParaEditar});

  @override
  State<AgregarLibroScreen> createState() => _AgregarLibroScreenState();
}

class _AgregarLibroScreenState extends State<AgregarLibroScreen> {
  // Controladores
  late TextEditingController _codCtrl;
  late TextEditingController _titCtrl;
  late TextEditingController _autCtrl;
  late TextEditingController _editCtrl;
  late TextEditingController _anioCtrl;
  late TextEditingController _copCtrl;
  late TextEditingController _obsCtrl; // <--- NUEVO

  @override
  void initState() {
    super.initState();
    final l = widget.libroParaEditar;
    
    _codCtrl = TextEditingController(text: l?.codigoBarras ?? '');
    _titCtrl = TextEditingController(text: l?.titulo ?? '');
    _autCtrl = TextEditingController(text: l?.autor ?? '');
    _editCtrl = TextEditingController(text: l?.editorial ?? '');
    _anioCtrl = TextEditingController(text: l?.anio.toString() ?? '');
    _copCtrl = TextEditingController(text: l?.copias.toString() ?? '1');
    _obsCtrl = TextEditingController(text: l?.observacion ?? ''); // <--- NUEVO
    
    // Inicializamos provider (Categoría, Estado, Foto)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FormLibroProvider>().initData(l);
    });
  }

  @override
  void dispose() {
    _codCtrl.dispose();
    _titCtrl.dispose();
    _autCtrl.dispose();
    _editCtrl.dispose();
    _anioCtrl.dispose();
    _copCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formProvider = context.watch<FormLibroProvider>();
    final esEdicion = widget.libroParaEditar != null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(esEdicion ? "Editar Libro" : "Nuevo Libro"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: formProvider.formKey,
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const LibroImagePicker(),
                    const SizedBox(width: 15),
                    Expanded(
                      child: LibroFormInputs(
                        codCtrl: _codCtrl,
                        titCtrl: _titCtrl,
                        autCtrl: _autCtrl,
                        editCtrl: _editCtrl,
                        anioCtrl: _anioCtrl,
                        copCtrl: _copCtrl,
                        obsCtrl: _obsCtrl, // <--- Conectado
                        onCodigoGenerado: () => setState((){}), 
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                LibroActionButtons(
                  esEdicion: esEdicion,
                  libroOriginal: widget.libroParaEditar,
                  codCtrl: _codCtrl,
                  titCtrl: _titCtrl,
                  autCtrl: _autCtrl,
                  editCtrl: _editCtrl,
                  anioCtrl: _anioCtrl,
                  copCtrl: _copCtrl,
                  obsCtrl: _obsCtrl, // <--- Enviamos al botón de guardar
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}