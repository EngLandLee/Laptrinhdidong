import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/entities/time_slot.dart';
import 'visual_court_header.dart';

class VisualCourtSlotCell extends StatelessWidget {
  final TimeSlot slot;
  final String sportType;
  final bool isSelected;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const VisualCourtSlotCell({
    super.key,
    required this.slot,
    required this.sportType,
    required this.isSelected,
    this.onTap,
    this.width = 120,
    this.height = 74,
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

  Color get _courtBaseColor {
    if (_isFootball) {
      return const Color(0xFF15803D); // Deep pitch green
    } else if (_isPickleball) {
      return const Color(0xFF0369A1); // Vibrant USAPA Court Blue
    }
    return const Color(0xFF047857); // Deep court green
  }

  @override
  Widget build(BuildContext context) {
    final isBooked = slot.status == SlotStatus.booked;
    final CustomPainter courtPainter;
    if (_isFootball) {
      courtPainter = const FootballPitchPainter();
    } else if (_isPickleball) {
      courtPainter = const PickleballCourtPainter();
    } else {
      courtPainter = const BadmintonCourtPainter();
    }

    final Color borderColor;
    final double borderWidth;
    final List<BoxShadow>? shadows;
    final Color overlayColor;
    final Widget statusWidget;

    if (isSelected) {
      borderColor = AppColors.slotSelected;
      borderWidth = 1.8;
      overlayColor = const Color(0xFFF59E0B).withValues(alpha: 0.35);
      shadows = [
        BoxShadow(
          color: AppColors.slotSelected.withValues(alpha: 0.4),
          blurRadius: 8,
          spreadRadius: 1,
        ),
      ];
      statusWidget = FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, size: 12, color: Colors.amber),
            const SizedBox(width: 3),
            Text(
              'Đang chọn',
              style: TextStyle(
                color: Colors.amber.shade200,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                shadows: const [
                  Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (isBooked) {
      borderColor = Colors.red.withValues(alpha: 0.4);
      borderWidth = 1.0;
      overlayColor = const Color(0xFF0F172A).withValues(alpha: 0.78);
      shadows = null;
      statusWidget = FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_rounded, size: 12, color: Colors.red.shade300),
            const SizedBox(width: 3),
            Text(
              'Đã đặt',
              style: TextStyle(
                color: Colors.red.shade200,
                fontWeight: FontWeight.w600,
                fontSize: 11,
                shadows: const [
                  Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (slot.status == SlotStatus.locked) {
      borderColor = const Color(0xFFF59E0B).withValues(alpha: 0.5);
      borderWidth = 1.0;
      overlayColor = const Color(0xFF1E293B).withValues(alpha: 0.85);
      shadows = null;
      statusWidget = FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build_circle_outlined, size: 12, color: Colors.amber.shade300),
            const SizedBox(width: 3),
            Text(
              'Tạm dừng',
              style: TextStyle(
                color: Colors.amber.shade200,
                fontWeight: FontWeight.w600,
                fontSize: 11,
                shadows: const [
                  Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Available
      borderColor = AppColors.slotAvailable.withValues(alpha: 0.85);
      borderWidth = 1.2;
      overlayColor = Colors.transparent;
      shadows = [
        BoxShadow(
          color: AppColors.slotAvailable.withValues(alpha: 0.2),
          blurRadius: 6,
          spreadRadius: 0,
        ),
      ];
      statusWidget = FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.slotAvailable,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              'Còn trống',
              style: TextStyle(
                color: AppColors.slotAvailable,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                shadows: [
                  Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final statusDescription = isSelected
        ? 'Đang chọn'
        : isBooked
            ? 'Đã đặt'
            : slot.status == SlotStatus.locked
                ? 'Tạm dừng bảo trì'
                : 'Còn trống';
    final semanticLabel =
        'Sân ${slot.courtNumber}, khung giờ ${slot.startTime} đến ${slot.endTime}, giá ${CurrencyFormatter.format(slot.price)}, trạng thái: $statusDescription';

    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: slot.isAvailable,
      selected: isSelected,
      hint: slot.isAvailable
          ? (isSelected ? 'Nhấn đúp để hủy chọn' : 'Nhấn đúp để chọn ca sân này')
          : 'Ca sân hiện không thể chọn',
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: _courtBaseColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: shadows,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Realistic Court Vector Graphics
              Positioned.fill(
                child: CustomPaint(
                  painter: courtPainter,
                ),
              ),

              // 2. Subtle vignette layer for contrast / legibility
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.85,
                      colors: [
                        Colors.black.withValues(alpha: 0.45),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Tinted overlay according to state
              if (overlayColor != Colors.transparent)
                Positioned.fill(
                  child: Container(color: overlayColor),
                ),

              // 3. Center pill with high contrast readability
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.68),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.slotSelected.withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.15),
                    width: 0.8,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        CurrencyFormatter.format(slot.price),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                          color: isBooked
                              ? Colors.white60
                              : Colors.white,
                          shadows: const [
                            Shadow(offset: Offset(0, 1), blurRadius: 3, color: Colors.black),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    statusWidget,
                  ],
                ),
              ),

              // 4. InkWell overlay for ripple effect
              Material(
                color: Colors.transparent,
                child: InkWell(
                  key: Key('slot_${slot.id}'),
                  onTap: slot.isAvailable
                      ? () {
                          HapticFeedback.selectionClick();
                          onTap?.call();
                        }
                      : null,
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
