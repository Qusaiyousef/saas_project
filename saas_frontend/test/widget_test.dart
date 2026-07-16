import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saas_frontend/main.dart';

void main() {
  testWidgets('Login screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: SaasApp()));
    await tester.pumpAndSettle();

    // Verify that the login title exists.
    expect(find.text('Smart Booking System'), findsWidgets);

    // Verify that the email and password text fields are present.
    expect(find.byType(TextField), findsNWidgets(2));
    
    // Check that we can find the labels
    expect(find.text('Email or Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
