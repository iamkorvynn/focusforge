import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:focusforge/db/database_helper.dart';
import 'package:focusforge/main.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // In-memory database: this file never touches the real database file,
    // so it cannot disturb other test files running in parallel.
    DatabaseHelper.useInMemory = true;
  });

  // The controller's init() does real async work (database open) which
  // only progresses in real time, while its continuations only run on
  // pump. Alternate runAsync delays with pumps until the app is ready.
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const FocusForgeApp());
    for (var i = 0; i < 30; i++) {
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump();
      if (find.text('FocusForge').evaluate().isNotEmpty) return;
    }
  }

  testWidgets('app starts empty on the timer with 25:00', (tester) async {
    await pumpApp(tester);
    expect(find.text('FocusForge'), findsWidgets);
    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Focus'), findsWidgets);
  });

  testWidgets('start button begins the countdown', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Start'));
    // The ticker fires on the next fake second and rebuilds the screen.
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Pause'), findsOneWidget);
    // Let two real seconds pass, then let the ticker fire: the countdown
    // is wall-clock based, so the time must have moved off 25:00.
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(seconds: 2));
    });
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('25:00'), findsNothing);
    expect(find.text('Pause'), findsOneWidget);
  });

  testWidgets('tasks tab shows the empty state', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Tasks'));
    await tester.pump();
    expect(find.text('No tasks yet'), findsOneWidget);
  });

  testWidgets('stats tab shows the empty state', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Stats'));
    await tester.pump();
    expect(find.text('No sessions yet'), findsOneWidget);
  });

  testWidgets('settings tab shows the durations', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Settings'));
    await tester.pump();
    expect(find.text('Focus session'), findsOneWidget);
    expect(find.text('Daily goal'), findsOneWidget);
  });
}
