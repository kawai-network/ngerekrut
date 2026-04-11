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
    expect(find.text('Workflow Utama'), findsOneWidget);
    expect(find.text('Buat Lowongan'), findsAtLeastNWidgets(1));
    expect(find.text('Asisten Recruiter'), findsAtLeastNWidgets(1));
  });
}
