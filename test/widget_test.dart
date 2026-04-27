// Smoke test mínimo. La aplicación principal arranca Firebase desde
// `main()`, así que no es testeable como widget aislado sin un mock
// completo del stack Firebase. Los tests útiles de la app están en
// `test/services/` y `test/widgets/`.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Smoke: MaterialApp básico se monta sin errores', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: const Text('RehabTech')),
        ),
      ),
    );
    expect(find.text('RehabTech'), findsOneWidget);
  });
}
