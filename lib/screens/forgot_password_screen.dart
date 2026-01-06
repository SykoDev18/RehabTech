
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  bool _emailSent = false;

  Future<void> _sendPasswordResetEmail() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa tu correo electrónico')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
      setState(() => _emailSent = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Correo enviado! Revisa tu bandeja de entrada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = _getErrorMessage(e.code);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al enviar el correo. Intenta de nuevo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No existe una cuenta con este correo';
      case 'invalid-email':
        return 'El correo electrónico no es válido';
      default:
        return 'Error al enviar el correo. Intenta de nuevo';
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Iniciar Sesión',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            const Text(
              'Recuperar Contraseña',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ingresa tu correo electrónico. Te enviaremos un enlace para restablecer tu contraseña.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            _buildTextField(
              controller: _emailController,
              hintText: 'Correo',
              exampleText: 'ej. tu@email.com',
            ),
            const SizedBox(height: 32),
            _buildGradientButton(
              _emailSent ? 'Reenviar Enlace' : 'Enviar Enlace de Recuperación', 
              _isLoading ? null : _sendPasswordResetEmail,
            ),
            if (_emailSent) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Revisa tu correo ${_emailController.text} y sigue las instrucciones para restablecer tu contraseña.',
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Volver al inicio de sesión',
                  style: TextStyle(color: Color(0xFF007AFF), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hintText, String? exampleText}) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: hintText,
        hintText: exampleText,
        labelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
        hintStyle: TextStyle(color: Colors.grey[400]),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
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
            color: Colors.blue.withOpacity(0.3),
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
}
