import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/repositories/firestore_conversation_repository.dart';
import '../../domain/models/conversation.dart';
import '../../domain/repositories/conversation_repository.dart';
import 'chat_screen.dart';
import 'widgets/conversation_list_tile.dart';

/// Replaces the previously mocked patient-side messages screen. Lists
/// every patient↔therapist conversation the current user participates
/// in, plus a static "Nora" entry pinned to the top so AI chat is
/// always one tap away.
///
/// Both roles can use this screen — the underlying repository picks
/// the right `therapistId == X` / `patientId == X` query based on the
/// caller's `userType`.
class ConversationsScreen extends StatelessWidget {
  ConversationsScreen({
    this.showNoraEntry = true,
    ConversationRepository? repository,
    super.key,
  }) : _repository = repository ?? FirestoreConversationRepository();

  final bool showNoraEntry;
  final ConversationRepository _repository;

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: myUid == null
                  ? const _SignedOut()
                  : _ConversationsList(
                      myUid: myUid,
                      repository: _repository,
                      showNoraEntry: showNoraEntry,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          Text(
            'Mensajes',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignedOut extends StatelessWidget {
  const _SignedOut();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Inicia sesión para ver tus mensajes',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
      ),
    );
  }
}

class _ConversationsList extends StatelessWidget {
  const _ConversationsList({
    required this.myUid,
    required this.repository,
    required this.showNoraEntry,
  });

  final String myUid;
  final ConversationRepository repository;
  final bool showNoraEntry;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Conversation>>(
      stream: repository.watchConversations(myUid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No se pudieron cargar las conversaciones.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ),
          );
        }

        final convs = snap.data ?? const <Conversation>[];

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
          itemCount: convs.length + (showNoraEntry ? 1 : 0) + 1, // +1 = info card
          separatorBuilder: (_, _) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            // Pinned Nora entry first.
            if (showNoraEntry && index == 0) {
              return const _NoraEntry();
            }
            final convIndex = showNoraEntry ? index - 1 : index;
            if (convIndex < convs.length) {
              final conv = convs[convIndex];
              return ConversationListTile(
                conversation: conv,
                myUid: myUid,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(conversationId: conv.id),
                  ),
                ),
              );
            }
            // Final slot: privacy/info card or empty hint.
            return Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 0),
              child: convs.isEmpty
                  ? const _EmptyHint()
                  : const _PrivacyCard(),
            );
          },
        );
      },
    );
  }
}

class _NoraEntry extends StatelessWidget {
  const _NoraEntry();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/main/chat/nora'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  LucideIcons.sparkles,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nora — Asistente Virtual',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Pregúntale lo que necesites',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                LucideIcons.chevronRight,
                color: Color(0xFF9CA3AF),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Column(
        children: [
          Icon(
            LucideIcons.messageCircle,
            color: Color(0xFF8B5CF6),
            size: 32,
          ),
          SizedBox(height: 12),
          Text(
            'Sin conversaciones',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Escribe a tu terapeuta desde "Mi Terapeuta" en tu perfil.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: const Row(
        children: [
          Icon(
            LucideIcons.shieldCheck,
            color: Color(0xFF2563EB),
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tus mensajes son privados entre tú y tu terapeuta.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF1E3A8A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
