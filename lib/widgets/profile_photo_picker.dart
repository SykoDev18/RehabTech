import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rehabtech/core/utils/logger.dart';

/// Round avatar that doubles as a profile-photo upload control.
///
/// Tapping the widget opens a camera/gallery sheet, uploads the chosen image
/// to Firebase Storage at `profile_images/{uid}.jpg`, persists the resulting
/// download URL into `users/{uid}.photoUrl`, and notifies the parent via
/// [onPhotoUploaded].
///
/// Used by both [EditProfileScreen] (patient) and [TherapistProfileScreen]
/// to avoid duplicating the picker + upload + Firestore-write boilerplate.
class ProfilePhotoPicker extends StatefulWidget {
  /// Current photo URL. Pass null/empty to show the [fallback].
  final String? photoUrl;

  /// Diameter in logical pixels.
  final double size;

  /// Widget rendered when [photoUrl] is empty AND no upload is in progress.
  /// Pass either an [Icon] or text-initials styled by the caller.
  final Widget fallback;

  /// Background gradient used behind the fallback. Ignored when an image is
  /// shown (the image fills the circle).
  final Gradient? gradient;

  /// Border drawn around the avatar.
  final Color borderColor;
  final double borderWidth;

  /// Called with the new download URL once the Firestore write succeeds.
  /// The parent should rebuild with this URL so the avatar reflects the
  /// upload immediately on the next frame.
  final ValueChanged<String>? onPhotoUploaded;

  /// Whether to render the small camera badge in the bottom-right.
  final bool showCameraBadge;

  const ProfilePhotoPicker({
    super.key,
    required this.photoUrl,
    this.size = 120,
    this.fallback = const Icon(
      LucideIcons.user,
      size: 50,
      color: Color(0xFF3B82F6),
    ),
    this.gradient,
    this.borderColor = const Color(0xFF3B82F6),
    this.borderWidth = 3,
    this.onPhotoUploaded,
    this.showCameraBadge = true,
  });

  @override
  State<ProfilePhotoPicker> createState() => _ProfilePhotoPickerState();
}

class _ProfilePhotoPickerState extends State<ProfilePhotoPicker> {
  static final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _handleTap() async {
    if (_isUploading) return;
    try {
      final source = await _showSourceSheet();
      if (source == null) return;

      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (picked == null) return;
      if (!mounted) return;

      setState(() => _isUploading = true);

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Usuario no autenticado');

      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('$uid.jpg');
      await ref.putFile(File(picked.path));
      final downloadUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'photoUrl': downloadUrl});

      AppLogger.info('Foto de perfil actualizada', tag: 'ProfilePhotoPicker');
      if (!mounted) return;
      setState(() => _isUploading = false);
      widget.onPhotoUploaded?.call(downloadUrl);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto de perfil actualizada'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e, st) {
      AppLogger.error(
        'Error subiendo foto de perfil',
        error: e,
        stackTrace: st,
        tag: 'ProfilePhotoPicker',
      );
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al subir la imagen'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<ImageSource?> _showSourceSheet() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Seleccionar imagen',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.camera, color: Color(0xFF3B82F6)),
              ),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.image, color: Color(0xFF3B82F6)),
              ),
              title: const Text('Elegir de galería'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = widget.photoUrl != null && widget.photoUrl!.isNotEmpty;

    return GestureDetector(
      onTap: _handleTap,
      child: Stack(
        children: [
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: hasPhoto
                  ? null
                  : const Color(0xFF3B82F6).withValues(alpha: 0.1),
              gradient: hasPhoto ? null : widget.gradient,
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.borderColor,
                width: widget.borderWidth,
              ),
              image: hasPhoto
                  ? DecorationImage(
                      image: NetworkImage(widget.photoUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _isUploading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF3B82F6),
                      strokeWidth: 2,
                    ),
                  )
                : hasPhoto
                    ? null
                    : Center(child: widget.fallback),
          ),
          if (widget.showCameraBadge)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF3B82F6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.camera,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
