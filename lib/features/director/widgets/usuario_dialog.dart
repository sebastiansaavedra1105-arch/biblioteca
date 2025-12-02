import 'package:flutter/material.dart';

class UsuarioDialog extends StatefulWidget {
  final Map<String, dynamic>? usuarioParaEditar; // Si es null, es CREAR. Si tiene datos, es EDITAR.
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
    _passCtrl = TextEditingController(); // Contraseña siempre empieza vacía por seguridad
    
    if (_esEdicion && u?['rol'] != null) {
      _rol = u!['rol'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF252525),
      title: Text(_esEdicion ? "Editar Usuario" : "Nuevo Usuario", style: const TextStyle(color: Colors.white)),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _input("Nombre Completo", _nombreCtrl, Icons.badge),
                const SizedBox(height: 15),
                // El username no se suele editar porque es ID único en lógica, lo bloqueamos si es edición
                _input("Usuario (Login)", _userCtrl, Icons.person, enabled: !_esEdicion),
                const SizedBox(height: 15),
                _input(
                  _esEdicion ? "Nueva Contraseña (Opcional)" : "Contraseña", 
                  _passCtrl, 
                  Icons.lock, 
                  obscure: true,
                  isPass: true
                ),
                const SizedBox(height: 20),
                
                DropdownButtonFormField<String>(
                  value: _rol,
                  dropdownColor: Colors.grey[900],
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Rol',
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.security, color: Colors.amber),
                    filled: true,
                    fillColor: Colors.black12,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'BIBLIOTECARIA', child: Text('Bibliotecaria/o')),
                    DropdownMenuItem(value: 'DIRECTOR', child: Text('Director/a')),
                  ],
                  onChanged: (v) => setState(() => _rol = v!),
                )
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: const Text("Cancelar", style: TextStyle(color: Colors.grey))
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
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
          child: Text(_esEdicion ? "Actualizar" : "Guardar", style: const TextStyle(color: Colors.black)),
        )
      ],
    );
  }

  Widget _input(String label, TextEditingController ctrl, IconData icon, {bool obscure = false, bool enabled = true, bool isPass = false}) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      enabled: enabled,
      style: TextStyle(color: enabled ? Colors.white : Colors.grey),
      validator: (v) {
        if (!enabled) return null; // Si está deshabilitado no valida
        if (_esEdicion && isPass) return null; // En edición, la contraseña es opcional
        return v!.isEmpty ? 'Requerido' : null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: enabled ? Colors.amber : Colors.grey),
        filled: true,
        fillColor: Colors.black12,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}