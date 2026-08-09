import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:virtuanetlab/core/widgets/app_notification.dart';

/// Pumps a trivial app and hands back a context that sits under an Overlay,
/// which is what AppNotifier inserts into.
Future<BuildContext> _pumpHost(WidgetTester tester) async {
  late BuildContext captured;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox.expand();
          },
        ),
      ),
    ),
  );
  return captured;
}

void main() {
  testWidgets('a notification appears and then dismisses itself', (
    tester,
  ) async {
    final context = await _pumpHost(tester);

    AppNotifier.success(context, 'Saved as "My canvas"');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Saved as "My canvas"'), findsOneWidget);

    // Past the 4s display window plus the exit animation.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(
      find.text('Saved as "My canvas"'),
      findsNothing,
      reason: 'it must clear itself without the student doing anything',
    );
  });

  testWidgets('tapping a notification dismisses it early', (tester) async {
    final context = await _pumpHost(tester);

    AppNotifier.error(context, 'Could not check the canvas.');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Could not check the canvas.'), findsOneWidget);

    await tester.tap(find.text('Could not check the canvas.'));
    await tester.pumpAndSettle();

    expect(find.text('Could not check the canvas.'), findsNothing);
  });

  testWidgets('several notifications stack instead of covering each other', (
    tester,
  ) async {
    final context = await _pumpHost(tester);

    AppNotifier.info(context, 'First message');
    AppNotifier.info(context, 'Second message');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('First message'), findsOneWidget);
    expect(find.text('Second message'), findsOneWidget);

    final firstY = tester.getTopLeft(find.text('First message')).dy;
    final secondY = tester.getTopLeft(find.text('Second message')).dy;

    expect(
      secondY,
      greaterThan(firstY),
      reason: 'the newer one sits below the older one, not on top of it',
    );

    // Both still tear down cleanly, leaving no orphaned overlay entries.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('First message'), findsNothing);
    expect(find.text('Second message'), findsNothing);
  });

  testWidgets('notifications render above the page, near the top', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final context = await _pumpHost(tester);

    AppNotifier.info(context, 'Top anchored');
    await tester.pump();
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    final y = tester.getTopLeft(find.text('Top anchored')).dy;
    expect(
      y,
      lessThan(150),
      reason: 'the whole point is that it pops at the top, not the bottom',
    );
  });
}
