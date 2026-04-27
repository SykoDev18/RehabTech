import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehabtech/presentation/widgets/auth/password_strength_indicator.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
  );
}

void main() {
  group('PasswordStrengthIndicator', () {
    testWidgets('contraseña vacía: sin etiqueta de fuerza visible', (tester) async {
      await tester.pumpWidget(_wrap(const PasswordStrengthIndicator(password: '')));
      // Las 4 etiquetas de strength solo aparecen cuando hay contraseña.
      expect(find.text('Débil'), findsNothing);
      expect(find.text('Media'), findsNothing);
      expect(find.text('Fuerte'), findsNothing);
      expect(find.text('Muy fuerte'), findsNothing);
    });

    testWidgets('contraseña débil muestra "Débil"', (tester) async {
      await tester.pumpWidget(_wrap(const PasswordStrengthIndicator(password: 'a')));
      expect(find.text('Débil'), findsOneWidget);
    });

    testWidgets('contraseña media muestra "Media" (8 chars + uppercase)', (tester) async {
      await tester.pumpWidget(_wrap(const PasswordStrengthIndicator(password: 'Aaaaaaaa')));
      // 8 chars + uppercase = 2 reqs cumplidos -> medium
      expect(find.text('Media'), findsOneWidget);
    });

    testWidgets('contraseña fuerte muestra "Fuerte" (8+up+num)', (tester) async {
      await tester.pumpWidget(_wrap(const PasswordStrengthIndicator(password: 'Aaaaaaa1')));
      expect(find.text('Fuerte'), findsOneWidget);
    });

    testWidgets('contraseña muy fuerte muestra "Muy fuerte"', (tester) async {
      await tester.pumpWidget(_wrap(const PasswordStrengthIndicator(password: 'Aaaaaaa1!')));
      expect(find.text('Muy fuerte'), findsOneWidget);
    });

    testWidgets('lista de requisitos siempre visible cuando showRequirements=true', (tester) async {
      await tester.pumpWidget(_wrap(const PasswordStrengthIndicator(password: '')));
      expect(find.text('Al menos 8 caracteres'), findsOneWidget);
      expect(find.text('Una letra mayúscula'), findsOneWidget);
      expect(find.text('Un número'), findsOneWidget);
      expect(find.text('Un carácter especial'), findsOneWidget);
    });

    testWidgets('check icons reflejan los requisitos cumplidos', (tester) async {
      await tester.pumpWidget(_wrap(const PasswordStrengthIndicator(password: 'Aaaaaaa1!')));
      // Los 4 requisitos cumplidos -> 4 check_circle
      expect(find.byIcon(Icons.check_circle), findsNWidgets(4));
      expect(find.byIcon(Icons.radio_button_unchecked), findsNothing);
    });

    testWidgets('mezcla de cumplidos e incumplidos muestra ambos íconos', (tester) async {
      // 8 chars + uppercase, faltan número y especial -> 2 check + 2 unchecked
      await tester.pumpWidget(_wrap(const PasswordStrengthIndicator(password: 'Aaaaaaaa')));
      expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
      expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(2));
    });

    testWidgets('showRequirements=false oculta la lista', (tester) async {
      await tester.pumpWidget(_wrap(const PasswordStrengthIndicator(
        password: 'Aaaaaaa1!',
        showRequirements: false,
      )));
      expect(find.text('Al menos 8 caracteres'), findsNothing);
      expect(find.text('Una letra mayúscula'), findsNothing);
      // La etiqueta de fuerza sí debe seguir visible.
      expect(find.text('Muy fuerte'), findsOneWidget);
    });
  });
}
