import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
                          color: Colors.white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(LucideIcons.arrowLeft, size: 22),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Política de Privacidad',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Última actualización
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Última actualización: Enero 2026',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF3B82F6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      _buildSection(
                        title: '1. Información que Recopilamos',
                        icon: LucideIcons.database,
                        content: '''
RehabTech recopila la siguiente información para brindarte un servicio personalizado de rehabilitación:

• Información personal: Nombre, correo electrónico, teléfono y fecha de nacimiento.
• Información médica: Condición a tratar, historial de ejercicios, niveles de dolor reportados y progreso en la rehabilitación.
• Datos de uso: Cómo interactúas con la aplicación, ejercicios completados, tiempo de sesión y frecuencia de uso.
• Información del dispositivo: Tipo de dispositivo, sistema operativo y datos de cámara durante las sesiones de ejercicio.
                        ''',
                      ),
                      
                      _buildSection(
                        title: '2. Uso de la Información',
                        icon: LucideIcons.target,
                        content: '''
Utilizamos tu información para:

• Proporcionar y personalizar los servicios de rehabilitación.
• Generar reportes de progreso para ti y tu terapeuta.
• Mejorar nuestros algoritmos de asistencia con IA.
• Enviar recordatorios y notificaciones sobre tus ejercicios.
• Comunicarnos contigo sobre tu cuenta y servicios.
• Cumplir con obligaciones legales y regulatorias.
                        ''',
                      ),
                      
                      _buildSection(
                        title: '3. Compartición de Datos',
                        icon: LucideIcons.users,
                        content: '''
Compartimos tu información únicamente con:

• Tu terapeuta asignado: Para que pueda monitorear tu progreso y ajustar tu tratamiento.
• Proveedores de servicios: Empresas que nos ayudan a operar la app (almacenamiento en la nube, análisis).
• Autoridades legales: Cuando sea requerido por ley.

Nunca vendemos tu información personal a terceros.
                        ''',
                      ),
                      
                      _buildSection(
                        title: '4. Seguridad de Datos',
                        icon: LucideIcons.shield,
                        content: '''
Protegemos tu información mediante:

• Encriptación de datos en tránsito y en reposo.
• Autenticación segura con Firebase Authentication.
• Acceso restringido a datos sensibles.
• Auditorías de seguridad regulares.
• Cumplimiento con estándares de la industria de salud.
                        ''',
                      ),
                      
                      _buildSection(
                        title: '5. Tus Derechos',
                        icon: LucideIcons.userCheck,
                        content: '''
Tienes derecho a:

• Acceder a tus datos personales.
• Corregir información inexacta.
• Solicitar la eliminación de tus datos.
• Exportar tus datos en formato portable.
• Revocar consentimientos otorgados.
• Presentar quejas ante autoridades de protección de datos.

Para ejercer estos derechos, contacta a privacidad@rehabtech.com
                        ''',
                      ),
                      
                      _buildSection(
                        title: '6. Retención de Datos',
                        icon: LucideIcons.clock,
                        content: '''
Conservamos tu información mientras:

• Tu cuenta esté activa.
• Sea necesario para proporcionar servicios.
• Sea requerido por ley o regulaciones.

Después de eliminar tu cuenta, los datos se eliminan en un plazo de 30 días, excepto aquellos que debamos conservar por obligaciones legales.
                        ''',
                      ),
                      
                      _buildSection(
                        title: '7. Uso de Cámara',
                        icon: LucideIcons.camera,
                        content: '''
La cámara se utiliza exclusivamente para:

• Guiarte durante las sesiones de ejercicio.
• Proporcionar retroalimentación sobre tu postura.

Las imágenes de la cámara se procesan localmente en tu dispositivo y NO se almacenan ni transmiten a nuestros servidores.
                        ''',
                      ),
                      
                      _buildSection(
                        title: '8. Contacto',
                        icon: LucideIcons.mail,
                        content: '''
Para preguntas sobre privacidad:

📧 Email: privacidad@rehabtech.com
📍 Dirección: Av. Tecnológico 123, Monterrey, N.L., México

Responderemos a tu consulta en un plazo máximo de 72 horas.
                        ''',
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Aceptación
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF22C55E).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  LucideIcons.circleCheck,
                                  color: Color(0xFF22C55E),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Al usar RehabTech, aceptas esta política de privacidad.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.green[800],
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
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSection({
    required String title,
    required IconData icon,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: const Color(0xFF3B82F6),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  content.trim(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
