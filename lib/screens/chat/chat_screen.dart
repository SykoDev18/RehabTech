import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/repositories/firestore_conversation_repository.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/repositories/conversation_repository.dart';
import 'widgets/message_bubble.dart';

/// Real-time patient↔therapist chat screen.
///
/// Two entry modes:
///   - `otherUserId`: caller knows the other party but not the
///     conversation (e.g. patient tapping "Mensaje" on MyTherapistScreen,
///     therapist tapping the chat icon on a patient card). The screen
///     idempotently `getOrCreate`s the conversation on init.
///   - `conversationId`: caller already knows the conversation (e.g.
///     opened from the conversations list). Skips the lookup.
///
/// Uses [ConversationRepository] for all Firestore work — never calls
/// Firestore directly so the role-specific schema stays internal.
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    this.otherUserId,
    this.conversationId,
    ConversationRepository? repository,
    super.key,
  })  : _repository = repository,
        assert(
          otherUserId != null || conversationId != null,
          'Must provide either otherUserId or conversationId',
        );

  final String? otherUserId;
  final String? conversationId;
  final ConversationRepository? _repository;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

sealed class _ChatUiState {
  const _ChatUiState();
}

final class _ChatLoading extends _ChatUiState {
  const _ChatLoading();
}

final class _ChatReady extends _ChatUiState {
  const _ChatReady(this.conversationId);
  final String conversationId;
}

final class _ChatError extends _ChatUiState {
  const _ChatError(this.message);
  final String message;
}

class _ChatScreenState extends State<ChatScreen> {
  late final ConversationRepository _repository =
      widget._repository ?? FirestoreConversationRepository();
  late final TextEditingController _controller = TextEditingController();
  late final ScrollController _scrollController = ScrollController();

  _ChatUiState _state = const _ChatLoading();
  bool _isSending = false;
  String? _myUid;
  String? _resolvedOtherUserId;
  int _lastSeenIncomingCount = 0;

  @override
  void initState() {
    super.initState();
    _myUid = FirebaseAuth.instance.currentUser?.uid;
    _resolvedOtherUserId = widget.otherUserId;
    _initConversation();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initConversation() async {
    final myUid = _myUid;
    if (myUid == null) {
      setState(() => _state =
          const _ChatError('Inicia sesión para usar el chat.'));
      return;
    }

    try {
      final String resolvedConvId;
      if (widget.conversationId != null) {
        resolvedConvId = widget.conversationId!;
      } else {
        final conv = await _repository.getOrCreateConversation(
          myUid,
          widget.otherUserId!,
        );
        resolvedConvId = conv.id;
        _resolvedOtherUserId = conv.otherParticipantId(myUid);
      }

      if (!mounted) return;
      setState(() => _state = _ChatReady(resolvedConvId));

      // Reset unread on open. Errors here are non-fatal — the badge
      // will just stay stale until the next open.
      unawaited(_repository.markAsRead(
        conversationId: resolvedConvId,
        uid: myUid,
      ));
    } on Exception {
      if (!mounted) return;
      setState(() => _state = const _ChatError(
            'No se pudo abrir el chat. Verifica tu conexión.',
          ));
    }
  }

  Future<void> _sendMessage(String conversationId) async {
    final text = _controller.text.trim();
    final myUid = _myUid;
    if (text.isEmpty || _isSending || myUid == null) return;

    _controller.clear();
    setState(() => _isSending = true);

    try {
      await _repository.sendMessage(
        conversationId: conversationId,
        senderId: myUid,
        text: text,
      );
    } on Exception {
      if (!mounted) return;
      _controller.text = text;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo enviar. Intenta de nuevo.')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _maybeMarkRead(
    String conversationId,
    List<ChatMessage> messages,
  ) {
    final myUid = _myUid;
    if (myUid == null) return;
    final incoming = messages.where((m) => !m.isSentBy(myUid)).length;
    if (incoming == _lastSeenIncomingCount) return;
    _lastSeenIncomingCount = incoming;
    unawaited(_repository.markAsRead(
      conversationId: conversationId,
      uid: myUid,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    final Widget body;
    if (state is _ChatReady) {
      body = _buildReady(context, state.conversationId);
    } else if (state is _ChatError) {
      body = _ErrorView(
        message: state.message,
        onRetry: _initConversation,
      );
    } else {
      body = const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(child: body),
    );
  }

  Widget _buildReady(BuildContext context, String conversationId) {
    return Column(
      children: [
        _ChatHeader(otherUserId: _resolvedOtherUserId),
        Expanded(
          child: StreamBuilder<List<ChatMessage>>(
            stream: _repository.watchMessages(conversationId),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting &&
                  !snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No se pudieron cargar los mensajes.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final messages = snap.data ?? const <ChatMessage>[];

              if (messages.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Sin mensajes aún. ¡Di hola! 👋',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                  ),
                );
              }

              _maybeMarkRead(conversationId, messages);

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  );
                }
              });

              final myUid = _myUid;
              return ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  // reverse: true means index 0 is the bottom (newest).
                  final msg = messages[messages.length - 1 - index];
                  final isMe = myUid != null && msg.isSentBy(myUid);
                  return MessageBubble(message: msg, isMe: isMe);
                },
              );
            },
          ),
        ),
        _MessageInputBar(
          controller: _controller,
          isSending: _isSending,
          onSend: () => _sendMessage(conversationId),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.circleAlert,
                size: 48, color: Color(0xFFEF4444)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.rotateCw),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.otherUserId});
  final String? otherUserId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.chevronLeft),
            color: const Color(0xFF3B82F6),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 4),
          if (otherUserId == null)
            const _OtherUserPlaceholder()
          else
            Expanded(
              child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUserId!)
                    .snapshots(),
                builder: (context, snap) {
                  final data = snap.data?.data() ?? const {};
                  final firstName = (data['name'] as String?) ?? '';
                  final lastName = (data['lastName'] as String?) ?? '';
                  final fullName = '$firstName $lastName'.trim();
                  final displayName =
                      fullName.isEmpty ? 'Conversación' : fullName;
                  final photoUrl = (data['photoUrl'] as String?) ?? '';
                  final initials = _initials(fullName);
                  return Row(
                    children: [
                      _Avatar(initials: initials, photoUrl: photoUrl),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const Text(
                              'En línea',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF22C55E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0]
        .substring(0, parts[0].length >= 2 ? 2 : 1)
        .toUpperCase();
  }
}

class _OtherUserPlaceholder extends StatelessWidget {
  const _OtherUserPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Expanded(
      child: Text(
        'Conversación',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: Color(0xFF111827),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials, required this.photoUrl});
  final String initials;
  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    if (photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(photoUrl),
        backgroundColor: const Color(0xFF3B82F6),
      );
    }
    return CircleAvatar(
      radius: 20,
      backgroundColor: const Color(0xFF3B82F6),
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _MessageInputBar extends StatefulWidget {
  const _MessageInputBar({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  State<_MessageInputBar> createState() => _MessageInputBarState();
}

class _MessageInputBarState extends State<_MessageInputBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuildOnTextChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuildOnTextChange);
    super.dispose();
  }

  void _rebuildOnTextChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final canSend =
        !widget.isSending && widget.controller.text.trim().isNotEmpty;
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        10 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: widget.controller,
                decoration: const InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                style: const TextStyle(fontSize: 15),
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: canSend ? widget.onSend : null,
            style: IconButton.styleFrom(
              backgroundColor: canSend
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFFD1D5DB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(12),
            ),
            icon: widget.isSending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(LucideIcons.send, size: 20),
          ),
        ],
      ),
    );
  }
}

/// Local clone of the standard `unawaited` to avoid pulling in
/// `dart:async` everywhere — we only fire-and-forget two non-critical
/// markAsRead calls.
void unawaited(Future<void> _) {}
