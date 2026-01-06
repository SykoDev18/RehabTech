import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class TherapistChatScreen extends StatefulWidget {
  const TherapistChatScreen({super.key});

  @override
  State<TherapistChatScreen> createState() => _TherapistChatScreenState();
}

class _TherapistChatScreenState extends State<TherapistChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    // Mensajes de ejemplo
    _messages.addAll([
      _ChatMessage(
        text: 'Hola Dr. Garza, tengo una pregunta sobre mi rutina de hoy.',
        isMe: true,
        time: '10:30',
      ),
      _ChatMessage(
        text: '¡Hola! Claro, dime en qué te puedo ayudar.',
        isMe: false,
        time: '10:32',
      ),
      _ChatMessage(
        text: 'Siento una pequeña molestia en la rodilla derecha al hacer las sentadillas. ¿Es normal?',
        isMe: true,
        time: '10:33',
      ),
      _ChatMessage(
        text: 'Es importante saber si es dolor o solo tensión muscular. ¿La molestia es aguda o es más como cansancio muscular?',
        isMe: false,
        time: '10:34',
      ),
      _ChatMessage(
        text: 'Es más como tensión, no es dolor agudo.',
        isMe: true,
        time: '10:35',
      ),
      _ChatMessage(
        text: 'Perfecto. Voy a añadir algunos ejercicios de calentamiento específicos para la rodilla antes de las sentadillas. Eso debería ayudar.',
        isMe: false,
        time: '10:36',
      ),
    ]);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(
        text: text,
        isMe: true,
        time: TimeOfDay.now().format(context),
      ));
    });
    _textController.clear();
    _scrollToBottom();

    // Simular respuesta del terapeuta
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(
            text: 'Gracias por tu mensaje. Te responderé lo antes posible.',
            isMe: false,
            time: TimeOfDay.now().format(context),
          ));
        });
        _scrollToBottom();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFDBEAFE), Color(0xFFD1FAE5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: _buildMessagesList(),
              ),
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
          ),
          child: Row(
            children: [
              // Botón atrás
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  LucideIcons.chevronLeft,
                  color: const Color(0xFF2563EB),
                  size: 28,
                ),
              ),
              
              // Avatar y nombre
              Stack(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=200&h=200&fit=crop',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          LucideIcons.user,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              
              // Nombre y estado
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dr. Elena Garza',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.stethoscope,
                          size: 12,
                          color: const Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Fisioterapeuta',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Botones de acción
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  LucideIcons.video,
                  color: const Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B7280).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  LucideIcons.info,
                  color: const Color(0xFF6B7280),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final showAvatar = !message.isMe && 
            (index == 0 || _messages[index - 1].isMe);
        
        return Padding(
          padding: EdgeInsets.only(
            bottom: 8,
            left: message.isMe ? 48 : 0,
            right: message.isMe ? 0 : 48,
          ),
          child: Row(
            mainAxisAlignment: message.isMe 
                ? MainAxisAlignment.end 
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!message.isMe && showAvatar)
                Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=100&h=100&fit=crop',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        LucideIcons.user,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                )
              else if (!message.isMe)
                const SizedBox(width: 40),
              
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: message.isMe
                        ? const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          )
                        : null,
                    color: message.isMe ? null : Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(message.isMe ? 18 : 4),
                      bottomRight: Radius.circular(message.isMe ? 4 : 18),
                    ),
                    border: message.isMe 
                        ? null 
                        : Border.all(color: Colors.white.withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        message.text,
                        style: TextStyle(
                          fontSize: 15,
                          color: message.isMe ? Colors.white : const Color(0xFF1F2937),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message.time,
                        style: TextStyle(
                          fontSize: 11,
                          color: message.isMe 
                              ? Colors.white.withOpacity(0.7) 
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            16, 
            12, 
            16, 
            12 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
          ),
          child: Row(
            children: [
              // Botón adjuntar
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  LucideIcons.paperclip,
                  color: const Color(0xFF6B7280),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              
              // Input
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF1F2937),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Botón enviar
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    LucideIcons.send,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isMe;
  final String time;

  _ChatMessage({
    required this.text,
    required this.isMe,
    required this.time,
  });
}
