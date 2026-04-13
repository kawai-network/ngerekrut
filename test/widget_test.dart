import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ngerekrut/app/recruiter_app.dart';

void main() {
  testWidgets('recruiter home renders recruiter tabs', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const RecruiterApp(enableAIInitialization: false),
    );
    await tester.pump();

    expect(find.text('NgeRekrut'), findsOneWidget);
    expect(find.text('Inbox recruiter'), findsOneWidget);
    expect(find.text('Lowongan'), findsWidgets);
    expect(find.text('Screening'), findsOneWidget);
    expect(find.text('Tes'), findsOneWidget);
    expect(find.text('Interview'), findsOneWidget);
  });
}
