import 'package:flutter/material.dart';

class NuevoPrestamoScreen extends StatefulWidget {
  const NuevoPrestamoScreen({super.key});

  @override
  State<NuevoPrestamoScreen> createState() => _NuevoPrestamoScreenState();
}

class _NuevoPrestamoScreenState extends State<NuevoPrestamoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codigoLibroController = TextEditingController();
  
  // Datos del alumno controllers
  final _codigoAlumnoController = TextEditingController();
  final _nombreAlumnoController = TextEditingController();
  DateTime _fechaEntrega = DateTime.now().add(const Duration(days: 14));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Préstamo'),
        backgroundColor: const Color(0xFF667eea),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('📖 Datos del Libro', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF667eea))),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _codigoLibroController,
                      decoration: const InputDecoration(
                        labelText: 'Código de Barras',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.qr_code),
                      ),
                      validator: (value) => value!.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.search, size: 30),
                    onPressed: () {
                      // Lógica para buscar libro (simulada)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Buscando libro...')),
                      );
                    },
                  )
                ],
              ),
              
              const SizedBox(height: 30),
              const Text('👤 Datos del Alumno', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF667eea))),
              const SizedBox(height: 15),
              
              TextFormField(
                controller: _codigoAlumnoController,
                decoration: const InputDecoration(labelText: 'Código Alumno', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _nombreAlumnoController,
                decoration: const InputDecoration(labelText: 'Nombre Completo', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 15),
              
              ListTile(
                title: const Text('Fecha de Entrega'),
                subtitle: Text("${_fechaEntrega.day}/${_fechaEntrega.month}/${_fechaEntrega.year}"),
                trailing: const Icon(Icons.calendar_today),
                shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _fechaEntrega,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => _fechaEntrega = picked);
                },
              ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667eea),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Aquí llamaremos a la base de datos luego
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Préstamo registrado con éxito')),
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('📝 Registrar Préstamo', style: TextStyle(fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}