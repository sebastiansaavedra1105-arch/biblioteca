import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Importante
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  
  bool _isObscure = true;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    // Llamamos al Provider
    final authProvider = context.read<AuthProvider>();
    final exito = await authProvider.login(
      _userController.text, 
      _passController.text
    );

    if (!mounted) return;

    if (exito) {
      Navigator.pop(context); 
    } else {
      // Mostrar error que viene del provider
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${authProvider.errorMessage ?? "Error desconocido"}'),
          backgroundColor: Colors.red.shade900,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorDorado = Theme.of(context).colorScheme.primary;
    // Escuchamos el estado de loading del provider
    final isLoading = context.select<AuthProvider, bool>((p) => p.isLoading);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.admin_panel_settings, size: 80, color: colorDorado),
                  const SizedBox(height: 20),
                  Text(
                    "ACCESO ADMINISTRATIVO",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorDorado,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // INPUT USUARIO
                  TextFormField(
                    controller: _userController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Usuario", Icons.person, colorDorado),
                    validator: (v) => v!.isEmpty ? 'Ingrese usuario' : null,
                  ),
                  const SizedBox(height: 20),

                  // INPUT PASSWORD
                  TextFormField(
                    controller: _passController,
                    obscureText: _isObscure,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Contraseña", Icons.lock, colorDorado).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(_isObscure ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                        onPressed: () => setState(() => _isObscure = !_isObscure),
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? 'Ingrese contraseña' : null,
                  ),

                  const SizedBox(height: 40),

                  // BOTÓN INGRESAR
                  SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorDorado,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: isLoading ? null : _handleLogin,
                      child: isLoading 
                        ? const SizedBox(
                            width: 24, 
                            height: 24, 
                            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)
                          )
                        : const Text("INGRESAR", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pop(context), // Volver al catálogo
                    child: const Text("Volver al Catálogo", style: TextStyle(color: Colors.grey)),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, Color color) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: color),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[800]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.red.shade900),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
}