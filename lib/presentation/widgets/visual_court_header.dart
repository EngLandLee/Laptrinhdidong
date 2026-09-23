import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A realistic court header widget displaying authentic court markings
/// for badminton, football, and pickleball with court number and surface tag badges.
class VisualCourtHeader extends StatelessWidget {
  final int courtNumber;
  final String sportType;
  final double width;
  final double height;
  final bool isSelected;
  final bool isInactive;
  final VoidCallback? onTap;

  const VisualCourtHeader({
    super.key,
    required this.courtNumber,
    required this.sportType,
    this.width = 110,
    this.height = 72,
    this.isSelected = false,
    this.isInactive = false,
    this.onTap,
  });

  bool get _isFootball {
    final lower = sportType.toLowerCase();
    return lower.contains('football') ||
        lower.contains('bóng đá') ||
        lower.contains('soccer');
  }

  bool get _isPickleball {
    final lower = sportType.toLowerCase();
    return lower.contains('pickleball');
  }

  String get surfaceTag {
    if (_isFootball) {
      return 'Cỏ FIFA';
    } else if (_isPickleball) {
      return 'Mặt USAPA';
    } else {
      return 'Thảm BWF';
    }
  }

  Color get _courtBaseColor {
    if (isInactive) {
      return const Color(0xFF334155); // Muted slate gray for inactive/maintenance
    }
    if (_isFootball) {
      return const Color(0xFF15803D); // Deep pitch green
    } else if (_isPickleball) {
      return const Color(0xFF0369A1); // Vibrant USAPA Court Blue
    }
    return const Color(0xFF047857); // Deep court green
  }

  Color get _neonAccentColor {
    if (isInactive) {
      return const Color(0xFFFBBF24); // Amber alert
    }
    if (_isFootball) {
      return const Color(0xFF4ADE80);
    } else if (_isPickleball) {
      return const Color(0xFF38BDF8);
    }
    return const Color(0xFF34D399);
  }

  @override
  Widget build(BuildContext context) {
    final CustomPainter courtPainter;
    if (_isFootball) {
      courtPainter = const FootballPitchPainter();
    } else if (_isPickleball) {
      courtPainter = const PickleballCourtPainter();
    } else {
      courtPainter = const BadmintonCourtPainter();
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: _courtBaseColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFF59E0B)
                  : Colors.white.withValues(alpha: 0.2),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
              if (isSelected)
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Authentic court lines via CustomPainter
                Positioned.fill(
                  child: CustomPaint(
                    painter: courtPainter,
                  ),
                ),

                // Center subtle vignette to improve badge contrast
                Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.8,
                      colors: [
                        Colors.black.withValues(alpha: 0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                // Overlay badge
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'SÂN $courtNumber',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 0.8,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 3,
                              color: Colors.black87,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _neonAccentColor.withValues(alpha: 0.8),
                            width: 0.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _neonAccentColor.withValues(alpha: 0.25),
                              blurRadius: 4,
                              spreadRadius: 0.5,
                            ),
                          ],
                        ),
                        child: Text(
                          isInactive ? '🔒 Tạm dừng' : surfaceTag,
                          style: TextStyle(
                            color: _neonAccentColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 9,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// CustomPainter rendering authentic Badminton BWF court markings.
class BadmintonCourtPainter extends CustomPainter {
  const BadmintonCourtPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const margin = 5.0;
    final court = Rect.fromLTWH(
      margin,
      margin,
      size.width - 2 * margin,
      size.height - 2 * margin,
    );

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final strongLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // 1. Outer boundary line (Doubles sidelines & back boundary)
    canvas.drawRect(court, strongLinePaint);

    // 2. Singles sidelines (inset horizontally from doubles sidelines)
    final singlesInset = court.width * 0.08;
    canvas.drawLine(
      Offset(court.left + singlesInset, court.top),
      Offset(court.left + singlesInset, court.bottom),
      linePaint,
    );
    canvas.drawLine(
      Offset(court.right - singlesInset, court.top),
      Offset(court.right - singlesInset, court.bottom),
      linePaint,
    );

    // 3. Long service lines for doubles (inset from top and bottom)
    final doublesServiceInset = court.height * 0.09;
    canvas.drawLine(
      Offset(court.left, court.top + doublesServiceInset),
      Offset(court.right, court.top + doublesServiceInset),
      linePaint,
    );
    canvas.drawLine(
      Offset(court.left, court.bottom - doublesServiceInset),
      Offset(court.right, court.bottom - doublesServiceInset),
      linePaint,
    );

    // 4. Center net line (dashed across court width)
    final centerY = court.center.dy;
    final netPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    const dashWidth = 3.5;
    const dashSpace = 2.5;
    double currentX = court.left - 2;
    final endX = court.right + 2;
    while (currentX < endX) {
      canvas.drawLine(
        Offset(currentX, centerY),
        Offset(math.min(currentX + dashWidth, endX), centerY),
        netPaint,
      );
      currentX += dashWidth + dashSpace;
    }

    // Net post markers at sidelines
    final postPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(court.left, centerY), 1.6, postPaint);
    canvas.drawCircle(Offset(court.right, centerY), 1.6, postPaint);

    // 5. Short service lines (above and below the net)
    final shortServiceDist = court.height * 0.21;
    final topShortService = centerY - shortServiceDist;
    final bottomShortService = centerY + shortServiceDist;

    canvas.drawLine(
      Offset(court.left, topShortService),
      Offset(court.right, topShortService),
      linePaint,
    );
    canvas.drawLine(
      Offset(court.left, bottomShortService),
      Offset(court.right, bottomShortService),
      linePaint,
    );

    // 6. Center line (dividing left and right service courts)
    final centerX = court.center.dx;
    // Top half center line (from back boundary to top short service line)
    canvas.drawLine(
      Offset(centerX, court.top),
      Offset(centerX, topShortService),
      linePaint,
    );
    // Bottom half center line (from bottom short service line to back boundary)
    canvas.drawLine(
      Offset(centerX, bottomShortService),
      Offset(centerX, court.bottom),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// CustomPainter rendering authentic Football FIFA pitch markings with mowed grass stripes.
class FootballPitchPainter extends CustomPainter {
  const FootballPitchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Mowed vertical grass stripes
    const stripeCount = 7;
    final stripeWidth = size.width / stripeCount;
    final darkStripePaint = Paint()
      ..color = const Color(0xFF14532D).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < stripeCount; i++) {
      if (i.isOdd) {
        canvas.drawRect(
          Rect.fromLTWH(i * stripeWidth, 0, stripeWidth, size.height),
          darkStripePaint,
        );
      }
    }

    // 2. Pitch boundary line
    const margin = 5.0;
    final pitch = Rect.fromLTWH(
      margin,
      margin,
      size.width - 2 * margin,
      size.height - 2 * margin,
    );

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final strongLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawRect(pitch, strongLinePaint);

    // 3. Halfway line & Center Circle & Center Spot
    final centerX = pitch.center.dx;
    final centerY = pitch.center.dy;

    canvas.drawLine(
      Offset(centerX, pitch.top),
      Offset(centerX, pitch.bottom),
      linePaint,
    );

    final centerCircleRadius = pitch.height * 0.28;
    canvas.drawCircle(Offset(centerX, centerY), centerCircleRadius, linePaint);

    final spotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, centerY), 1.2, spotPaint);

    // 4. Penalty Boxes (18-yard boxes on left and right)
    final penaltyBoxWidth = pitch.width * 0.20;
    final penaltyBoxHeight = pitch.height * 0.60;
    final penaltyBoxTop = centerY - penaltyBoxHeight / 2;

    final leftPenaltyBox = Rect.fromLTWH(
      pitch.left,
      penaltyBoxTop,
      penaltyBoxWidth,
      penaltyBoxHeight,
    );
    canvas.drawRect(leftPenaltyBox, linePaint);

    final rightPenaltyBox = Rect.fromLTWH(
      pitch.right - penaltyBoxWidth,
      penaltyBoxTop,
      penaltyBoxWidth,
      penaltyBoxHeight,
    );
    canvas.drawRect(rightPenaltyBox, linePaint);

    // 5. Goal Area (6-yard boxes)
    final goalAreaWidth = pitch.width * 0.08;
    final goalAreaHeight = pitch.height * 0.32;
    final goalAreaTop = centerY - goalAreaHeight / 2;

    final leftGoalArea = Rect.fromLTWH(
      pitch.left,
      goalAreaTop,
      goalAreaWidth,
      goalAreaHeight,
    );
    canvas.drawRect(leftGoalArea, linePaint);

    final rightGoalArea = Rect.fromLTWH(
      pitch.right - goalAreaWidth,
      goalAreaTop,
      goalAreaWidth,
      goalAreaHeight,
    );
    canvas.drawRect(rightGoalArea, linePaint);

    // 6. Penalty Arcs
    final arcRadius = pitch.height * 0.16;
    final leftArcRect = Rect.fromCircle(
      center: Offset(pitch.left + penaltyBoxWidth * 0.72, centerY),
      radius: arcRadius,
    );
    canvas.drawArc(
      leftArcRect,
      -math.pi / 2.6,
      math.pi / 1.3,
      false,
      linePaint,
    );

    final rightArcRect = Rect.fromCircle(
      center: Offset(pitch.right - penaltyBoxWidth * 0.72, centerY),
      radius: arcRadius,
    );
    canvas.drawArc(
      rightArcRect,
      math.pi - math.pi / 2.6,
      math.pi / 1.3,
      false,
      linePaint,
    );

    // 7. Corner Arcs
    const cornerRadius = 3.5;
    canvas.drawArc(
      Rect.fromCircle(center: pitch.topLeft, radius: cornerRadius),
      0,
      math.pi / 2,
      false,
      linePaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: pitch.topRight, radius: cornerRadius),
      math.pi / 2,
      math.pi / 2,
      false,
      linePaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: pitch.bottomRight, radius: cornerRadius),
      math.pi,
      math.pi / 2,
      false,
      linePaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: pitch.bottomLeft, radius: cornerRadius),
      3 * math.pi / 2,
      math.pi / 2,
      false,
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// CustomPainter rendering authentic Pickleball USAPA court markings with Non-Volley Zone (Kitchen).
class PickleballCourtPainter extends CustomPainter {
  const PickleballCourtPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const margin = 5.0;
    final court = Rect.fromLTWH(
      margin,
      margin,
      size.width - 2 * margin,
      size.height - 2 * margin,
    );

    // 1. Boundary line
    final boundaryPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRect(court, boundaryPaint);

    final centerX = court.center.dx;

    // 2. Non-Volley Zone (Kitchen) dimensions: 7ft / 44ft ≈ 15.9% each side from net
    final kitchenWidth = court.width * 0.16;

    // Kitchen zone tinted background (contrasting cyan/teal overlay)
    final kitchenRect = Rect.fromLTRB(
      centerX - kitchenWidth,
      court.top,
      centerX + kitchenWidth,
      court.bottom,
    );

    final kitchenPaint = Paint()
      ..color = const Color(0xFF0284C7).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawRect(kitchenRect, kitchenPaint);

    // 3. Center Net Line
    final netPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawLine(
      Offset(centerX, court.top),
      Offset(centerX, court.bottom),
      netPaint,
    );

    // 4. Non-Volley Lines (Kitchen Lines)
    canvas.drawLine(
      Offset(centerX - kitchenWidth, court.top),
      Offset(centerX - kitchenWidth, court.bottom),
      linePaint,
    );
    canvas.drawLine(
      Offset(centerX + kitchenWidth, court.top),
      Offset(centerX + kitchenWidth, court.bottom),
      linePaint,
    );

    // 5. Center Service Lines (from baseline to kitchen line on left and right)
    final centerY = court.center.dy;
    // Left service centerline
    canvas.drawLine(
      Offset(court.left, centerY),
      Offset(centerX - kitchenWidth, centerY),
      linePaint,
    );
    // Right service centerline
    canvas.drawLine(
      Offset(centerX + kitchenWidth, centerY),
      Offset(court.right, centerY),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

