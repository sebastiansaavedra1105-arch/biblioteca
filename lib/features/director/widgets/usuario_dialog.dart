import 'package:flutter/material.dart';

class UsuarioDialog extends StatefulWidget {
  final Map<String, dynamic>? usuarioParaEditar; 
  final Function(String user, String pass, String nombre, String rol) onConfirm;

  const UsuarioDialog({super.key, this.usuarioParaEditar, required this.onConfirm});

  @override
  State<UsuarioDialog> createState() => _UsuarioDialogState();
}

class _UsuarioDialogState extends State<UsuarioDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nombreCtrl;
  late TextEditingController _userCtrl;
  late TextEditingController _passCtrl;
  
  String _rol = 'BIBLIOTECARIA';
  bool _esEdicion = false;

  @override
  void initState() {
    super.initState();
    final u = widget.usuarioParaEditar;
    _esEdicion = u != null;

    _nombreCtrl = TextEditingController(text: u?['nombre'] ?? '');
    _userCtrl = TextEditingController(text: u?['username'] ?? '');
    _passCtrl = TextEditingController(); 
    
    if (_esEdicion && u?['rol'] != null) {
      _rol = u!['rol'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      // Fondo dinámico
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(_esEdicion ? Icons.edit : Icons.person_add, color: colorScheme.primary),
          const SizedBox(width: 10),
          Text(
            _esEdicion ? "Editar Usuario" : "Nuevo Usuario",
            style: TextStyle(color: colorScheme.onSurface)
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // NOMBRE
                _input("Nombre del Personal", _nombreCtrl, Icons.badge),
                const SizedBox(height: 15),
                
                // ROL (Dropdown)
                DropdownButtonFormField<String>(
                  value: _rol,
                  dropdownColor: colorScheme.surface,
                  decoration: const InputDecoration(
                    labelText: "Rol / Permisos",
                    prefixIcon: Icon(Icons.admin_panel_settings),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'BIBLIOTECARIA', child: Text("Bibliotecario/a (Acceso Estándar)")),
                    DropdownMenuItem(value: 'DIRECTOR', child: Text("Director (Acceso Total)")),
                  ],
                  onChanged: (val) => setState(() => _rol = val!),
                ),
                const SizedBox(height: 15),

                // USERNAME
                _input(
                  "Nombre de Usuario", 
                  _userCtrl, 
                  Icons.account_circle, 
                  enabled: !_esEdicion // No dejar cambiar username al editar
                ),
                const SizedBox(height: 15),

                // PASSWORD
                _input(
                  _esEdicion ? "Nueva Contraseña (Opcional)" : "Contraseña", 
                  _passCtrl, 
                  Icons.lock,
                  isPass: true,
                  obscure: true
                ),
                if (_esEdicion)
                  Padding(
                    padding: const EdgeInsets.only(top: 5, left: 10),
                    child: Text(
                      "* Dejar vacío para mantener la actual", 
                      style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withOpacity(0.5))
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: const Text("Cancelar")
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onConfirm(
                _userCtrl.text.trim(), 
                _passCtrl.text.trim(), 
                _nombreCtrl.text.trim(), 
                _rol
              );
              Navigator.pop(context);
            }
          },
          child: Text(_esEdicion ? "Actualizar" : "Guardar"),
        )
      ],
    );
  }

  Widget _input(String label, TextEditingController ctrl, IconData icon, {bool obscure = false, bool enabled = true, bool isPass = false}) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      enabled: enabled,
      validator: (v) {
        if (!enabled) return null; 
        if (_esEdicion && isPass) return null; // En edición, pass es opcional
        return v!.isEmpty ? 'Requerido' : null;
      },
      // Usamos el tema global, solo añadimos iconos específicos
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
    );
  }
}