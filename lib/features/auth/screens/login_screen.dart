import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

// IMPORTS NECESARIOS PARA NAVEGAR
import '../../dashboard/screens/dashboard_screen.dart';
import '../../director/screens/director_dashboard_screen.dart'; // Por si tienes rol de director

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

    final authProvider = context.read<AuthProvider>();
    
    FocusScope.of(context).unfocus();

    // 1. Intentamos Login
    final exito = await authProvider.login(
      _userController.text.trim(), 
      _passController.text
    );

    if (!mounted) return;

    if (exito) {
      // --- CORRECCIÓN AQUÍ ---
      // Antes usábamos pop(), ahora navegamos al Dashboard correspondiente
      
      final Widget pantallaDestino = authProvider.esDirector 
          ? const DirectorDashboardScreen() 
          : const DashboardScreen();

      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (_) => pantallaDestino)
      );
      // -----------------------
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${authProvider.errorMessage ?? "Error de acceso"}'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    
    final isLoading = context.select<AuthProvider, bool>((p) => p.isLoading);

    return Scaffold(
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
                  // --- 1. LOGO INSTITUCIONAL ---
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          )
                        ],
                        border: Border.all(color: colorScheme.primary, width: 2),
                      ),
                      child: Image.asset(
                        'assets/images/logo_colegio.png',
                        height: 80,
                        width: 80,
                        errorBuilder: (_,__,___) => Icon(Icons.school, size: 60, color: colorScheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- 2. TÍTULOS ---
                  Text(
                    "Bienvenido",
                    textAlign: TextAlign.center,
                    style: textTheme.displaySmall?.copyWith(
                      color: colorScheme.onSurface, // Corregido
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Inicie sesión para gestionar la biblioteca",
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7), // Corregido
                    ),
                  ),
                  const SizedBox(height: 40),

                  // --- 3. INPUT USUARIO ---
                  TextFormField(
                    controller: _userController,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: _inputDecoration(
                      "Usuario", 
                      Icons.person_outline, 
                      colorScheme
                    ),
                    validator: (value) => value!.isEmpty ? 'Ingrese su usuario' : null,
                  ),
                  const SizedBox(height: 20),

                  // --- 4. INPUT CONTRASEÑA ---
                  TextFormField(
                    controller: _passController,
                    obscureText: _isObscure,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: _inputDecoration(
                      "Contraseña", 
                      Icons.lock_outline, 
                      colorScheme
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(() => _isObscure = !_isObscure),
                      ),
                    ),
                    validator: (value) => value!.isEmpty ? 'Ingrese su contraseña' : null,
                    onFieldSubmitted: (_) => _handleLogin(),
                  ),
                  const SizedBox(height: 40),

                  // --- 5. BOTÓN INGRESAR ---
                  SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: colorScheme.primary.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                        ? const SizedBox(
                            height: 24, 
                            width: 24, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          )
                        : const Text(
                            "INGRESAR", 
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.0),
                          ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),

                  // --- 6. BOTÓN VOLVER ---
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back, size: 18, color: colorScheme.secondary),
                    label: Text(
                      "Volver al Catálogo", 
                      style: TextStyle(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w600
                      )
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, ColorScheme colors) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: colors.primary),
    );
  }
}