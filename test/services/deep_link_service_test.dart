import 'package:flutter_test/flutter_test.dart';
import 'package:rehabtech/services/deep_link_service.dart';

void main() {
  group('DeepLinkService', () {
    late DeepLinkService service;

    setUp(() {
      service = DeepLinkService();
    });

    group('parseDeepLink', () {
      test('debería parsear deep link de ejercicio con scheme personalizado', () {
        final uri = Uri.parse('rehabtech://exercise/1');
        final result = service.parseDeepLink(uri);
        expect(result, '/main/exercise/1');
      });

      test('debería parsear deep link de ejercicio con HTTPS', () {
        final uri = Uri.parse('https://rehabtech.app/exercise/2');
        final result = service.parseDeepLink(uri);
        expect(result, '/main/exercise/2');
      });

      test('debería parsear deep link de chat con Nora', () {
        final uri = Uri.parse('rehabtech://chat/nora');
        final result = service.parseDeepLink(uri);
        expect(result, '/main/chat/nora');
      });

      test('debería parsear deep link de chat con Nora y conversationId', () {
        final uri = Uri.parse('rehabtech://chat/nora?id=abc123');
        final result = service.parseDeepLink(uri);
        expect(result, '/main/chat/nora?conversationId=abc123');
      });

      test('debería parsear deep link de chat con terapeuta', () {
        final uri = Uri.parse('rehabtech://chat/therapist');
        final result = service.parseDeepLink(uri);
        expect(result, '/main/chat/therapist');
      });

      test('debería parsear deep link de perfil', () {
        final uri = Uri.parse('rehabtech://profile/edit');
        final result = service.parseDeepLink(uri);
        expect(result, '/profile/edit');
      });

      test('debería parsear deep link de progreso', () {
        final uri = Uri.parse('rehabtech://progress');
        final result = service.parseDeepLink(uri);
        expect(result, '/main');
      });

      test('debería retornar /main para deep links vacíos', () {
        final uri = Uri.parse('rehabtech://');
        final result = service.parseDeepLink(uri);
        expect(result, '/main');
      });

      test('debería retornar /main para deep links no reconocidos', () {
        final uri = Uri.parse('rehabtech://unknown/path');
        final result = service.parseDeepLink(uri);
        expect(result, '/main');
      });
    });

    group('notification deep links', () {
      test('debería manejar notificación de recordatorio diario', () {
        final uri = Uri.parse('rehabtech://notification?type=daily_reminder');
        final result = service.parseDeepLink(uri);
        expect(result, '/main');
      });

      test('debería manejar notificación de mensaje de terapeuta', () {
        final uri = Uri.parse('rehabtech://notification?type=therapist_message');
        final result = service.parseDeepLink(uri);
        expect(result, '/main/chat/therapist');
      });

      test('debería manejar notificación de nueva rutina', () {
        final uri = Uri.parse('rehabtech://notification?type=new_routine&routineId=r123');
        final result = service.parseDeepLink(uri);
        expect(result, '/main/routine/r123');
      });
    });

    group('generateExerciseLink', () {
      test('debería generar link correcto para ejercicio', () {
        final link = service.generateExerciseLink('1');
        expect(link.toString(), 'https://rehabtech.app/exercise/1');
      });
    });

    group('generateProgressLink', () {
      test('debería generar link correcto para progreso', () {
        final link = service.generateProgressLink('2026-01-07');
        expect(link.toString(), 'https://rehabtech.app/progress?date=2026-01-07');
      });
    });

    group('getExerciseById', () {
      test('debería retornar ejercicio existente', () {
        final exercise = service.getExerciseById('1');
        expect(exercise, isNotNull);
        expect(exercise!.id, '1');
      });

      test('debería retornar null para ejercicio inexistente', () {
        final exercise = service.getExerciseById('nonexistent');
        expect(exercise, isNull);
      });
    });

    group('generateInternalLink', () {
      test('debería generar link interno sin query params', () {
        final link = service.generateInternalLink('exercise/1');
        expect(link.scheme, 'rehabtech');
        expect(link.host, 'exercise');
      });

      test('debería generar link interno con query params', () {
        final link = service.generateInternalLink(
          'chat/nora',
          queryParams: {'id': 'conv123'},
        );
        expect(link.scheme, 'rehabtech');
        expect(link.queryParameters['id'], 'conv123');
      });
    });
  });
}
