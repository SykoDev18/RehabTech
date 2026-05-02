import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehabtech/domain/entities/therapist_license_entity.dart';
import 'package:rehabtech/widgets/license_status_badge.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('LicenseStatusBadge', () {
    testWidgets('verified renders the verified label', (tester) async {
      await tester.pumpWidget(
        _wrap(const LicenseStatusBadge(status: LicenseStatus.verified)),
      );
      expect(find.text('Cédula verificada SEP'), findsOneWidget);
    });

    testWidgets('unverified renders an empty box', (tester) async {
      await tester.pumpWidget(
        _wrap(const LicenseStatusBadge(status: LicenseStatus.unverified)),
      );
      expect(find.byType(SizedBox), findsWidgets);
      expect(find.text('Cédula verificada SEP'), findsNothing);
      expect(find.text('Verificación pendiente'), findsNothing);
      expect(find.text('No verificado'), findsNothing);
    });

    testWidgets('manualReview shows pending label', (tester) async {
      await tester.pumpWidget(
        _wrap(const LicenseStatusBadge(status: LicenseStatus.manualReview)),
      );
      expect(find.text('Verificación pendiente'), findsOneWidget);
    });

    testWidgets('pending shows pending label', (tester) async {
      await tester.pumpWidget(
        _wrap(const LicenseStatusBadge(status: LicenseStatus.pending)),
      );
      expect(find.text('Verificación pendiente'), findsOneWidget);
    });

    testWidgets('rejected shows rejected label', (tester) async {
      await tester.pumpWidget(
        _wrap(const LicenseStatusBadge(status: LicenseStatus.rejected)),
      );
      expect(find.text('No verificado'), findsOneWidget);
    });

    testWidgets('compact = true hides the label', (tester) async {
      await tester.pumpWidget(
        _wrap(const LicenseStatusBadge(
          status: LicenseStatus.verified,
          compact: true,
        )),
      );
      expect(find.text('Cédula verificada SEP'), findsNothing);
    });

    testWidgets('onTap fires when verified badge is tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(LicenseStatusBadge(
          status: LicenseStatus.verified,
          onTap: () => taps++,
        )),
      );
      await tester.tap(find.text('Cédula verificada SEP'));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });
  });
}
