import 'package:flutter/material.dart';

class CustomCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subLabel;
  final String? badge;
  final Color iconColor;
  final Color iconBackgroundColor;
  final Color accentColor;
  final VoidCallback? onTap;

  const CustomCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.subLabel,
    this.badge,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.accentColor,
    this.onTap,
  });

  @override
  State<CustomCard> createState() => _CustomCardState();
}

class _CustomCardState extends State<CustomCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 1.015,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onEnter(_) {
    setState(() => _hovered = true);
    _controller.forward();
  }

  void _onExit(_) {
    setState(() => _hovered = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _hovered
                    ? const Color(0xFFCBD5E1)
                    : const Color(0xFFE9EDF2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: _hovered ? 0.07 : 0.03),
                  blurRadius: _hovered ? 20 : 10,
                  offset: Offset(0, _hovered ? 8 : 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        widget.label,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(widget.icon, color: widget.iconColor, size: 22),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  widget.value,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    height: 1.1,
                    letterSpacing: -0.8,
                  ),
                ),
                if (widget.subLabel != null || widget.badge != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (widget.badge != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: widget.iconBackgroundColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.badge!,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: widget.iconColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (widget.subLabel != null)
                        Expanded(
                          child: Text(
                            widget.subLabel!,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
