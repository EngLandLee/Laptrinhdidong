import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/entities/venue_addon.dart';

class _CategoryTab {
  final String label;
  final AddonCategory? category;
  const _CategoryTab(this.label, this.category);
}

class VenueAddonSelector extends StatefulWidget {
  final List<VenueAddonItem> items;
  final Map<String, int> selectedCounts;
  final void Function(VenueAddonItem item, int quantity) onQuantityChanged;

  const VenueAddonSelector({
    super.key,
    required this.items,
    required this.selectedCounts,
    required this.onQuantityChanged,
  });

  @override
  State<VenueAddonSelector> createState() => _VenueAddonSelectorState();
}

class _VenueAddonSelectorState extends State<VenueAddonSelector> {
  AddonCategory? _selectedCategory;

  static const List<_CategoryTab> _categories = [
    _CategoryTab('Tất cả', null),
    _CategoryTab('🏸 Thuê dụng cụ', AddonCategory.rental),
    _CategoryTab('🥤 Nước & Căng tin', AddonCategory.beverage),
    _CategoryTab('🎾 Phụ kiện', AddonCategory.gear),
  ];

  @override
  Widget build(BuildContext context) {
    final displayedItems = _selectedCategory == null
        ? widget.items
        : widget.items.where((i) => i.category == _selectedCategory).toList();

    int totalAddonPrice = 0;
    int totalCount = 0;
    for (final item in widget.items) {
      final count = widget.selectedCounts[item.id] ?? 0;
      if (count > 0) {
        totalCount += count;
        totalAddonPrice += (item.price * count).toInt();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Category Pills
        _buildCategoryFilters(),
        const SizedBox(height: 14),

        // Items list
        if (displayedItems.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Center(
              child: Text(
                'Không có dịch vụ nào trong danh mục này',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          )
        else
          ...displayedItems.map(_buildItemCard),

        // Subtotal Display
        if (totalCount > 0) _buildSubtotalBanner(totalAddonPrice, totalCount),
      ],
    );
  }

  Widget _buildCategoryFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _categories.map((tab) {
          final isSelected = _selectedCategory == tab.category;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedCategory = tab.category;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.18)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        isSelected ? AppColors.primary : AppColors.cardBorder,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Text(
                  tab.label,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildItemCard(VenueAddonItem item) {
    final qty = widget.selectedCounts[item.id] ?? 0;
    final isSelected = qty > 0;

    return Semantics(
      label:
          '${item.name}, giá ${CurrencyFormatter.formatWithUnit(item.price, item.unit)}, đang chọn $qty ${item.unit}',
      child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.surface
            : AppColors.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.cardBorder,
          width: isSelected ? 1.5 : 1.0,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Icon box with dark card background
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : AppColors.cardBorder,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              item.icon,
              style: const TextStyle(fontSize: 22),
            ),
          ),
          const SizedBox(width: 12),
          // Item Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  CurrencyFormatter.formatWithUnit(item.price, item.unit),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.description,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Stepper Control
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                key: Key('addon_dec_${item.id}'),
                tooltip: 'Giảm số lượng',
                icon: const Icon(Icons.remove_circle_outline),
                iconSize: 24,
                color: isSelected
                    ? AppColors.error
                    : AppColors.textSecondary.withValues(alpha: 0.3),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: isSelected
                    ? () {
                        HapticFeedback.lightImpact();
                        widget.onQuantityChanged(item, qty - 1);
                      }
                    : null,
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 26),
                alignment: Alignment.center,
                child: Text(
                  '$qty',
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              IconButton(
                key: Key('addon_inc_${item.id}'),
                tooltip: 'Tăng số lượng',
                icon: const Icon(Icons.add_circle_outline),
                iconSize: 24,
                color: AppColors.primary,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.onQuantityChanged(item, qty + 1);
                },
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _buildSubtotalBanner(int subtotal, int totalCount) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Tạm tính dịch vụ ($totalCount):',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Text(
            CurrencyFormatter.format(subtotal),
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
