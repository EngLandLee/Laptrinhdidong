import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/time_slot.dart';
import 'visual_court_header.dart';
import 'visual_court_slot_cell.dart';

class TimeSlotMatrix extends StatefulWidget {
  final List<TimeSlot> slots;
  final Set<String> selectedSlotIds;
  final Function(TimeSlot) onSlotTapped;
  final String sportType;
  final Map<int, String>? courtSportMap;
  final Set<int>? inactiveCourts;

  const TimeSlotMatrix({
    super.key,
    required this.slots,
    required this.selectedSlotIds,
    required this.onSlotTapped,
    this.sportType = 'badminton',
    this.courtSportMap,
    this.inactiveCourts,
  });

  @override
  State<TimeSlotMatrix> createState() => _TimeSlotMatrixState();
}

class _TimeSlotMatrixState extends State<TimeSlotMatrix> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  void _scrollCourts(double delta) {
    if (!_horizontalController.hasClients) return;
    final maxScroll = _horizontalController.position.maxScrollExtent;
    final target = (_horizontalController.offset + delta).clamp(0.0, maxScroll);
    _horizontalController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  String _getSportForCourt(int court) {
    return widget.courtSportMap?[court] ?? widget.sportType;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.slots.isEmpty) {
      return Container(
        color: AppColors.surface,
        alignment: Alignment.center,
        child: Text(
          'Không có khung giờ nào',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    // Extract sorted unique court numbers
    final courtNumbers = widget.slots.map((s) => s.courtNumber).toSet().toList()
      ..sort();

    // Extract sorted unique time frames
    final timeFrames = widget.slots
        .map((s) => '${s.startTime} - ${s.endTime}')
        .toSet()
        .toList()
      ..sort();

    // Fast lookup map: [timeFrame][courtNumber] -> TimeSlot
    final Map<String, Map<int, TimeSlot>> matrix = {};
    for (final slot in widget.slots) {
      final timeKey = '${slot.startTime} - ${slot.endTime}';
      matrix.putIfAbsent(timeKey, () => {})[slot.courtNumber] = slot;
    }

    return Container(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Navigation toolbar for multiple courts
          if (courtNumbers.length > 2)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.isDark
                    ? const Color(0xFF161F30)
                    : const Color(0xFFF1F5F9),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.cardBorder.withValues(alpha: 0.6),
                    width: 0.8,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.swap_horiz_rounded,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Tổng ${courtNumbers.length} sân (Sân 1 - ${courtNumbers.last})',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        key: const Key('court_scroll_left'),
                        onTap: () => _scrollCourts(-256.0),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: AppColors.isDark
                                ? const Color(0xFF1E293B)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chevron_left_rounded,
                                  size: 15, color: AppColors.textPrimary),
                              Text('Trước',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textPrimary)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        key: const Key('court_scroll_right'),
                        onTap: () => _scrollCourts(256.0),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color:
                                    AppColors.primary.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Sau',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded,
                                  size: 15, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // 2. Matrix 2D Scrollable Grid with Scrollbars
          Expanded(
            child: Scrollbar(
              controller: _verticalController,
              thumbVisibility: false,
              child: SingleChildScrollView(
                controller: _verticalController,
                scrollDirection: Axis.vertical,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Scrollbar(
                  controller: _horizontalController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  child: SingleChildScrollView(
                    controller: _horizontalController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row with court numbers
                        Row(
                          children: [
                            Container(
                              width: 110,
                              height: 72,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.access_time_rounded,
                                      size: 18, color: AppColors.textSecondary),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Khung giờ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...courtNumbers.map(
                              (court) => Container(
                                width: 120,
                                height: 72,
                                margin: const EdgeInsets.only(left: 8),
                                child: VisualCourtHeader(
                                  courtNumber: court,
                                  sportType: _getSportForCourt(court),
                                  width: 120,
                                  height: 72,
                                  isInactive: widget.inactiveCourts?.contains(court) == true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Rows for each distinct time range
                        ...timeFrames.map(
                          (timeFrame) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 110,
                                  height: 74,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 6, horizontal: 6),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.isDark
                                        ? const Color(0xFF1E293B)
                                            .withValues(alpha: 0.6)
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: AppColors.cardBorder),
                                  ),
                                  child: Text(
                                    timeFrame,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: AppColors.isDark
                                          ? AppColors.textSecondary
                                          : const Color(0xFF334155),
                                    ),
                                  ),
                                ),
                                ...courtNumbers.map((court) {
                                  final slot = matrix[timeFrame]?[court];
                                  if (slot == null) {
                                    return Container(
                                      width: 120,
                                      height: 74,
                                      margin: const EdgeInsets.only(left: 8),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface
                                            .withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: AppColors.cardBorder
                                                .withValues(alpha: 0.5)),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text('-',
                                          style: TextStyle(
                                              color: AppColors.textSecondary)),
                                    );
                                  }

                                  final isSelected =
                                      widget.selectedSlotIds.contains(slot.id);

                                  return Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    child: VisualCourtSlotCell(
                                      slot: slot,
                                      sportType: _getSportForCourt(court),
                                      isSelected: isSelected,
                                      onTap: () => widget.onSlotTapped(slot),
                                      width: 120,
                                      height: 74,
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
