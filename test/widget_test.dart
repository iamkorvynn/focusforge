import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:focusforge/main.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // Guarantee the app starts empty even if another test file ran first.
    final path = await getDatabasesPath();
    await databaseFactoryFfi.deleteDatabase('$path/focusforge.db');
  });

  // The controller runs a 1-second periodic ticker, so pumpAndSettle would
  // never settle. Pump fixed durations instead.
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const FocusForgeApp());
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
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
    await tester.pump();
    expect(find.text('Pause'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('24:58'), findsOneWidget);
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
