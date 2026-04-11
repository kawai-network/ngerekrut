import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ngerekrut/app/recruiter_app.dart';

void main() {
  testWidgets('recruiter home renders primary actions', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const RecruiterApp());

    expect(find.text('NgeRekrut'), findsOneWidget);
    expect(find.text('Percakapan'), findsOneWidget);
    expect(find.text('Daftar Sesi'), findsOneWidget);
    expect(find.text('Chat Baru'), findsOneWidget);
  });
}
