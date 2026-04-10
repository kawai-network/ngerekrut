import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ngerekrut/main.dart';

void main() {
  testWidgets('recruiter home renders primary actions', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MyApp());

    expect(find.text('NgeRekrut'), findsOneWidget);
    expect(find.text('Bikin Lowongan (Chat)'), findsOneWidget);
    expect(find.text('AI Hiring Assistant'), findsOneWidget);
  });
}
