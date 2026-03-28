import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/app/app.dart';

void main() {
  testWidgets('PledgeFit app builds', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: StartupApp()),
    );
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
