import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rehabtech/domain/entities/therapist_license_entity.dart';
import 'package:rehabtech/router/app_router.dart';
import 'package:rehabtech/widgets/license_status_badge.dart';
import 'package:rehabtech/widgets/profile_photo_picker.dart';

class TherapistProfileScreen extends StatefulWidget {
  const TherapistProfileScreen({super.key});

  @override
  State<TherapistProfileScreen> createState() => _TherapistProfileScreenState();
}

class _TherapistProfileScreenState extends State<TherapistProfileScreen> {
  Map<String, dynamic>? _userData;
  int _patientCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (!mounted) return;
      if (userDoc.exists) {
        setState(() => _userData = userDoc.data());
      }

      final patientsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('therapistId', isEqualTo: userId)
          .where('userType', isEqualTo: 'patient')
          .get();
      if (!mounted) return;
      setState(() => _patientCount = patientsSnapshot.docs.length);
    } on FirebaseException {
      // Network errors are non-fatal — the existing _userData (possibly
      // null) keeps the UI in a stable empty state until the next reload.
      // Logging is intentionally skipped: this method runs on every
      // photo-upload callback and would generate noise.
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: _buildHeader(),
        ),
        // Profile content
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildProfileCard(),
              const SizedBox(height: 16),
              _buildContactCard(),
              const SizedBox(height: 16),
              _buildLicenseCard(),
              const SizedBox(height: 16),
              _buildStatsCard(),
              const SizedBox(height: 32),
              _buildLogoutButton(),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Perfil',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          GestureDetector(
            onTap: _showEditProfileModal,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                LucideIcons.pencil,
                color: const Color(0xFF3B82F6),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    final name = '${_userData?['name'] ?? ''} ${_userData?['lastName'] ?? ''}'.trim();
    final specialty = _userData?['specialty'] ?? 'Fisioterapeuta';
    final photoUrl = (_userData?['photoUrl'] as String?) ?? '';
    final initials = _getInitials(name);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar — uses ProfilePhotoPicker so taps trigger camera/gallery
          // upload. Falls back to gradient + initials when no photo is set.
          ProfilePhotoPicker(
            photoUrl: photoUrl,
            size: 88,
            borderWidth: 0,
            gradient: const LinearGradient(
              colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            fallback: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 32,
              ),
            ),
            onPhotoUploaded: (_) => _loadUserData(),
          ),
          const SizedBox(height: 16),
          Text(
            name.isEmpty ? 'Dr. Fisioterapeuta' : name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            specialty,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    final email = _userData?['email'] ?? FirebaseAuth.instance.currentUser?.email ?? '';
    final phone = _userData?['phone'] ?? '';
    final address = _userData?['address'] ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildContactRow(LucideIcons.mail, 'Email', email),
          if (phone.isNotEmpty) ...[
            const Divider(height: 24),
            _buildContactRow(LucideIcons.phone, 'Teléfono', phone),
          ],
          if (address.isNotEmpty) ...[
            const Divider(height: 24),
            _buildContactRow(LucideIcons.mapPin, 'Dirección', address),
          ],
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF3B82F6), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Live status of the therapist's professional license. Reads from the
  /// `users/{uid}` doc via StreamBuilder so the badge updates the moment the
  /// `verifyProfessionalLicense` Cloud Function writes a result. Tapping the
  /// row pushes the dedicated verification screen — the cédula number itself
  /// is no longer hand-editable from the profile (it's owned by that flow).
  Widget _buildLicenseCard() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snap) {
        final license = snap.data?.data() == null
            ? const TherapistLicense()
            : TherapistLicense.fromMap(snap.data!.data()!);

        final (subtitle, ctaLabel) = switch (license.status) {
          LicenseStatus.verified => (
              license.licenseNumber != null
                  ? 'Cédula ${license.licenseNumber} • Verificada SEP'
                  : 'Verificada por la SEP',
              'Ver detalles',
            ),
          LicenseStatus.pending => (
              'Verificando con el RNP de la SEP…',
              'Ver estado',
            ),
          LicenseStatus.manualReview => (
              'En revisión manual de nuestro equipo',
              'Ver detalles',
            ),
          LicenseStatus.rejected => (
              license.verificationError ?? 'No se pudo verificar tu cédula',
              'Reintentar',
            ),
          LicenseStatus.unverified => (
              'Verifica tu cédula para mostrar el sello a tus pacientes',
              'Verificar ahora',
            ),
        };

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => context.goToLicenseVerification(),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      LucideIcons.badgeCheck,
                      color: const Color(0xFF3B82F6),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Cédula Profesional',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Compact status pill — renders nothing for
                            // `unverified`, so we add a fallback below.
                            if (license.status != LicenseStatus.unverified)
                              LicenseStatusBadge(
                                status: license.status,
                                compact: true,
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          ctaLabel,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronRight,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsCard() {
    final yearsExp = _userData?['yearsExperience'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estadísticas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  value: '$_patientCount',
                  label: 'Pacientes',
                  color: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  value: '$yearsExp',
                  label: 'Años exp.',
                  color: const Color(0xFF22C55E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _signOut,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.logOut, color: Colors.red[600], size: 18),
            const SizedBox(width: 8),
            Text(
              'Cerrar Sesión',
              style: TextStyle(
                color: Colors.red[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'DR';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : name.length).toUpperCase();
  }

  void _showEditProfileModal() {
    final nameController = TextEditingController(text: '${_userData?['name'] ?? ''} ${_userData?['lastName'] ?? ''}'.trim());
    final specialtyController = TextEditingController(text: _userData?['specialty'] ?? 'Fisioterapeuta Especializada');
    final emailController = TextEditingController(text: _userData?['email'] ?? FirebaseAuth.instance.currentUser?.email ?? '');
    final phoneController = TextEditingController(text: _userData?['phone'] ?? '');
    final addressController = TextEditingController(text: _userData?['address'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFDBEAFE), Color(0xFFF0FDF4), Color(0xFFEFF6FF)],
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Editar Perfil',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(LucideIcons.x, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  children: [
                    _buildFormField(label: 'Nombre', controller: nameController),
                    const SizedBox(height: 16),
                    _buildFormField(label: 'Especialidad', controller: specialtyController),
                    const SizedBox(height: 16),
                    _buildFormField(label: 'Email', controller: emailController, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 16),
                    _buildFormField(label: 'Teléfono', controller: phoneController, keyboardType: TextInputType.phone),
                    const SizedBox(height: 16),
                    _buildFormField(label: 'Dirección', controller: addressController),
                    const SizedBox(height: 8),
                    // The cédula is owned by the verification flow, not this
                    // form. Therapists tap the "Cédula Profesional" card on
                    // the profile to open `/license-verification`.
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.info,
                            size: 16,
                            color: Color(0xFF3B82F6),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Para verificar tu cédula profesional usa la '
                              'sección "Cédula Profesional" en tu perfil.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Submit button
                    GestureDetector(
                      onTap: () => _updateProfile(
                        context,
                        name: nameController.text,
                        specialty: specialtyController.text,
                        email: emailController.text,
                        phone: phoneController.text,
                        address: addressController.text,
                      ),
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Guardar Cambios',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProfile(
    BuildContext context, {
    required String name,
    required String specialty,
    required String email,
    required String phone,
    required String address,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      // Split name
      final nameParts = name.trim().split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts[0] : '';
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'name': firstName,
        'lastName': lastName,
        'specialty': specialty,
        'email': email,
        'phone': phone,
        'address': address,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        Navigator.pop(context);
        _loadUserData(); // Refresh data
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo actualizar el perfil: ${e.code}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        context.goToLogin();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de autenticación al cerrar sesión: ${e.code}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cerrar sesión: $e')),
        );
      }
    }
  }
}
