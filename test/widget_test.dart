import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_cloak/main.dart';

void main() {
  testWidgets('NetworkCloakApp renders home screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: NetworkCloakApp()));

    // Let GoRouter settle
    await tester.pumpAndSettle();

    // Verify that the brand header label is rendered.
    expect(find.textContaining('Welcome to'), findsOneWidget);
  });
}
