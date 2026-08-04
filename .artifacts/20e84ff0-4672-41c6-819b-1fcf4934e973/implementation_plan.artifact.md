# Implementation Plan - Fix Layout Overflow in Student Dashboard

The user reported a `RenderFlex` overflow in the Student Dashboard, specifically in the "Primary Action Bar" (Sandbox Launcher) when the screen is narrow (e.g., mobile view).

## User Review Required

> [!IMPORTANT]
> The fix involves changing the layout from a `Row` to a `Column` on narrow screens (less than 650px). This will cause the Sandbox launcher text and buttons to stack vertically on mobile.

## Proposed Changes

### Dashboard Feature

#### [MODIFY] [student_dashboard.dart](file:///C:/Users/Admin/Desktop/virtuanetlab/lib/features/dashboard/screens/student_dashboard.dart)

- Wrap the "Primary Action Bar" content in a `LayoutBuilder` to detect available width.
- Switch from `Row` to `Column` when `constraints.maxWidth < 650`.
- Update the title row for "Free Practice Progression" (line 406) to use `Expanded` for the title to prevent potential overflows there as well.
- Audit and apply similar `Expanded` or `Wrap` fixes to other minor `Row` widgets in the file (e.g., Level Cards) if they appear risky.

## Verification Plan

### Manual Verification
- Resize the browser/emulator to a narrow width (e.g., 320px - 400px) and verify the "Primary Action Bar" stacks correctly and does not overflow.
- Verify the "Free Practice Progression" section does not overflow.
- Check the dashboard on a wider screen (desktop view) to ensure the layout remains as intended (horizontal layout).
