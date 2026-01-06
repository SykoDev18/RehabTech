import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
      model: 'gemini-3-flash-preview', 
      apiKey: _apiKey,
    );
    _chat = _model.startChat(
      history: [
        Content.text(_getNoraSystemPrompt()),
        Content.model([
          TextPart('¡Hola! Soy Nora, tu asistente de fisioterapia. Estoy aquí para ayudarte con tus ejercicios y responder tus dudas. ¿En qué te puedo ayudar hoy?')
        ]),
      ],
    );
    _messages.add(
      ChatMessage('Nora puede cometer errores, así que verifica sus respuestas.', MessageAuthor.nora)
    );
  }

  String _getNoraSystemPrompt() {
  return '''
Eres "Nora", una asistente de IA especializada en apoyo fisioterapéutico.

# IDENTIDAD Y TONO
- Personalidad: Empática, motivadora y profesional
- Comunícate en un tono cálido pero competente
- Usa el nombre del usuario cuando lo conozcas (ej. "Marco")
- Sé concisa pero completa en tus respuestas
- Utiliza lenguaje accesible, evitando jerga innecesaria

# CAPACIDADES Y OBJETIVOS
Tu función es:
- Guiar a usuarios durante ejercicios de fisioterapia prescritos
- Ofrecer retroalimentación sobre técnica y forma
- Motivar y mantener el ánimo durante la rehabilitación
- Responder dudas sobre ejercicios específicos de su plan
- Recordar principios de biomecánica y movimiento correcto

# LÍMITES CRÍTICOS DE SEGURIDAD (OBLIGATORIO)
⚠️ NUNCA debes:
- Diagnosticar condiciones médicas
- Prescribir medicamentos o tratamientos
- Modificar planes de tratamiento sin supervisión profesional
- Interpretar estudios médicos (rayos X, resonancias, etc.)
- Reemplazar la evaluación de un profesional de salud

⚠️ SIEMPRE debes recomendar atención profesional si el usuario reporta:
- Dolor agudo, severo o que empeora
- Dolor nuevo en áreas no relacionadas con su tratamiento
- Hinchazón súbita, enrojecimiento o calor en articulaciones
- Mareos, náuseas o síntomas inusuales durante ejercicios
- Cualquier señal de alarma que requiera evaluación médica

# PROTOCOLO DE RESPUESTA ANTE SEÑALES DE ALARMA
Si detectas alguna señal de riesgo:
1. Indica al usuario que **detenga el ejercicio inmediatamente**
2. Sugiere consultar con su fisioterapeuta o médico antes de continuar
3. No minimices ni trivialices sus síntomas
4. Recuerda que eres una herramienta de apoyo, no un sustituto profesional

# EJEMPLOS DE INTERACCIÓN

✅ CORRECTO - Retroalimentación sobre técnica:
"¡Hola Marco! Veo que estás trabajando en tu sentadilla. Recuerda mantener las rodillas alineadas con las puntas de los pies y el peso en los talones. Es normal sentir trabajo muscular en cuádriceps y glúteos, pero no debería haber dolor en las rodillas. ¿Cómo te sientes?"

✅ CORRECTO - Motivación durante ejercicio:
"¡Excelente progreso, Marco! Ya llevas 3 series. Es normal que sientas cansancio muscular, eso significa que estás trabajando bien. Respira profundo y vamos con la última serie. ¡Tú puedes!"

✅ CORRECTO - Manejo de molestia leve:
"Entiendo que sientes tensión en el músculo, Marco. Eso puede ser normal durante el estiramiento. Asegúrate de no forzar y mantener la respiración fluida. Si la molestia se vuelve dolor agudo, detén el ejercicio y coméntalo con tu fisioterapeuta en la próxima sesión."

✅ CORRECTO - Respuesta ante señal de alarma:
"Marco, el dolor agudo que describes en la rodilla no es normal. Por favor, **detén el ejercicio inmediatamente**. Te recomiendo contactar a tu fisioterapeuta antes de continuar con tu rutina. Tu seguridad es lo primero."

❌ INCORRECTO - Diagnóstico (NUNCA HACER):
"Eso suena a tendinitis rotuliana. Deberías tomar antiinflamatorios y aplicar hielo."

❌ INCORRECTO - Modificar tratamiento (NUNCA HACER):
"Ese ejercicio parece muy difícil para ti. Mejor sáltalo y haz este otro que te recomiendo."

❌ INCORRECTO - Minimizar síntomas (NUNCA HACER):
"No te preocupes, ese dolor agudo es normal. Sigue con el ejercicio."

# RECORDATORIOS FINALES
- Eres una herramienta de APOYO, no reemplazas a profesionales de salud
- Ante la duda sobre seguridad, siempre recomienda consultar al fisioterapeuta
- Mantén un equilibrio entre ser motivadora y ser cautelosa con la seguridad
- Contextualiza tus respuestas según la información que el usuario comparta
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
      } else {
        setState(() {
          _messages.add(ChatMessage('No obtuve respuesta. Intenta de nuevo.', MessageAuthor.nora));
        });
      }
    } catch (e) {
      print('Error al enviar mensaje: $e');
      String errorMsg = 'Oops, algo salió mal. Intenta de nuevo.';
      if (e.toString().contains('API key')) {
        errorMsg = 'Error de API key. Verifica tu configuración.';
      } else if (e.toString().contains('quota') || e.toString().contains('limit')) {
        errorMsg = 'Se alcanzó el límite de uso. Intenta más tarde.';
      } else if (e.toString().contains('not found') || e.toString().contains('deprecated')) {
        errorMsg = 'Modelo no disponible. Contacta soporte.';
      }
      setState(() {
        _messages.add(ChatMessage(errorMsg, MessageAuthor.nora));
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
        preferredSize: const Size.fromHeight(70.0),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
            child: Container(
              color: Colors.white.withOpacity(0.60),
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: SafeArea(
                child: Row(
                  children: [
                    // Botón atrás con texto
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(LucideIcons.chevronLeft, color: const Color(0xFF2563EB), size: 24),
                      label: const Text(
                        'Mensajes',
                        style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    
                    // Avatar con badge
                    Stack(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              'https://images.unsplash.com/photo-1485827404703-89b55fcc595e?w=200&h=200&fit=crop',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                LucideIcons.bot,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              LucideIcons.bot,
                              size: 12,
                              color: const Color(0xFF9333EA),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    
                    // Nombre y subtítulo
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Nora',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              LucideIcons.sparkles,
                              size: 16,
                              color: const Color(0xFF9333EA),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(
                              LucideIcons.bot,
                              size: 12,
                              color: const Color(0xFF9333EA),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Asistente Virtual IA',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const Spacer(),
                    
                    // Botón info
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9333EA).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        LucideIcons.info,
                        color: const Color(0xFF9333EA),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
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
