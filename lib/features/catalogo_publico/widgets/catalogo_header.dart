import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/catalogo_provider.dart';

class CatalogoHeader extends StatefulWidget {
  const CatalogoHeader({super.key});

  @override
  State<CatalogoHeader> createState() => _CatalogoHeaderState();
}

class _CatalogoHeaderState extends State<CatalogoHeader> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollLeft() {
    _scrollController.animateTo(
      _scrollController.offset - 200,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + 200,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalogoRead = context.read<CatalogoProvider>();
    
    // Accedemos a los colores y textos del tema global
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: colorScheme.surface, 
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          // 1. BUSCADOR ELEGANTE
          TextField(
            // CORRECCIÓN FINAL: Usamos 'buscar' que es el método real de tu Provider
            onChanged: (val) => catalogoRead.buscar(val),
            style: textTheme.bodyLarge, 
            decoration: InputDecoration(
              hintText: 'Buscar por título, autor o ISBN...',
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: Icon(Icons.search, color: colorScheme.primary), 
              filled: true,
              // Color de fondo dinámico (Evitamos 'background' deprecated)
              fillColor: theme.brightness == Brightness.light 
                  ? const Color(0xFFF5F5F5) 
                  : const Color(0xFF2C2C2C),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 15),

          // 2. FILTROS (Categorías) CON SCROLL
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios, size: 16, color: colorScheme.onSurface.withOpacity(0.5)), 
                onPressed: _scrollLeft
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Consumer<CatalogoProvider>(
                    builder: (context, provider, child) {
                      return Row(
                        children: List.generate(
                          provider.categorias.length,
                          (index) {
                            final categoria = provider.categorias[index];
                            final isSelected = provider.categoriaSeleccionada == categoria;
                            
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(categoria),
                                labelStyle: textTheme.labelLarge?.copyWith(
                                  color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                selected: isSelected,
                                onSelected: (val) {
                                  if (val) provider.cambiarCategoria(categoria);
                                },
                                selectedColor: colorScheme.primary, 
                                backgroundColor: Colors.grey.withOpacity(0.1), 
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: isSelected 
                                      ? BorderSide.none 
                                      : BorderSide(color: Colors.grey.withOpacity(0.3)),
                                ),
                                showCheckmark: false, 
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.arrow_forward_ios, size: 16, color: colorScheme.onSurface.withOpacity(0.5)), 
                onPressed: _scrollRight
              ),
            ],
          ),
        ],
      ),
    );
  }
}