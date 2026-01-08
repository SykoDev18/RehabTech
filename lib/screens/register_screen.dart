
import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rehabtech/router/app_router.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  String _userType = 'patient';
  bool _agreedToTerms = false;
  bool _isLoading = false;

  Future<void> _navigateAfterRegister() async {
    AppRouter.clearUserTypeCache();
    if (mounted) {
      if (_userType == 'therapist') {
        context.go('/therapist');
      } else {
        context.go('/main');
      }
    }
  }

  /// Genera un ID único de paciente de 8 caracteres alfanuméricos
  String _generatePatientId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> _createAccount() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes aceptar los términos y condiciones')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Separar nombre y apellido
      final nameParts = _nameController.text.trim().split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts[0] : '';
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      // Generar ID único de paciente si es paciente
      final patientId = _userType == 'patient' ? _generatePatientId() : null;

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': firstName,
        'lastName': lastName,
        'email': _emailController.text.trim(),
        'userType': _userType,
        'patientId': patientId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Enviar email de verificación
      await userCredential.user!.sendEmailVerification();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Cuenta creada! Revisa tu correo para verificar tu cuenta.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

      await _navigateAfterRegister();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Error al crear cuenta')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      // Crear documento de usuario si es nuevo
      final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
      if (!userDoc.exists) {
        final nameParts = (googleUser.displayName ?? '').split(' ');
        final firstName = nameParts.isNotEmpty ? nameParts[0] : '';
        final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
        
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'name': firstName,
          'lastName': lastName,
          'email': googleUser.email,
          'photoUrl': googleUser.photoUrl,
          'userType': _userType,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      await _navigateAfterRegister();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al iniciar con Google: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Crear Cuenta',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildUserTypeSelector(),
            const SizedBox(height: 24),
            _buildTextField(controller: _nameController, hintText: 'Nombre', exampleText: 'Ej. Marco Antonio'),
            const SizedBox(height: 16),
            _buildTextField(controller: _emailController, hintText: 'Correo', exampleText: 'Ej. tu@email.com'),
            const SizedBox(height: 16),
            _buildTextField(controller: _passwordController, hintText: 'Contraseña', isPassword: true),
            const SizedBox(height: 16),
            _buildTextField(controller: _confirmPasswordController, hintText: 'Confirmar', isPassword: true),
            const SizedBox(height: 24),
            _buildTermsAndConditions(),
            const SizedBox(height: 24),
            _buildGradientButton('Crear Cuenta', _isLoading ? null : _createAccount),
            const SizedBox(height: 24),
            _buildSeparator(),
            const SizedBox(height: 24),
            _buildSocialButton(
              text: 'Continuar con Apple',
              imagePath: 'assets/apple_logo.png',
              backgroundColor: Colors.black,
              textColor: Colors.white,
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            _buildSocialButton(
              text: 'Continuar con Google',
              imagePath: 'assets/google_logo.png',
              backgroundColor: Colors.white,
              textColor: Colors.black,
              onPressed: _isLoading ? () {} : _signInWithGoogle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildUserTypeButton('Soy Paciente', 'patient'),
          _buildUserTypeButton('Soy Terapeuta', 'therapist'),
        ],
      ),
    );
  }

  Widget _buildUserTypeButton(String text, String type) {
    final isSelected = _userType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _userType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: isSelected
              ? BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                )
              : null,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hintText, bool isPassword = false, String? exampleText}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: hintText,
        hintText: exampleText,
        hintStyle: TextStyle(color: Colors.grey[400]),
        labelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        suffixText: isPassword ? '•••••••' : null,
        suffixStyle: TextStyle(color: Colors.grey[400]),
      ),
    );
  }

  Widget _buildTermsAndConditions() {
    return Row(
      children: [
        Checkbox(
          value: _agreedToTerms,
          onChanged: (value) => setState(() => _agreedToTerms = value!),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: Colors.grey[600]),
              children: [
                const TextSpan(text: 'Acepto los '),
                TextSpan(
                  text: 'Términos y Condiciones',
                  style: const TextStyle(color: Color(0xFF007AFF), fontWeight: FontWeight.bold),
                  recognizer: TapGestureRecognizer()..onTap = () => _openTermsAndConditions(),
                ),
                const TextSpan(text: ' y la '),
                TextSpan(
                  text: 'Política de Privacidad',
                  style: const TextStyle(color: Color(0xFF007AFF), fontWeight: FontWeight.bold),
                  recognizer: TapGestureRecognizer()..onTap = () => _openPrivacyPolicy(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openTermsAndConditions() async {
    final uri = Uri.parse('https://drive.google.com/file/d/1pluhJYI2OoKxA4U8mh828U7hG3-O0NVx/view?usp=sharing');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse('https://drive.google.com/file/d/1he2yl9Hap6-dhgsS7tqUIj8Vukp_-4hf/view?usp=sharing');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildGradientButton(String text, VoidCallback? onPressed) {
    return Container(
      height: 50,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: onPressed == null 
              ? [Colors.grey.shade400, Colors.grey.shade500]
              : [const Color(0xFF1E88E5), const Color(0xFF26C6DA)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: onPressed == null ? [] : [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                    color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
  Widget _buildSeparator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(child: Container(height: 1, color: Colors.grey.shade300)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text('o regístrate con', style: TextStyle(color: Colors.grey.shade500)),
        ),
        Expanded(child: Container(height: 1, color: Colors.grey.shade300)),
      ],
    );
  }

  Widget _buildSocialButton({required String text, required String imagePath, required Color backgroundColor, required Color textColor, VoidCallback? onPressed}) {
    return ElevatedButton(
      onPressed: onPressed ?? () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(imagePath, height: 20, color: imagePath.contains('apple') ? Colors.white : null),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
                color: textColor, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
