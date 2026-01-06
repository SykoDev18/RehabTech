import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  String _selectedCategory = 'Todos';
  
  final List<Map<String, String>> _faqs = [
    {
      'category': 'Cuenta',
      'question': '¿Cómo cambio mi contraseña?',
      'answer': 'Ve a Mi Perfil > Seguridad > Cambiar Contraseña. Ingresa tu contraseña actual y luego la nueva contraseña dos veces para confirmar.',
    },
    {
      'category': 'Cuenta',
      'question': '¿Cómo actualizo mi información personal?',
      'answer': 'Ve a Mi Perfil > Editar Perfil. Ahí podrás modificar tu nombre, correo, teléfono y otra información personal.',
    },
    {
      'category': 'Ejercicios',
      'question': '¿Cómo inicio una sesión de ejercicios?',
      'answer': 'Ve a la sección de Ejercicios, selecciona el ejercicio que deseas realizar y presiona "Iniciar Sesión". La cámara se activará para guiarte durante el ejercicio.',
    },
    {
      'category': 'Ejercicios',
      'question': '¿Qué hago si siento dolor durante un ejercicio?',
      'answer': 'Si sientes dolor intenso, detén el ejercicio inmediatamente. Reporta el nivel de dolor al finalizar la sesión. Si el dolor persiste, contacta a tu terapeuta.',
    },
    {
      'category': 'Ejercicios',
      'question': '¿Cómo funciona el asistente de voz IA?',
      'answer': 'Nora, nuestra asistente de IA, te guía durante los ejercicios con consejos de técnica y motivación. Puedes hacerle preguntas tocando el botón del asistente.',
    },
    {
      'category': 'Progreso',
      'question': '¿Cómo veo mi progreso?',
      'answer': 'Ve a la sección de Progreso donde encontrarás gráficas de tu rendimiento, estadísticas semanales, mensuales y totales de tus sesiones.',
    },
    {
      'category': 'Progreso',
      'question': '¿Cómo comparto mi progreso con mi terapeuta?',
      'answer': 'En la sección de Progreso, presiona el botón de compartir. Puedes generar un PDF con tu reporte y enviarlo por correo o mensaje.',
    },
    {
      'category': 'Técnico',
      'question': '¿La app funciona sin internet?',
      'answer': 'Algunas funciones básicas están disponibles sin conexión, pero necesitas internet para el asistente de IA, sincronizar tu progreso y contactar a tu terapeuta.',
    },
    {
      'category': 'Técnico',
      'question': '¿Por qué la cámara no funciona?',
      'answer': 'Asegúrate de que la app tiene permisos de cámara. Ve a Configuración de tu teléfono > Apps > RehabTech > Permisos y activa la cámara.',
    },
  ];

  List<Map<String, String>> get _filteredFaqs {
    if (_selectedCategory == 'Todos') return _faqs;
    return _faqs.where((faq) => faq['category'] == _selectedCategory).toList();
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
                          color: Colors.white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(LucideIcons.arrowLeft, size: 22),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Centro de Ayuda',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Categorías
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    _buildCategoryChip('Todos', LucideIcons.layoutGrid),
                    _buildCategoryChip('Cuenta', LucideIcons.user),
                    _buildCategoryChip('Ejercicios', LucideIcons.dumbbell),
                    _buildCategoryChip('Progreso', LucideIcons.chartLine),
                    _buildCategoryChip('Técnico', LucideIcons.settings),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // FAQs
                      const Text(
                        'Preguntas Frecuentes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      ..._filteredFaqs.map((faq) => _buildFaqCard(faq)),
                      
                      const SizedBox(height: 32),
                      
                      // Contactar soporte
                      _buildContactSupportCard(),
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
  
  Widget _buildCategoryChip(String label, IconData icon) {
    final isSelected = _selectedCategory == label;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategory = label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF3B82F6)
                : Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF3B82F6)
                  : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : const Color(0xFF6B7280),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFaqCard(Map<String, String> faq) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.white.withOpacity(0.6),
            collapsedBackgroundColor: Colors.white.withOpacity(0.6),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                LucideIcons.info,
                color: const Color(0xFF3B82F6),
                size: 20,
              ),
            ),
            title: Text(
              faq['question']!,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            subtitle: Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                faq['category']!,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF22C55E),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            children: [
              Text(
                faq['answer']!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildContactSupportCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF3B82F6).withOpacity(0.1),
                const Color(0xFF8B5CF6).withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.headphones,
                  color: Color(0xFF3B82F6),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '¿No encontraste lo que buscabas?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Nuestro equipo de soporte está listo para ayudarte',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildContactButton(
                      icon: LucideIcons.mail,
                      label: 'Email',
                      onTap: () => _launchEmail(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildContactButton(
                      icon: LucideIcons.messageCircle,
                      label: 'Chat',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Abriendo chat de soporte...')),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _launchEmail() async {
    final uri = Uri.parse('mailto:soporte@rehabtech.com?subject=Ayuda%20con%20RehabTech');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se puede abrir el correo')),
      );
    }
  }
}
