import 'package:flutter/gestures.dart';
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
    final colorDorado = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        border: Border(bottom: BorderSide(color: Colors.grey[900]!)),
      ),
      child: Column(
        children: [
          // FILA 1: BUSCADOR + SWITCH
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Buscar título, autor...',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: Icon(Icons.search, color: colorDorado),
                    filled: true,
                    fillColor: const Color(0xFF252525),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onChanged: (val) => catalogoRead.buscar(val),
                ),
              ),
              const SizedBox(width: 15),
              // Switch "Solo Disponibles"
              Consumer<CatalogoProvider>(
                builder: (context, provider, _) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF252525),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: provider.soloDisponibles ? Colors.green : Colors.transparent)
                    ),
                    child: Row(
                      children: [
                        Text("Solo Disponibles", 
                          style: TextStyle(
                            color: provider.soloDisponibles ? Colors.green : Colors.grey, 
                            fontWeight: FontWeight.bold, fontSize: 12
                          )
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: provider.soloDisponibles, 
                          onChanged: (v) => provider.toggleSoloDisponibles(v),
                          activeColor: Colors.green,
                          activeTrackColor: Colors.green.withOpacity(0.3),
                          inactiveThumbColor: Colors.grey,
                          inactiveTrackColor: Colors.grey[800],
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        )
                      ],
                    ),
                  );
                }
              )
            ],
          ),

          const SizedBox(height: 15),

          // FILA 2: CATEGORÍAS CON FLECHAS
          Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back_ios, size: 16, color: Colors.grey), onPressed: _scrollLeft),
              Expanded(
                child: SizedBox(
                  height: 35,
                  child: Consumer<CatalogoProvider>(
                    builder: (context, provider, _) {
                      return ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(
                          dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
                        ),
                        child: ListView.builder(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          itemCount: provider.categorias.length,
                          itemBuilder: (ctx, index) {
                            final categoria = provider.categorias[index];
                            final isSelected = provider.categoriaSeleccionada == categoria;
                            
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(categoria),
                                selected: isSelected,
                                onSelected: (val) {
                                  if (val) provider.cambiarCategoria(categoria);
                                },
                                selectedColor: colorDorado,
                                backgroundColor: const Color(0xFF252525),
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.black : Colors.white70, 
                                  fontWeight: FontWeight.bold, fontSize: 12
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                side: BorderSide.none,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
              IconButton(icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey), onPressed: _scrollRight),
            ],
          ),
        ],
      ),
    );
  }
}