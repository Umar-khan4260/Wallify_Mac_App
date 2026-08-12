import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wallify/data/search_history_service.dart';
import 'package:wallify/widgets/search_field.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SearchHistoryService.instance.init();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SearchField())),
    );
    await tester.pump();
  }

  Future<void> openDropdown(WidgetTester tester) async {
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('history row tap fills field and triggers search', (tester) async {
    await SearchHistoryService.instance.addSearch('aurora');
    await SearchHistoryService.instance.addSearch('mountains');
    await pumpApp(tester);

    await openDropdown(tester);

    expect(find.text('mountains'), findsOneWidget);

    await tester.tap(find.text('mountains'));
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'mountains',
    );
    expect(find.text('Clear all'), findsNothing);
  });

  testWidgets('Clear all in dropdown clears history and closes', (tester) async {
    await SearchHistoryService.instance.addSearch('aurora');
    await SearchHistoryService.instance.addSearch('mountains');
    await pumpApp(tester);

    await openDropdown(tester);

    expect(find.text('Clear all'), findsOneWidget);

    await tester.tap(find.text('Clear all'));
    await tester.pump();

    expect(SearchHistoryService.instance.listenable.value, isEmpty);
    expect(find.text('Clear all'), findsNothing);
  });
}
