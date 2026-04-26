import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../domain/constants/achievement_catalog.dart';
import '../../domain/entities/user_achievement_entity.dart';
import '../../data/repositories/achievement_repository_impl.dart';
import '../../presentation/widgets/common/app_gradient_background.dart';
import 'widgets/achievement_card.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final repository = AchievementRepositoryImpl();

    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: user == null
              ? const Center(child: Text('Inicia sesión para ver tus logros'))
              : StreamBuilder<List<UserAchievementEntity>>(
                  stream: repository.watchUnlocked(user.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final unlocked = snapshot.data ?? const [];
                    final unlockedById = {
                      for (final u in unlocked) u.achievementId: u,
                    };
                    final totalPoints = achievementCatalog
                        .where((a) => unlockedById.containsKey(a.id))
                        .fold<int>(0, (sum, a) => sum + a.points);

                    return CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: _buildHeader(
                            context,
                            unlockedCount: unlocked.length,
                            totalCount: achievementCatalog.length,
                            totalPoints: totalPoints,
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.85,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final achievement = achievementCatalog[index];
                                final unlock = unlockedById[achievement.id];
                                return AchievementCard(
                                  achievement: achievement,
                                  unlocked: unlock != null,
                                  unlockedAt: unlock?.unlockedAt,
                                );
                              },
                              childCount: achievementCatalog.length,
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required int unlockedCount,
    required int totalCount,
    required int totalPoints,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: themedGlassColor(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    LucideIcons.arrowLeft,
                    size: 22,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Logros',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: themedGlassColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: themedGlassBorder(context)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Stat(label: 'Desbloqueados', value: '$unlockedCount/$totalCount'),
                Container(
                  width: 1,
                  height: 32,
                  color: colorScheme.outlineVariant,
                ),
                _Stat(label: 'Puntos', value: '$totalPoints'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2563EB),
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
