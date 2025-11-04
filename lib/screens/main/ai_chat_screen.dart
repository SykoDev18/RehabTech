import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum MessageAuthor { user, nora }

class ChatMessage {
  final String text;
  final MessageAuthor author;
  ChatMessage(this.text, this.author);
}

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? 'NO_SE_ENCONTRO_LA_KEY';
  late final GenerativeModel _model;
  late final ChatSession _chat;

  @override
  void initState() {
    super.initState();
    // 3. (OPCIONAL) Añade una comprobación de que la key existe
    if (_apiKey == 'NO_SE_ENCONTRO_LA_KEY') {
      print('¡ERROR! No se pudo cargar la GEMINI_API_KEY desde el .env');
      // (Aquí podrías mostrar un error al usuario)
    }

    _model = GenerativeModel(
      model: 'gemini-pro', 
      apiKey: _apiKey, // <-- Ahora usa la key segura
    );
    _chat = _model.startChat(
      history: [
        Content.text(_getNoraSystemPrompt()),
        Content.model(
          '¡Hola! Soy Nora, tu asistente de fisioterapia. Estoy aquí para ayudarte con tus ejercicios y responder tus dudas. ¿En qué te puedo ayudar hoy?'
        ),
      ],
    );
    _messages.add(
      ChatMessage('Nora puede cometer errores, así que verifica sus respuestas.', MessageAuthor.nora)
    );
  }

  String _getNoraSystemPrompt() {
    return '''
      Eres "Nora", una asistente de IA para fisioterapia.
      Tu personalidad es: **Fisioterapeuta Profesional y Amigable**.

      Tus reglas son:
      1.  **Amigable:** Sé empática, alentadora y positiva. Saluda a los usuarios por su nombre (ej. "Marco") si lo sabes.
      2.  **Profesional:** Usa un lenguaje claro y basado en conceptos de fisioterapia. Tu objetivo es guiar y motivar.
      3.  **¡GUARDARRAIL DE SEGURIDAD MÁXIMA!:** -   **NUNCA** des un diagnóstico médico.
          -   **NUNCA** reemplaces el consejo de un doctor o fisioterapeuta humano.
          -   Si un usuario reporta dolor "agudo", "severo", "nuevo" o "preocupante", tu respuesta **DEBE** ser aconsejarle que pare el ejercicio y consulte a su fisioterapeuta humano de inmediato.
          -   Siempre recuerda al usuario que eres una IA.

      Ejemplo de respuesta (buena):
      "¡Hola Marco! Es normal sentir un poco de estiramiento, pero no debería doler. Asegúrate de que tu rodilla esté alineada. Si el dolor sigue, es mejor que lo pauses por hoy y lo comentes con tu terapeuta. ¡Vas muy bien!"

      Ejemplo de respuesta (MALA, ¡NO HACER!):
      "Oh, parece que tienes tendinitis. Tómate este ibuprofeno."
    ''';
  }

  Future<void> _sendMessage() async {
    final text = _textController.text;
    if (text.isEmpty) return;

    _textController.clear();
    
    setState(() {
      _messages.add(ChatMessage(text, MessageAuthor.user));
      _isLoading = true;
    });

    try {
      var response = await _chat.sendMessage(Content.text(text));
      var noraResponse = response.text;

      if (noraResponse != null) {
        setState(() {
          _messages.add(ChatMessage(noraResponse, MessageAuthor.nora));
        });
      }
    } catch (e) {
      print('Error al enviar mensaje: $e');
      setState(() {
        _messages.add(ChatMessage('Oops, algo salió mal. Intenta de nuevo.', MessageAuthor.nora));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
            child: Container(
              color: Colors.white.withOpacity(0.40),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Color(0xFF2563EB), size: 30),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Nora',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                        ),
                        Text(
                          'En línea',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF16A34A)),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline, color: Color(0xFF6B7280)),
                      onPressed: () { /* ... */ },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[100]!,
              Colors.green[100]!,
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 20),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  if (index == 0) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 20.0),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[100]!.withOpacity(0.80),
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(color: Colors.grey[200]!.withOpacity(0.60)),
                      ),
                      child: Text(
                        message.text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF4B5563), fontSize: 16),
                      ),
                    );
                  }
                  if (message.author == MessageAuthor.user) {
                    return Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6.0),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Text(
                          message.text,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    );
                  } else {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20.0),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6.0),
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.40),
                              borderRadius: BorderRadius.circular(20.0),
                              border: Border.all(color: Colors.white.withOpacity(0.60)),
                            ),
                            child: Text(
                              message.text,
                              style: const TextStyle(color: Color(0xFF111827), fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: CircularProgressIndicator(),
                ),
              ),
            ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  color: Colors.white.withOpacity(0.40),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _textController,
                            style: const TextStyle(color: Color(0xFF111827), fontSize: 16),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.60),
                              hintText: 'Escribe tu mensaje...',
                              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14.0),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: _sendMessage,
                          child: Container(
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF3B82F6), Color(0xFF22D3EE)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(14.0),
                            ),
                            child: const Icon(Icons.send, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
