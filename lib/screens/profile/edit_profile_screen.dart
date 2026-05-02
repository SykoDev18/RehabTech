import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rehabtech/services/progress_service.dart';
import 'package:rehabtech/core/utils/logger.dart';
import 'package:rehabtech/widgets/profile_photo_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProgressService _progressService = ProgressService();

  late TextEditingController _nameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _birthDateController; // display "d/M/yyyy"
  late TextEditingController _conditionController;

  bool _isInitialLoad = true;
  bool _isLoading = false;
  String? _photoUrl;
  // Canonical ISO "yyyy-MM-dd" form stored in Firestore. Empty string when unset.
  String _birthDateIso = '';

  @override
  void initState() {
    super.initState();
    // Hydrate immediately from local cache so the form isn't blank during the
    // Firestore round-trip; the values get overwritten by the authoritative
    // Firestore snapshot when it arrives.
    final cached = _progressService.userProfile;
    _nameController = TextEditingController(text: cached.name);
    _lastNameController = TextEditingController(text: cached.lastName);
    _emailController = TextEditingController(text: cached.email);
    _phoneController = TextEditingController(text: cached.phone);
    _birthDateController = TextEditingController(text: cached.birthDate);
    _conditionController = TextEditingController(text: cached.condition);
    _photoUrl = cached.photoUrl;
    _loadFromFirestore();
  }

  Future<void> _loadFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isInitialLoad = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!mounted) return;
      final data = doc.data() ?? <String, dynamic>{};

      _nameController.text =
          (data['name'] as String?) ?? _nameController.text;
      _lastNameController.text =
          (data['lastName'] as String?) ?? _lastNameController.text;
      // Auth email is the source of truth for the displayed (read-only) email.
      _emailController.text = user.email ?? (data['email'] as String?) ?? '';
      _phoneController.text =
          (data['phone'] as String?) ?? _phoneController.text;
      _conditionController.text =
          (data['condition'] as String?) ?? _conditionController.text;
      _photoUrl = (data['photoUrl'] as String?) ?? _photoUrl;

      // birthDate may be stored as ISO "yyyy-MM-dd" (new) or "d/M/yyyy" (legacy
      // SharedPreferences-only era). Detect by the presence of a dash.
      final raw = (data['birthDate'] as String?) ?? '';
      if (raw.contains('-')) {
        _birthDateIso = raw;
        _birthDateController.text = _formatBirthDate(raw);
      } else if (raw.isNotEmpty) {
        // Legacy display value — keep as displayed but leave _birthDateIso empty
        // so the next save migrates it to ISO if the user re-picks the date.
        _birthDateController.text = raw;
      }

      setState(() => _isInitialLoad = false);
    } catch (e, st) {
      AppLogger.error(
        'Error cargando perfil desde Firestore',
        error: e,
        stackTrace: st,
        tag: 'EditProfile',
      );
      if (!mounted) return;
      setState(() => _isInitialLoad = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cargar el perfil. Mostrando datos en caché.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  String _formatBirthDate(String iso) {
    if (iso.isEmpty) return '';
    final parts = iso.split('-');
    if (parts.length != 3) return iso;
    final y = parts[0];
    final m = int.tryParse(parts[1]) ?? 1;
    final d = int.tryParse(parts[2]) ?? 1;
    return '$d/$m/$y';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _conditionController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    DateTime initial = DateTime(1990);
    if (_birthDateIso.isNotEmpty) {
      initial = DateTime.tryParse(_birthDateIso) ?? initial;
    }
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    final iso = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    setState(() {
      _birthDateIso = iso;
      _birthDateController.text = _formatBirthDate(iso);
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phone = _phoneController.text.trim();
    final condition = _conditionController.text.trim();

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'name': name,
        'lastName': lastName,
        'phone': phone,
        'birthDate': _birthDateIso,
        'condition': condition,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Mirror to local cache so the next open hydrates instantly without a
      // round-trip. Firestore remains the source of truth.
      final mirrored = UserProfile(
        name: name,
        lastName: lastName,
        email: _emailController.text.trim(),
        phone: phone,
        birthDate: _formatBirthDate(_birthDateIso),
        condition: condition,
        // Preserved verbatim; the field is being phased out as the assignment
        // model lives in users/{uid}.therapistId now.
        therapistName: _progressService.userProfile.therapistName,
        photoUrl: _photoUrl ?? '',
      );
      await _progressService.saveProfile(mirrored);

      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado correctamente'),
          backgroundColor: Color(0xFF22C55E),
        ),
      );
      Navigator.pop(context);
    } on FirebaseException catch (e) {
      AppLogger.error(
        'Error guardando perfil en Firestore',
        error: e,
        tag: 'EditProfile',
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo guardar el perfil: ${e.code}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e, st) {
      AppLogger.error(
        'Error inesperado guardando perfil',
        error: e,
        stackTrace: st,
        tag: 'EditProfile',
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[50]!,
              Colors.green[50]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(LucideIcons.arrowLeft, size: 22),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Editar Perfil',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),

              // Body
              Expanded(
                child: _isInitialLoad
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF3B82F6),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildProfilePhoto(),
                              const SizedBox(height: 32),

                              _buildFormCard([
                                _buildTextField(
                                  controller: _nameController,
                                  label: 'Nombre',
                                  icon: LucideIcons.user,
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Ingresa tu nombre'
                                          : null,
                                ),
                                _buildTextField(
                                  controller: _lastNameController,
                                  label: 'Apellido',
                                  icon: LucideIcons.user,
                                ),
                                _buildTextField(
                                  controller: _emailController,
                                  label: 'Correo Electrónico',
                                  icon: LucideIcons.mail,
                                  keyboardType: TextInputType.emailAddress,
                                  readOnly: true,
                                  helperText:
                                      'Para cambiar el correo ve a Seguridad',
                                ),
                                _buildTextField(
                                  controller: _phoneController,
                                  label: 'Teléfono',
                                  icon: LucideIcons.phone,
                                  keyboardType: TextInputType.phone,
                                ),
                                _buildTextField(
                                  controller: _birthDateController,
                                  label: 'Fecha de Nacimiento',
                                  icon: LucideIcons.calendar,
                                  readOnly: true,
                                  onTap: _selectBirthDate,
                                ),
                              ]),

                              const SizedBox(height: 24),

                              _buildFormCard([
                                _buildTextField(
                                  controller: _conditionController,
                                  label: 'Condición Médica',
                                  icon: LucideIcons.heartPulse,
                                  hint: 'Ej: Lesión de rodilla',
                                ),
                              ]),

                              const SizedBox(height: 32),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3B82F6),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'Guardar Cambios',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePhoto() {
    return Center(
      child: ProfilePhotoPicker(
        photoUrl: _photoUrl,
        onPhotoUploaded: (url) => setState(() => _photoUrl = url),
      ),
    );
  }

  Widget _buildFormCard(List<Widget> children) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: children.map((child) {
              final index = children.indexOf(child);
              return Column(
                children: [
                  child,
                  if (index < children.length - 1) const SizedBox(height: 16),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    String? helperText,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        prefixIcon: Icon(icon, color: const Color(0xFF3B82F6)),
        filled: true,
        fillColor: readOnly
            ? Colors.grey.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
      ),
    );
  }
}
