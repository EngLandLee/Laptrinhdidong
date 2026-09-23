import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/presentation/widgets/community_image_attachment_picker.dart';

void main() {
  testWidgets('CommunityImageAttachmentPicker renders preset options and allows selection and removal', (tester) async {
    String? currentImage;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return CommunityImageAttachmentPicker(
                sportType: 'badminton',
                selectedImageUrl: currentImage,
                onImageChanged: (url) {
                  setState(() => currentImage = url);
                },
              );
            },
          ),
        ),
      ),
    );

    // Initial state: presets carousel should exist
    expect(find.byKey(const Key('image_preset_carousel')), findsOneWidget);
    expect(find.byKey(const Key('image_preset_0')), findsOneWidget);

    // Tap preset 0
    await tester.tap(find.byKey(const Key('image_preset_0')));
    await tester.pumpAndSettle();

    // Now preview with remove button should appear
    expect(find.byKey(const Key('selected_image_preview')), findsOneWidget);
    expect(find.byKey(const Key('remove_attached_image')), findsOneWidget);

    // Tap remove
    await tester.tap(find.byKey(const Key('remove_attached_image')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('selected_image_preview')), findsNothing);
  });

  testWidgets('CommunityImageAttachmentPicker allows entering custom image URL', (tester) async {
    String? currentImage;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return CommunityImageAttachmentPicker(
                sportType: 'pickleball',
                selectedImageUrl: currentImage,
                onImageChanged: (url) {
                  setState(() => currentImage = url);
                },
              );
            },
          ),
        ),
      ),
    );

    // Find custom image url button
    final customUrlBtn = find.byKey(const Key('custom_image_url_button'));
    expect(customUrlBtn, findsOneWidget);

    // Tap custom image url button to open dialog
    await tester.tap(customUrlBtn);
    await tester.pumpAndSettle();

    // Dialog should be displayed with text field and confirmation button
    expect(find.byKey(const Key('custom_image_url_field')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('custom_image_url_field')), 'https://example.com/court.jpg');
    await tester.pumpAndSettle();

    final submitBtn = find.byKey(const Key('submit_image_url_button'));
    expect(submitBtn, findsOneWidget);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    // Selected preview should now show with custom image URL
    expect(currentImage, 'https://example.com/court.jpg');
    expect(find.byKey(const Key('selected_image_preview')), findsOneWidget);
  });

  testWidgets('CommunityImageAttachmentPicker handles prefilled initialImageUrl', (tester) async {
    String? currentImage = 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return CommunityImageAttachmentPicker(
                sportType: 'badminton',
                initialImageUrl: currentImage,
                onImageChanged: (url) {
                  setState(() => currentImage = url);
                },
              );
            },
          ),
        ),
      ),
    );

    // Initial state: preview already shown with remove button
    expect(find.byKey(const Key('selected_image_preview')), findsOneWidget);
    expect(find.byKey(const Key('remove_attached_image')), findsOneWidget);

    // Tap remove
    await tester.tap(find.byKey(const Key('remove_attached_image')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('selected_image_preview')), findsNothing);
    expect(currentImage, isNull);
  });
}
