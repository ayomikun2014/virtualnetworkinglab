# Implementation Plan - Fix Canvas Layout Overflow on Mobile

The user reported a `RenderFlex` overflow (approx. 150px) on the canvas screen on mobile. This is likely caused by the fixed-width sidebars (`DevicePalette` at 220px and `NodePropertyInspector` at 320px) being placed in a horizontal `Row` with the canvas, which exceeds the width of mobile screens.

## User Review Required

> [!IMPORTANT]
> On mobile devices (width < 900px), the sidebars will now **overlay** the canvas instead of pushing it. This ensures the canvas remains accessible and no overflow occurs, but it means parts of the canvas will be covered when a sidebar is open.

## Proposed Changes

### Topology Feature

#### [MODIFY] [canvas_builder_screen.dart](file:///C:/Users/Admin/Desktop/virtuanetlab/lib/features/topology/screens/canvas_builder_screen.dart)

- Wrap the main workspace area (Sidebar + Canvas + Inspector) in a `LayoutBuilder`.
- Implement a responsive layout:
    - **Desktop (> 900px)**: Maintain the current `Row` layout where sidebars and canvas share horizontal space.
    - **Mobile/Tablet (< 900px)**: Use a `Stack` where the canvas is the background (full-width) and sidebars are positioned as overlays.
- Ensure `DevicePalette` and `NodePropertyInspector` are positioned at the left and right edges respectively when in overlay mode.
- Add a subtle backdrop or shadow to overlays to differentiate them from the canvas background.

## Verification Plan

### Manual Verification
- Resize the browser or use a mobile emulator to trigger the narrow layout.
- Open the Device Palette and select a node to open the Inspector simultaneously.
- Verify that **no RenderFlex overflow** occurs and that both overlays are visible.
- Verify that on desktop, the layout still uses the side-by-side `Row` configuration.
