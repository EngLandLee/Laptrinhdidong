import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/venue.dart';
import 'chatbot_bottom_sheet.dart';

/// Floating AI Chatbot trigger bubble with context badge and subtle glow.
class FloatingChatBubble extends StatelessWidget {
  final Venue? currentVenue;
  final String currentRoute;
  final DateTime? selectedDate;
  final VoidCallback? onTap;
  final Function(Map<String, dynamic> actionCard)? onBookNowAction;
  final Function(Map<String, dynamic> actionCard)? onViewCourtMapAction;

  const FloatingChatBubble({
    super.key = const Key('floating_chat_bubble'),
    this.currentVenue,
    this.currentRoute = '/home',
    this.selectedDate,
    this.onTap,
    this.onBookNowAction,
    this.onViewCourtMapAction,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Trợ lý AI SportHub',
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.38),
              blurRadius: 14,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              if (onTap != null) {
                onTap!();
              } else {
                ChatbotBottomSheet.show(
                  context,
                  currentVenue: currentVenue,
                  currentRoute: currentRoute,
                  selectedDate: selectedDate,
                  onBookNowAction: onBookNowAction,
                  onViewCourtMapAction: onViewCourtMapAction,
                );
              }
            },
            child: Ink(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: AppColors.onPrimary,
                    size: 26,
                  ),
                  // AI Ready Badge
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber[800],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.white,
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'AI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
                    ),
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
