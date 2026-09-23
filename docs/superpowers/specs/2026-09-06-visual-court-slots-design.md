# Visual Court Slot Graphics Design Specification

## Overview
This document specifies the design and implementation for rendering realistic sports court graphics (Badminton BWF mat and Football FIFA turf markings) directly inside every individual slot cell of the booking grid matrix (`TimeSlotMatrix`).

## Context & User Problem
Previously, realistic court graphics (`VisualCourtHeader`) were only displayed in the column headers of the matrix and the 2D cluster map. The individual time-slot cells in the booking matrix were plain colored containers (`#064E3B`, `#78350F`, `#450A0A`). The user requested that every single slot cell should display the authentic court graphic directly as its visual foundation while clearly indicating booking states.

## Key Design Principles
1. **Immersive Sport Aesthetic**: Every slot cell renders realistic badminton court lines (boundary, center line, short/long service lines, net) or football turf markings (stripes, center circle, penalty box) via hardware-accelerated `CustomPainter`.
2. **High-Contrast Readability**: White court lines must never interfere with the readability of price tags or state indicators. A subtle radial/box vignette and semi-transparent pill overlay ensures 100% legibility.
3. **State Distinction**:
   - **Còn trống (Available)**: Crisp sports green base (`#047857` for badminton, `#15803D` for football) with emerald neon border (`#10B981`) and soft emerald glow. Displays price and `Còn trống` badge.
   - **Đang chọn (Selected)**: Amber tinted court overlay (`#F59E0B` with alpha), radiant amber glowing border, amber checkmark icon `✓`, price, and `Đang chọn` badge.
   - **Đã đặt (Booked)**: Dimmed dark overlay (`#0B0F19` with alpha 0.75 + dark red undertone `#450A0A`), lock icon `🔒`, and `Đã đặt` badge. Tap interactions disabled.
4. **Performance & Clean Layout**: Maintains standard cell dimensions (`120px` width x `74px` height) with smooth 60fps canvas rendering and scroll performance across both web and mobile viewports.

## Component Architecture
- `lib/presentation/widgets/visual_court_header.dart`:
  - Contains `BadmintonCourtPainter` and `FootballPitchPainter`.
  - Export painters and utility functions for reusability.
- `lib/presentation/widgets/time_slot_matrix.dart`:
  - Update slot cell builder to wrap each cell in a `ClipRRect` and render `CustomPaint(painter: courtPainter)`.
  - Add tinted overlay layer depending on `isSelected`, `isBooked`, or available.
  - Render contrast pill badge containing price and status badge.
- `test/presentation/widgets/time_slot_matrix_test.dart`:
  - Verify that `CustomPaint` is rendered for slot cells.
  - Verify state styling for available, selected, and booked slots.

## Verification & Testing
1. Unit and widget tests must assert that slot cells render with the visual court painter.
2. Verify all 55 existing tests continue to pass.
3. Verify `flutter analyze` has 0 issues.
