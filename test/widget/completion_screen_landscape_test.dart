import 'package:ayutam/features/timer/presentation/completion_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
