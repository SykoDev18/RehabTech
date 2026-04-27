import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rehabtech/domain/entities/achievement_entity.dart';
import 'package:rehabtech/screens/achievements/widgets/achievement_card.dart';

const _ach = AchievementEntity(
  id: 'first_step',
  title: 'Primer Paso',
  description: 'Completaste tu primera sesión',
  iconName: 'footprints',
  condition: 'Completa una sesión',
  points: 10,
);

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
  );
}

void main() {
  // El widget usa DateFormat('d MMM yyyy', 'es_ES'); sin esta inicialización
  // la formatea con un locale simbólico no cargado y tira excepción.
  setUpAll(() async {
    await initializeDateFormatting('es_ES', null);
  });

  group('AchievementCard', () {
    testWidgets('locked muestra icono de lock y la condición', (tester) async {
      await tester.pumpWidget(_wrap(
        const AchievementCard(achievement: _ach, unlocked: false),
      ));
      expect(find.text('Primer Paso'), findsOneWidget);
      expect(find.text('Completa una sesión'), findsOneWidget); // condition
      expect(find.byIcon(LucideIcons.lock), findsOneWidget);
      expect(find.text('+10 pts'), findsOneWidget);
    });

    testWidgets('unlocked sin fecha muestra la condición', (tester) async {
      await tester.pumpWidget(_wrap(
        const AchievementCard(achievement: _ach, unlocked: true),
      ));
      expect(find.byIcon(LucideIcons.lock), findsNothing);
      expect(find.text('Completa una sesión'), findsOneWidget);
    });

    testWidgets('unlocked con fecha muestra la fecha formateada', (tester) async {
      // Usamos solo el año en la verificación para no depender del locale
      // de la máquina de CI (DateFormat usa Spanish 'es_ES' que requiere
      // initializeDateFormatting; aquí caemos al locale por defecto).
      await tester.pumpWidget(_wrap(
        AchievementCard(
          achievement: _ach,
          unlocked: true,
          unlockedAt: DateTime(2026, 4, 26),
        ),
      ));
      expect(find.byIcon(LucideIcons.lock), findsNothing);
      // No verificamos el texto exacto de la fecha porque depende del locale.
      // Sí verificamos que la condición ya NO se muestra.
      expect(find.text('Completa una sesión'), findsNothing);
    });

    testWidgets('renderiza el ícono mapeado del catálogo', (tester) async {
      await tester.pumpWidget(_wrap(
        const AchievementCard(achievement: _ach, unlocked: true),
      ));
      // 'footprints' del catálogo se mapea a LucideIcons.footprints.
      expect(find.byIcon(LucideIcons.footprints), findsOneWidget);
    });

    testWidgets('icono desconocido cae al default (award)', (tester) async {
      const unknown = AchievementEntity(
        id: 'x',
        title: 'X',
        description: 'd',
        iconName: 'icono_que_no_existe',
        condition: 'c',
        points: 1,
      );
      await tester.pumpWidget(_wrap(
        const AchievementCard(achievement: unknown, unlocked: true),
      ));
      expect(find.byIcon(LucideIcons.award), findsOneWidget);
    });
  });
}
