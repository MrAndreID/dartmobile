import 'package:dart_mobile/core/router/app_router.dart';
import 'package:dart_mobile/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Home page lists the available features', (tester) async {
    final router = createRouter();

    await tester.pumpWidget(
      ProviderScope(
        child: DartMobileApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    // The home screen should surface both feature entry points.
    expect(find.text('Hello World'), findsOneWidget);
    expect(find.text('Users'), findsOneWidget);
  });

  testWidgets('Tapping Hello World navigates to the greeting screen',
      (tester) async {
    final router = createRouter();

    await tester.pumpWidget(
      ProviderScope(
        child: DartMobileApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hello World'));
    await tester.pumpAndSettle();

    expect(find.text('Hello, World!'), findsOneWidget);
  });
}
