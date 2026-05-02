import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rehabtech/domain/entities/therapist_license_entity.dart';
import 'package:rehabtech/screens/profile/therapist/license_verification_screen.dart';
import 'package:rehabtech/widgets/license_status_badge.dart';

/// Drop-in widget for patient-facing screens. It looks up the assigned
/// therapist (via the patient's own `therapistId`), watches that therapist's
/// license state, and renders a tappable [LicenseStatusBadge].
///
/// Renders an empty box when:
///   - the user is not signed in,
///   - the patient has no assigned therapist,
///   - the therapist exists but their license status is `unverified`.
class PatientTherapistBadge extends StatelessWidget {
  /// Display name to use when opening the verified-therapist sheet.
  final String therapistName;

  final bool compact;

  const PatientTherapistBadge({
    required this.therapistName,
    this.compact = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    final users = FirebaseFirestore.instance.collection('users');

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: users.doc(uid).snapshots(),
      builder: (context, patientSnap) {
        final therapistId =
            patientSnap.data?.data()?['therapistId'] as String?;
        if (therapistId == null || therapistId.isEmpty) {
          return const SizedBox.shrink();
        }
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: users.doc(therapistId).snapshots(),
          builder: (context, therapistSnap) {
            final license = therapistSnap.data?.data() == null
                ? const TherapistLicense()
                : TherapistLicense.fromMap(therapistSnap.data!.data()!);
            return LicenseStatusBadge(
              status: license.status,
              compact: compact,
              onTap: license.status == LicenseStatus.verified
                  ? () => showVerifiedTherapistSheet(
                        context,
                        therapistName: therapistName,
                        licenseNumber: license.licenseNumber,
                        licenseData: license.licenseData,
                        verifiedAt: license.verifiedAt,
                      )
                  : null,
            );
          },
        );
      },
    );
  }
}
