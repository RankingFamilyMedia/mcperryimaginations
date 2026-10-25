import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:autoyaad_ghana/main.dart';

void main() {
  testWidgets('startup displays the ready application',
      (WidgetTester tester) async {
    await tester.pumpWidget(StartupApp(
      initialize: () async {},
      ready: const MaterialApp(home: Text('AutoYaad is ready')),
    ));
    await tester.pump();

    expect(find.text('AutoYaad is ready'), findsOneWidget);
  });
}
