import '../entities/achievement_entity.dart';

/// Master catalog of achievements available in the app. The catalog is
/// versioned with the codebase — adding or removing achievements requires an
/// app release. The unlock predicate for each entry lives in
/// `services/achievement_service.dart` (kept there so the domain stays
/// dependency-free).
const List<AchievementEntity> achievementCatalog = [
  AchievementEntity(
    id: 'first_step',
    title: 'Primer Paso',
    description: 'Completaste tu primera sesión de ejercicio',
    iconName: 'footprints',
    condition: 'Completa una sesión',
    points: 10,
  ),
  AchievementEntity(
    id: 'pain_fighter',
    title: 'Luchador del Dolor',
    description: 'Registraste tu nivel de dolor durante 3 días seguidos',
    iconName: 'shield',
    condition: 'Registra dolor 3 días seguidos',
    points: 25,
  ),
  AchievementEntity(
    id: 'chatterbox',
    title: 'Conversador',
    description: 'Enviaste 10 mensajes a Nora',
    iconName: 'messages_square',
    condition: 'Envía 10 mensajes a Nora',
    points: 30,
  ),
  AchievementEntity(
    id: 'week_warrior',
    title: 'Guerrero de la Semana',
    description: 'Mantuviste una racha de 7 días',
    iconName: 'flame',
    condition: '7 días seguidos de actividad',
    points: 50,
  ),
  AchievementEntity(
    id: 'dedicated',
    title: 'Dedicación Total',
    description: 'Completaste 30 sesiones en total',
    iconName: 'medal',
    condition: 'Completa 30 sesiones',
    points: 100,
  ),
  AchievementEntity(
    id: 'month_master',
    title: 'Maestro del Mes',
    description: 'Mantuviste una racha de 30 días',
    iconName: 'trophy',
    condition: '30 días seguidos de actividad',
    points: 200,
  ),
];

AchievementEntity? findAchievementById(String id) {
  for (final a in achievementCatalog) {
    if (a.id == id) return a;
  }
  return null;
}
