import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rehabtech/domain/entities/therapist_license_entity.dart';
import 'package:rehabtech/router/app_router.dart';

/// Persistent in-app banner shown to therapists whose `users/{uid}` doc reports
/// `licenseStatus == unverified`. Renders an empty box for verified, pending,
/// rejected, or manual_review states (those have their own surfaces) and for
/// patients/anonymous users.
class TherapistUnverifiedBanner extends StatelessWidget {
  const TherapistUnverifiedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    final ref = FirebaseFirestore.instance.collection('users').doc(uid);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ref.snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data();
        if (data == null) return const SizedBox.shrink();
        final isTherapist = (data['userType'] as String?) == 'therapist';
        if (!isTherapist) return const SizedBox.shrink();
        final license = TherapistLicense.fromMap(data);
        if (license.status != LicenseStatus.unverified) {
          return const SizedBox.shrink();
        }
        return _Banner(
          onTap: () => context.goToLicenseVerification(),
        );
      },
    );
  }
}

class _Banner extends StatelessWidget {
  final VoidCallback onTap;
  const _Banner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF8E1),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(
                LucideIcons.triangleAlert,
                color: Color(0xFFB45309),
                size: 20,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Verifica tu cédula para aparecer en búsquedas',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF92400E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Text(
                'Verificar ahora',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFB45309),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: Color(0xFFB45309),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
