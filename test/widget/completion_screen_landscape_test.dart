import 'package:ayutam/features/timer/presentation/completion_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness({
    VoidCallback? onSave,
    VoidCallback? onResume,
    VoidCallback? onDiscard,
  }) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Session complete')),
        body: CompletionBody(
          activeSeconds: 125,
          onSave: onSave ?? () {},
          onResume: onResume ?? () {},
          onDiscard: onDiscard ?? () {},
        ),
      ),
    );
  }

  Future<void> pumpAtSize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();
  }

  void expectNoScrollNeeded(WidgetTester tester) {
    final scrollable = tester.widget<Scrollable>(find.byType(Scrollable));
    final position = scrollable.controller?.position;
    if (position != null) {
      expect(position.maxScrollExtent, 0);
    }
    final viewportBottom = tester.getRect(find.byType(CompletionBody)).bottom;
    for (final label in ['Save', 'Resume', 'Discard']) {
      expect(
        tester.getBottomLeft(find.text(label)).dy,
        lessThanOrEqualTo(viewportBottom),
        reason: '$label must be visible without scrolling',
      );
    }
  }

  testWidgets('all buttons visible without scrolling in portrait', (
    tester,
  ) async {
    await pumpAtSize(tester, const Size(400, 800));
    expect(tester.takeException(), isNull);
    expectNoScrollNeeded(tester);
  });

  testWidgets('all buttons visible without scrolling in normal landscape', (
    tester,
  ) async {
    await pumpAtSize(tester, const Size(1024, 500));
    expect(tester.takeException(), isNull);
    expectNoScrollNeeded(tester);
  });

  testWidgets('completion screen fits short landscape without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    var saveTapped = false;
    var resumeTapped = false;
    var discardTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Session complete')),
          body: CompletionBody(
            activeSeconds: 125,
            onSave: () => saveTapped = true,
            onResume: () => resumeTapped = true,
            onDiscard: () => discardTapped = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Resume'), findsOneWidget);
    expect(find.text('Discard'), findsOneWidget);

    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.ensureVisible(find.text('Resume'));
    await tester.tap(find.text('Resume'));
    await tester.ensureVisible(find.text('Discard'));
    await tester.tap(find.text('Discard'));
    await tester.pump();

    expect(saveTapped, isTrue);
    expect(resumeTapped, isTrue);
    expect(discardTapped, isTrue);
    expect(tester.takeException(), isNull);
  });
}
