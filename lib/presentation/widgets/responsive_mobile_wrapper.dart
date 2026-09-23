import 'package:flutter/material.dart';

class ResponsiveMobileWrapper extends StatelessWidget {
  final Widget child;

  const ResponsiveMobileWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          // Desktop / Web Viewport: Center in a sleek smartphone frame
          return Container(
            color: const Color(0xFF030712), // Dark backdrop behind the phone
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420, maxHeight: 890),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 30,
                      spreadRadius: 8,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(33),
                  child: child,
                ),
              ),
            ),
          );
        }

        // Native Smartphone View: Fullscreen
        return child;
      },
    );
  }
}
