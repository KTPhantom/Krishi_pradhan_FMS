// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import '../lib/main.dart';
import '../lib/presentation/providers/auth_provider.dart';
import '../lib/data/services/auth_service.dart';
import '../lib/data/models/user_model.dart';
import '../lib/core/utils/result.dart';

class FakeAuthService extends Fake implements AuthService {
  @override
  Future<bool> isLoggedIn() async => false;
  
  @override
  Future<UserModel?> getCurrentUser() async => null;
}

void main() {
  testWidgets('App renders login page smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(FakeAuthService()),
        ],
        child: const KrishiPradhanApp(),
      ),
    );
    
    // Wait for the widget to settle (animations etc)
    await tester.pumpAndSettle();

    // Verify that our app title is present (on Login Page)
    expect(find.text('Krishi Pradhan'), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });
}
