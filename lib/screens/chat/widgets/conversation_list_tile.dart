import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../domain/models/conversation.dart';

/// One row of the conversations list. Resolves the other party's
/// display info via a `users/{uid}` lookup. The Firestore SDK caches
/// these reads in-memory between rebuilds, so a `FutureBuilder` here
/// is fine without an explicit cache layer.
class ConversationListTile extends StatelessWidget {
  const ConversationListTile({
    required this.conversation,
    required this.myUid,
    required this.onTap,
    super.key,
  });

  final Conversation conversation;
  final String myUid;
  final VoidCallback onTap;

  String get _otherUid => conversation.otherParticipantId(myUid);
  int get _unread => conversation.unreadFor(myUid);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(_otherUid)
              .get(),
          builder: (context, snap) {
            final data = snap.data?.data() ?? const <String, dynamic>{};
            final firstName = (data['name'] as String?) ?? '';
            final lastName = (data['lastName'] as String?) ?? '';
            final fullName = '$firstName $lastName'.trim();
            final fallback =
                conversation.patientName?.trim().isNotEmpty == true
                    ? conversation.patientName!
                    : 'Conversación';
            final displayName = fullName.isEmpty ? fallback : fullName;
            final photoUrl = (data['photoUrl'] as String?) ?? '';
            return _Tile(
              displayName: displayName,
              photoUrl: photoUrl,
              lastMessage: conversation.lastMessage,
              lastMessageAt: conversation.lastMessageAt,
              unread: _unread,
            );
          },
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.displayName,
    required this.photoUrl,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unread,
  });

  final String displayName;
  final String photoUrl;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unread;

  @override
  Widget build(BuildContext context) {
    final hasUnread = unread > 0;
    final preview = (lastMessage == null || lastMessage!.isEmpty)
        ? 'Sin mensajes'
        : lastMessage!;
    final time = _formatTimestamp(lastMessageAt);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _Avatar(displayName: displayName, photoUrl: photoUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        hasUnread ? FontWeight.bold : FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: hasUnread
                        ? const Color(0xFF374151)
                        : const Color(0xFF9CA3AF),
                    fontWeight:
                        hasUnread ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                time,
                style: TextStyle(
                  fontSize: 11,
                  color: hasUnread
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFF9CA3AF),
                  fontWeight:
                      hasUnread ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              if (hasUnread) ...[
                const SizedBox(height: 6),
                Container(
                  constraints: const BoxConstraints(minWidth: 20),
                  height: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    unread > 99 ? '99+' : '$unread',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static String _formatTimestamp(DateTime? t) {
    if (t == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tDay = DateTime(t.year, t.month, t.day);
    final diffDays = today.difference(tDay).inDays;
    String two(int n) => n.toString().padLeft(2, '0');
    if (diffDays == 0) return '${two(t.hour)}:${two(t.minute)}';
    if (diffDays == 1) return 'Ayer';
    if (diffDays < 7) {
      const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      return days[t.weekday - 1];
    }
    return '${two(t.day)}/${two(t.month)}';
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.displayName, required this.photoUrl});

  final String displayName;
  final String photoUrl;

  String get _initials {
    final n = displayName.trim();
    if (n.isEmpty) return '?';
    final parts = n.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0]
        .substring(0, parts[0].length >= 2 ? 2 : 1)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(photoUrl),
        backgroundColor: const Color(0xFF3B82F6),
      );
    }
    return CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFF3B82F6),
      child: Text(
        _initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
