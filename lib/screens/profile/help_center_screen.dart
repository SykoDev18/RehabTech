import 'dart:io' show SocketException;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:rehabtech/core/constants/api_constants.dart';
import 'package:rehabtech/core/utils/logger.dart';
import 'package:rehabtech/core/utils/url_launcher_helper.dart';

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
                          color: Colors.white.withValues(alpha: 0.6),
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
                : Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF3B82F6)
                  : Colors.grey.withValues(alpha: 0.3),
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
            backgroundColor: Colors.white.withValues(alpha: 0.6),
            collapsedBackgroundColor: Colors.white.withValues(alpha: 0.6),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
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
                color: const Color(0xFF22C55E).withValues(alpha: 0.1),
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
                const Color(0xFF3B82F6).withValues(alpha: 0.1),
                const Color(0xFF8B5CF6).withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
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
                      label: 'Chat IA',
                      onTap: () => _openSupportChat(context),
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
  
  Future<void> _launchEmail() async {
    await UrlLauncherHelper.launchEmail(
      context: context,
      to: 'rehabtechnoreply@gmail.com',
      subject: 'Solicitud de Ayuda - RehabTech',
      body: 'Hola, necesito ayuda con: ',
    );
  }

  void _openSupportChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const _SupportChatScreen(),
      ),
    );
  }
}

/// Pantalla de chat de soporte con IA
class _SupportChatScreen extends StatefulWidget {
  const _SupportChatScreen();

  @override
  State<_SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<_SupportChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  GenerativeModel? _model;
  ChatSession? _chat;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _addWelcomeMessage();
  }

  void _initializeChat() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isNotEmpty) {
      _model = GenerativeModel(
        model: ApiConstants.geminiModel,
        apiKey: apiKey,
        systemInstruction: Content.text('''
Eres el asistente de soporte técnico de RehabTech, una aplicación de rehabilitación física.
Tu rol es ayudar a los usuarios con:
- Problemas técnicos de la aplicación
- Preguntas sobre cómo usar funciones
- Dudas sobre ejercicios y sesiones
- Problemas con la cámara o el seguimiento
- Configuración de cuenta y perfil

Responde siempre en español, de manera amable y concisa.
Si no puedes resolver un problema, sugiere contactar a soporte por email: rehabtechnoreply@gmail.com
'''),
      );
      _chat = _model!.startChat();
    }
  }

  void _addWelcomeMessage() {
    _messages.add(_ChatMessage(
      text: '¡Hola! 👋 Soy el asistente de soporte de RehabTech. ¿En qué puedo ayudarte hoy?\n\nPuedes preguntarme sobre:\n• Problemas técnicos\n• Cómo usar la app\n• Ejercicios y sesiones\n• Tu cuenta y perfil',
      isUser: false,
    ));
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _chat == null) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await _chat!.sendMessage(Content.text(text));
      if (mounted && response.text != null) {
        setState(() {
          _messages.add(_ChatMessage(text: response.text!, isUser: false));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } on GenerativeAIException catch (e, st) {
      AppLogger.error('Error de Gemini en soporte', error: e, stackTrace: st, tag: 'HelpCenter');
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(
            text: 'El asistente no está disponible en este momento. Por favor intenta más tarde o contacta a soporte por email.',
            isUser: false,
          ));
          _isLoading = false;
        });
      }
    } on SocketException catch (e, st) {
      AppLogger.error('Sin conexión en soporte', error: e, stackTrace: st, tag: 'HelpCenter');
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(
            text: 'Sin conexión a internet. Verifica tu conexión e intenta de nuevo.',
            isUser: false,
          ));
          _isLoading = false;
        });
      }
    } catch (e, st) {
      AppLogger.error('Error inesperado en soporte', error: e, stackTrace: st, tag: 'HelpCenter');
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(
            text: 'Lo siento, hubo un error. Por favor intenta de nuevo o contacta a soporte por email.',
            isUser: false,
          ));
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.green[50]!],
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
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(LucideIcons.bot, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Soporte RehabTech',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          Text(
                            'Asistente IA • En línea',
                            style: TextStyle(fontSize: 12, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Messages
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _isLoading) {
                      return _buildTypingIndicator();
                    }
                    return _buildMessageBubble(_messages[index]);
                  },
                ),
              ),
              
              // Input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Escribe tu pregunta...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.send, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isUser ? const Color(0xFF3B82F6) : Colors.white,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: message.isUser ? const Radius.circular(4) : null,
            bottomLeft: !message.isUser ? const Radius.circular(4) : null,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
            ),
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser ? Colors.white : const Color(0xFF111827),
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            _buildDot(1),
            _buildDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[400],
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;

  _ChatMessage({required this.text, required this.isUser});
}
