import 'package:flutter/material.dart';
import '../services/diff_service.dart';

class DiffText extends StatelessWidget {
  final List<DiffSegment> segments;
  final double fontSize;

  const DiffText({
    Key? key,
    required this.segments,
    this.fontSize = 22,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(
            fontSize: fontSize,
            fontFamily: 'monospace',
            letterSpacing: 1.5,
          ),
          children: segments.map((segment) {
            switch (segment.type) {
              case DiffType.match:
                return TextSpan(
                  text: segment.text,
                  style: const TextStyle(
                    color: Color(0xFF00FFCC), // Glow cyan
                    fontWeight: FontWeight.bold,
                  ),
                );
              case DiffType.missing:
                return TextSpan(
                  text: segment.text,
                  style: TextStyle(
                    color: const Color(0xFFFFCC00), // Amber
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                    decorationStyle: TextDecorationStyle.solid,
                    decorationColor: const Color(0xFFFFCC00),
                    decorationThickness: 2,
                    backgroundColor: const Color(0xFFFFCC00).withOpacity(0.1),
                  ),
                );
              case DiffType.extra:
                return TextSpan(
                  text: segment.text,
                  style: TextStyle(
                    color: const Color(0xFFFF3366), // Neon Pink/Red
                    decoration: TextDecoration.lineThrough,
                    decorationColor: const Color(0xFFFF3366),
                    decorationThickness: 2,
                    backgroundColor: const Color(0xFFFF3366).withOpacity(0.15),
                  ),
                );
            }
          }).toList(),
        ),
      ),
    );
  }
}
