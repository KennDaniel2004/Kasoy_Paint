// Basic smoke test for the Kasoy Painting Shop app.
//
// This just verifies the app builds and the splash screen appears —
// replace/expand this later as you add more testable behavior.

import 'package:flutter_test/flutter_test.dart';

import 'package:kasoy_app/main.dart';

void main() {
  testWidgets('App launches and shows the splash tagline', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const KasoyApp());

    // The splash screen should be showing right after launch.
    expect(find.text('Bring Your Ride Back to Life.'), findsOneWidget);
  });
}