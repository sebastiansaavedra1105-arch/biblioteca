import 'package:flutter/material.dart';

class PrestamoSearchField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final VoidCallback onSearch;
  final bool isLoading;

  const PrestamoSearchField({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    required this.onSearch,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextField(
      controller: controller,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
        prefixIcon: Icon(icon, color: colorScheme.primary),
        suffixIcon: isLoading
            ? Padding(
                padding: const EdgeInsets.all(12.0),
                child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary),
              )
            : IconButton(
                icon: Icon(Icons.search, color: colorScheme.onSurface),
                onPressed: onSearch,
              ),
        filled: true,
        fillColor: theme.cardTheme.color, // Color de tarjeta según tema
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary),
        ),
      ),
      onSubmitted: (_) => onSearch(),
    );
  }
}