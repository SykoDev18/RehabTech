import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rehabtech/core/utils/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rehabtech/services/analytics_service.dart';
import 'package:rehabtech/services/nora_service.dart';

enum MessageAuthor { user, nora }

class ChatMessage {
  final String text;
  final MessageAuthor author;
  final DateTime timestamp;
  
  ChatMessage(this.text, this.author, {DateTime? timestamp}) 
      : timestamp = timestamp ?? DateTime.now();
  
  Map<String, dynamic> toMap() => {
    'text': text,
    'author': author == MessageAuthor.user ? 'user' : 'nora',
    'timestamp': Timestamp.fromDate(timestamp),
  };
  
  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
    map['text'] ?? '',
    map['author'] == 'user' ? MessageAuthor.user : MessageAuthor.nora,
    timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );
}

// Modelo para conversaciones guardadas
class ChatConversation {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final String? lastMessage;
  
  ChatConversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.lastMessageAt,
    this.lastMessage,
  });
  
  factory ChatConversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatConversation(
      id: doc.id,
      title: data['title'] ?? 'Conversación',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessage: data['lastMessage'],
    );
  }
}

// Widget animado de "escribiendo..." con puntos
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _dotCount = 1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _dotCount = (_dotCount % 3) + 1;
          });
          _controller.forward(from: 0);
        }
      });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 0.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(LucideIcons.bot, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Text(
                  '•' * _dotCount,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9333EA),
                    letterSpacing: 4,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AiChatScreen extends StatefulWidget {
  final String? conversationId;
  
  const AiChatScreen({super.key, this.conversationId});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _initFailed = false;
  String? _initError;

  // Firebase
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  String? _conversationId;
  String? _userName;
  String _patientContext = '';

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    final key = dotenv.env['GEMINI_API_KEY'];
    if (key == null || key.isEmpty) {
      AppLogger.error('No se pudo cargar GEMINI_API_KEY desde .env', tag: 'NoraChat');
      if (mounted) {
        setState(() {
          _initFailed = true;
          _initError = 'No se pudo conectar con Nora. Falta la configuración de API.';
        });
      }
      return;
    }

    await _loadUserData();
    await _loadPatientContext();

    if (_conversationId != null) {
      await _loadConversation();
    } else {
      await _createNewConversation();
    }

    if (mounted) setState(() => _isInitialized = true);
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        _userName = userDoc.data()?['name'] ?? 'Usuario';
      }
    }
  }

  Future<void> _loadPatientContext() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final patientDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('patient_context')
        .doc('summary')
        .get();

    if (patientDoc.exists) {
      _patientContext = patientDoc.data()?['context'] ?? '';
    }
  }

  Future<void> _updatePatientContext(String newInfo) async {
    final user = _auth.currentUser;
    if (user == null) return;

    _patientContext += '\n$newInfo';
    
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('patient_context')
        .doc('summary')
        .set({
          'context': _patientContext,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> _createNewConversation() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('nora_chats')
        .add({
          'title': 'Nueva conversación',
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessageAt': FieldValue.serverTimestamp(),
          'lastMessage': '',
        });

    _conversationId = docRef.id;
    
    _messages.add(ChatMessage(
      'Nora puede cometer errores, así que verifica sus respuestas.',
      MessageAuthor.nora,
    ));
  }

  Future<void> _loadConversation() async {
    final user = _auth.currentUser;
    if (user == null || _conversationId == null) return;

    final messagesSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('nora_chats')
        .doc(_conversationId)
        .collection('messages')
        .orderBy('timestamp')
        .get();

    _messages.clear();
    _messages.add(ChatMessage(
      'Nora puede cometer errores, así que verifica sus respuestas.',
      MessageAuthor.nora,
    ));

    for (var doc in messagesSnapshot.docs) {
      _messages.add(ChatMessage.fromMap(doc.data()));
    }
  }

  Future<void> _saveMessage(ChatMessage message) async {
    final user = _auth.currentUser;
    if (user == null || _conversationId == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('nora_chats')
        .doc(_conversationId)
        .collection('messages')
        .add(message.toMap());

    // Actualizar última actividad de la conversación
    String title = _messages.length <= 2 
        ? message.text.length > 30 
            ? '${message.text.substring(0, 30)}...' 
            : message.text
        : 'Conversación';

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('nora_chats')
        .doc(_conversationId)
        .update({
          'lastMessageAt': FieldValue.serverTimestamp(),
          'lastMessage': message.text.length > 50 
              ? '${message.text.substring(0, 50)}...' 
              : message.text,
          if (_messages.length <= 2) 'title': title,
        });
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

  Future<void> _extractAndSavePatientInfo(String userMessage) async {
    final keywords = [
      'lesión', 'dolor', 'operación', 'cirugía', 'años', 'edad',
      'trabajo', 'deporte', 'ejercicio', 'medicamento', 'alergia',
      'condición', 'diagnóstico', 'peso', 'altura', 'rodilla', 
      'espalda', 'hombro', 'cadera', 'tobillo', 'muñeca', 'tengo',
      'me duele', 'sufro', 'padezco'
    ];

    bool hasRelevantInfo = keywords.any((k) => 
        userMessage.toLowerCase().contains(k));

    if (hasRelevantInfo) {
      final timestamp = DateTime.now().toString().substring(0, 10);
      await _updatePatientContext('[$timestamp] $userMessage');
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    AnalyticsService().logChatMessage(isUser: true);
    _textController.clear();

    final userMessage = ChatMessage(text, MessageAuthor.user);
    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });
    _scrollToBottom();

    // Persist the user turn first so NoraService.buildHistoryFromFirestore
    // would see the same shape on a future cold start.
    await _saveMessage(userMessage);
    await _extractAndSavePatientInfo(text);

    // Build history payload from prior in-memory messages, skipping the
    // welcome sentinel at index 0 and the user turn we just added.
    final priorTurns = _messages
        .skip(1)
        .where((m) => m != userMessage)
        .map((m) => {
              'text': m.text,
              'author': m.author == MessageAuthor.user ? 'user' : 'nora',
            })
        .toList();
    final history = NoraService().buildHistoryFromFirestore(priorTurns);

    final NoraResponse response = await NoraService().sendMessage(
      userInput: text,
      history: history,
      userName: _userName,
      patientContext: _patientContext.isNotEmpty ? _patientContext : null,
    );

    if (kDebugMode && response is! NoraSuccess) {
      AppLogger.info(
        '[Nora] non-success response: ${response.runtimeType}',
        tag: 'NoraChat',
      );
    }

    if (!mounted) return;
    final reply = ChatMessage(response.userMessage, MessageAuthor.nora);
    setState(() {
      _messages.add(reply);
      _isLoading = false;
    });

    // Only persist genuine model replies. Canned safety / error responses
    // would pollute Firestore history and risk re-injection on reload.
    if (response is NoraSuccess) {
      await _saveMessage(reply);
    }

    _scrollToBottom();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // TODO(optimization): build() supera 330 líneas. Extraer:
  //   _ChatMessageList (StreamBuilder de mensajes),
  //   _ChatInputBar (TextField + botón enviar + estado pensando),
  //   _ChatHistoryDrawer (modal de historial).
  // Cachear `FirebaseAuth.instance.currentUser?.uid` en initState para
  // evitar consultarlo en cada rebuild.
  @override
  Widget build(BuildContext context) {
    if (_initFailed) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[100]!, Colors.green[100]!],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(LucideIcons.circleAlert, size: 56, color: Color(0xFFDC2626)),
                  const SizedBox(height: 16),
                  Text(
                    _initError ?? 'No se pudo iniciar Nora.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Color(0xFF111827), fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Volver'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[100]!, Colors.green[100]!],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFF9333EA)),
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
            child: Container(
              color: Colors.white.withValues(alpha: 0.60),
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
                              cacheWidth: 200,
                              cacheHeight: 200,
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
                    
                    // Botón historial
                    GestureDetector(
                      onTap: () => _showChatHistory(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9333EA).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          LucideIcons.history,
                          color: const Color(0xFF9333EA),
                          size: 20,
                        ),
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
                controller: _scrollController,
                padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 20),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  // Mostrar indicador de escritura al final
                  if (_isLoading && index == _messages.length) {
                    return const TypingIndicator();
                  }
                  
                  final message = _messages[index];
                  if (index == 0) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 20.0),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[100]!.withValues(alpha: 0.80),
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(color: Colors.grey[200]!.withValues(alpha: 0.60)),
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
                              color: Colors.white.withValues(alpha: 0.40),
                              borderRadius: BorderRadius.circular(20.0),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.60)),
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
            ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  color: Colors.white.withValues(alpha: 0.40),
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
                              fillColor: Colors.white.withValues(alpha: 0.60),
                              hintText: 'Escribe tu mensaje...',
                              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14.0),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                            ),
                            onFieldSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: _isLoading ? null : _sendMessage,
                          child: Container(
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _isLoading 
                                    ? [Colors.grey[400]!, Colors.grey[500]!]
                                    : [const Color(0xFF3B82F6), const Color(0xFF22D3EE)],
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

  void _showChatHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Historial de Chats',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        // Crear nueva conversación
                        setState(() => _isInitialized = false);
                        _conversationId = null;
                        _messages.clear();
                        await _createNewConversation();
                        if (mounted) setState(() => _isInitialized = true);
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('users')
                      .doc(_auth.currentUser?.uid)
                      .collection('nora_chats')
                      .orderBy('lastMessageAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final chats = snapshot.data!.docs
                        .map((doc) => ChatConversation.fromFirestore(doc))
                        .toList();

                    if (chats.isEmpty) {
                      return const Center(
                        child: Text(
                          'No hay conversaciones aún',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        final chat = chats[index];
                        final isCurrentChat = chat.id == _conversationId;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isCurrentChat 
                                ? const Color(0xFF9333EA).withValues(alpha: 0.1)
                                : Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: isCurrentChat 
                                ? Border.all(color: const Color(0xFF9333EA).withValues(alpha: 0.3))
                                : null,
                          ),
                          child: ListTile(
                            onTap: () async {
                              Navigator.pop(context);
                              if (chat.id != _conversationId) {
                                setState(() => _isInitialized = false);
                                _conversationId = chat.id;
                                await _loadConversation();
                                if (mounted) {
                                  setState(() => _isInitialized = true);
                                }
                              }
                            },
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                LucideIcons.messageCircle,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            title: Text(
                              chat.title,
                              style: TextStyle(
                                fontWeight: isCurrentChat ? FontWeight.bold : FontWeight.w500,
                                color: isCurrentChat ? const Color(0xFF9333EA) : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              chat.lastMessage ?? 'Sin mensajes',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatDate(chat.lastMessageAt),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                if (isCurrentChat)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF9333EA),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'Actual',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inHours < 1) return 'Hace ${diff.inMinutes}m';
    if (diff.inDays < 1) return 'Hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays}d';
    return '${date.day}/${date.month}/${date.year}';
  }
}
