import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

class KpiCard extends StatefulWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<KpiCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppTheme.navyBorder : AppTheme.ash;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        // Tarjeta plana: el borde define el contenedor; al pasar el mouse
        // aparece un anillo sutil en lugar de una sombra flotante.
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          boxShadow: _isHovered && !isDark ? AppTheme.ringShadow : null,
          border: Border.all(
            color: _isHovered ? (isDark ? scheme.outline : AppTheme.smoke) : borderColor,
            width: 1,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Encabezado: etiqueta atenuada + icono con un solo acento
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: widget.color.withValues(alpha: isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                        ),
                        child: Icon(widget.icon, color: widget.color, size: 18),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Valor Principal (Con ajuste automático de tamaño)
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.value,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ),
                  ),

                  // Subtítulo
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward,
                        size: 14,
                        color: _isHovered ? widget.color : scheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
