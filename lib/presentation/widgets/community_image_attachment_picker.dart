import 'package:flutter/material.dart';
import 'package:sporthub/core/constants/app_colors.dart';
import 'package:sporthub/core/utils/sport_image_catalog.dart';

class CommunityImageAttachmentPicker extends StatelessWidget {
  final String sportType;
  final String? selectedImageUrl;
  final ValueChanged<String?> onImageChanged;

  CommunityImageAttachmentPicker({
    super.key,
    required this.sportType,
    String? selectedImageUrl,
    String? initialImageUrl,
    required this.onImageChanged,
  }) : selectedImageUrl = selectedImageUrl ?? initialImageUrl;

  void _showCustomUrlDialog(BuildContext context) {
    final controller = TextEditingController(text: selectedImageUrl ?? '');
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Nhập liên kết ảnh',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            key: const Key('custom_image_url_field'),
            controller: controller,
            style: TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'https://images.unsplash.com/...',
              hintStyle:
                  TextStyle(color: AppColors.textSecondary, fontSize: 13),
              labelText: 'URL hình ảnh',
              labelStyle: TextStyle(color: AppColors.primary),
              filled: true,
              fillColor: AppColors.background,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child:
                  Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
            ),
            FilledButton(
              key: const Key('submit_image_url_button'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  onImageChanged(text);
                }
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                'Xác nhận',
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final presets = SportImageCatalog.getPresetsForSport(sportType);
    final hasSelectedImage =
        selectedImageUrl != null && selectedImageUrl!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Ảnh đính kèm / Ảnh check-in sân',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              key: const Key('custom_image_url_button'),
              onPressed: () => _showCustomUrlDialog(context),
              icon:
                  Icon(Icons.link_rounded, size: 16, color: AppColors.primary),
              label: Text(
                'Nhập URL ảnh',
                style: TextStyle(fontSize: 12, color: AppColors.primary),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        if (hasSelectedImage) ...[
          const SizedBox(height: 8),
          Container(
            key: const Key('selected_image_preview'),
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.6), width: 1.5),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.5),
                  child: Image.network(
                    selectedImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.surface,
                      child: Center(
                        child: Icon(Icons.broken_image_rounded,
                            color: AppColors.textSecondary, size: 36),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: InkWell(
                    key: const Key('remove_attached_image'),
                    onTap: () => onImageChanged(null),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.close_rounded,
                              size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Gỡ ảnh',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        SizedBox(
          key: const Key('image_preset_carousel'),
          height: 68,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: presets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final presetUrl = presets[index];
              final isSelected = selectedImageUrl == presetUrl;

              return GestureDetector(
                key: Key('image_preset_$index'),
                onTap: () => onImageChanged(presetUrl),
                child: Container(
                  width: 92,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.primary : AppColors.cardBorder,
                      width: isSelected ? 2.5 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.5),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          presetUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.surface,
                            child: Center(
                              child: Icon(Icons.sports_rounded,
                                  size: 22, color: AppColors.primary),
                            ),
                          ),
                        ),
                        if (isSelected)
                          Container(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            child: Center(
                              child: Icon(Icons.check_circle_rounded,
                                  color: AppColors.primary, size: 22),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
