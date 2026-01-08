import 'package:flutter_test/flutter_test.dart';
import 'package:rehabtech/widgets/common/error_widget.dart';
import 'package:rehabtech/widgets/common/empty_state_widget.dart';
import 'package:rehabtech/widgets/common/loading_widget.dart';
import 'package:flutter/material.dart';

void main() {
  group('AppErrorWidget', () {
    testWidgets('debería mostrar título y mensaje', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorWidget(
              title: 'Test Error',
              message: 'Test message',
            ),
          ),
        ),
      );

      expect(find.text('Test Error'), findsOneWidget);
      expect(find.text('Test message'), findsOneWidget);
    });

    testWidgets('debería mostrar botón de retry cuando se proporciona callback', (tester) async {
      bool retryPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorWidget(
              title: 'Error',
              onRetry: () => retryPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Reintentar'), findsOneWidget);
      
      await tester.tap(find.text('Reintentar'));
      expect(retryPressed, isTrue);
    });

    testWidgets('factory network debería mostrar contenido correcto', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorWidget.network(),
          ),
        ),
      );

      expect(find.text('Sin conexión'), findsOneWidget);
      expect(find.textContaining('conexión a internet'), findsOneWidget);
    });

    testWidgets('factory server debería mostrar contenido correcto', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorWidget.server(),
          ),
        ),
      );

      expect(find.text('Error del servidor'), findsOneWidget);
    });

    testWidgets('factory auth debería mostrar contenido correcto', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorWidget.auth(),
          ),
        ),
      );

      expect(find.text('Sesión expirada'), findsOneWidget);
      expect(find.text('Iniciar sesión'), findsOneWidget);
    });

    testWidgets('factory permission debería mostrar contenido correcto', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorWidget.permission(),
          ),
        ),
      );

      expect(find.text('Permiso denegado'), findsOneWidget);
      expect(find.text('Configurar permisos'), findsOneWidget);
    });

    testWidgets('factory timeout debería mostrar contenido correcto', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorWidget.timeout(),
          ),
        ),
      );

      expect(find.text('Tiempo agotado'), findsOneWidget);
    });
  });

  group('InlineErrorWidget', () {
    testWidgets('debería mostrar mensaje de error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InlineErrorWidget(message: 'Error inline'),
          ),
        ),
      );

      expect(find.text('Error inline'), findsOneWidget);
    });

    testWidgets('debería mostrar botón retry cuando se proporciona callback', (tester) async {
      bool retryPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InlineErrorWidget(
              message: 'Error',
              onRetry: () => retryPressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      expect(retryPressed, isTrue);
    });
  });

  group('EmptyStateWidget', () {
    testWidgets('debería mostrar título y mensaje', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              title: 'Sin datos',
              message: 'No hay datos disponibles',
            ),
          ),
        ),
      );

      expect(find.text('Sin datos'), findsOneWidget);
      expect(find.text('No hay datos disponibles'), findsOneWidget);
    });

    testWidgets('debería mostrar acción cuando se proporciona', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              title: 'Sin datos',
              action: ElevatedButton(
                onPressed: () {},
                child: const Text('Acción'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Acción'), findsOneWidget);
    });

    testWidgets('factory noExercises debería mostrar contenido correcto', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget.noExercises(),
          ),
        ),
      );

      expect(find.text('Sin ejercicios'), findsOneWidget);
    });

    testWidgets('factory noHistory debería mostrar contenido correcto', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget.noHistory(),
          ),
        ),
      );

      expect(find.text('Sin historial'), findsOneWidget);
    });

    testWidgets('factory noSearchResults debería mostrar query', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget.noSearchResults(query: 'test'),
          ),
        ),
      );

      expect(find.textContaining('"test"'), findsOneWidget);
    });
  });

  group('AppLoadingWidget', () {
    testWidgets('debería mostrar spinner', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppLoadingWidget(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('debería mostrar mensaje cuando se proporciona', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppLoadingWidget(message: 'Cargando datos...'),
          ),
        ),
      );

      expect(find.text('Cargando datos...'), findsOneWidget);
    });

    testWidgets('factory fullScreen debería tener mensaje por defecto', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppLoadingWidget.fullScreen(),
          ),
        ),
      );

      expect(find.text('Cargando...'), findsOneWidget);
    });
  });

  group('LoadingOverlay', () {
    testWidgets('debería mostrar child cuando no está cargando', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoadingOverlay(
            isLoading: false,
            child: Text('Contenido'),
          ),
        ),
      );

      expect(find.text('Contenido'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('debería mostrar overlay cuando está cargando', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoadingOverlay(
            isLoading: true,
            child: Text('Contenido'),
          ),
        ),
      );

      expect(find.text('Contenido'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('ShimmerLoading', () {
    testWidgets('debería renderizar con dimensiones correctas', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerLoading(width: 100, height: 50),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.constraints?.maxWidth, 100);
      expect(container.constraints?.maxHeight, 50);
    });
  });

  group('CompactEmptyState', () {
    testWidgets('debería mostrar mensaje', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompactEmptyState(message: 'Lista vacía'),
          ),
        ),
      );

      expect(find.text('Lista vacía'), findsOneWidget);
    });
  });
}
