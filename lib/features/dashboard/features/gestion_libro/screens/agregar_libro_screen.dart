import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  late TextEditingController _codCtrl;
  late TextEditingController _titCtrl;
  late TextEditingController _autCtrl;
  late TextEditingController _editCtrl;
  late TextEditingController _anioCtrl;
  late TextEditingController _copCtrl;
  late TextEditingController _obsCtrl;

  @override
  void initState() {
    super.initState();
    final l = widget.libroParaEditar;
    
    _codCtrl = TextEditingController(text: l?.codigoBarras ?? '');
    _titCtrl = TextEditingController(text: l?.titulo ?? '');
    _autCtrl = TextEditingController(text: l?.autor ?? '');
    _editCtrl = TextEditingController(text: l?.editorial ?? '');
    _anioCtrl = TextEditingController(text: l?.anio.toString() ?? DateTime.now().year.toString());
    _copCtrl = TextEditingController(text: l?.copias.toString() ?? '1');
    _obsCtrl = TextEditingController(text: l?.observacion ?? '');

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

  void _generarCodigo() {
    final random = Random();
    final cod = "LIB-${1000 + random.nextInt(9000)}-${DateTime.now().year}";
    setState(() {
      _codCtrl.text = cod;
    });
  }

  @override
  Widget build(BuildContext context) {
    final formProvider = context.watch<FormLibroProvider>();
    final esEdicion = widget.libroParaEditar != null;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: esEdicion 
          ? AppBar(title: const Text("Editar Libro"), elevation: 0) 
          : null, 
      
      backgroundColor: theme.scaffoldBackgroundColor,
      
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formProvider.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const LibroImagePicker(),
                    const SizedBox(width: 20),
                    Expanded(
                      child: LibroFormInputs(
                        codCtrl: _codCtrl,
                        titCtrl: _titCtrl,
                        autCtrl: _autCtrl,
                        editCtrl: _editCtrl,
                        anioCtrl: _anioCtrl,
                        copCtrl: _copCtrl,
                        obsCtrl: _obsCtrl,
                        onCodigoGenerado: _generarCodigo,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
                Divider(color: theme.colorScheme.onSurface.withOpacity(0.1)),
                const SizedBox(height: 20),

                LibroActionButtons(
                  esEdicion: esEdicion,
                  libroOriginal: widget.libroParaEditar,
                  codCtrl: _codCtrl,
                  titCtrl: _titCtrl,
                  autCtrl: _autCtrl,
                  editCtrl: _editCtrl,
                  anioCtrl: _anioCtrl,
                  copCtrl: _copCtrl,
                  obsCtrl: _obsCtrl,
                ),
                
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}