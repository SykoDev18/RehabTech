/// Firestore seed data for the rehab exercise catalog.
///
/// Each entry is a `routines` document. Run via
/// `flutter run -t lib/data/seeds/run_seed.dart` from a debug build.
///
/// Schema:
///   id              — stable identifier; matches ExerciseCatalog factory keys.
///   name            — display name (es-MX).
///   group           — A/B/C/D/E (Knee/Shoulder/Hip/Balance/Neck).
///   reps            — null for timed-hold exercises.
///   sets            — number of sets.
///   durationSeconds — null for rep-based exercises.
///   targetMuscles   — array of muscle names (es-MX).
///   difficulty      — principiante | intermedio | avanzado.
///   instructions    — short bullet list (es-MX).
///   analyzerId      — id used by ExerciseCatalog.createById(); null for self-report.
const List<Map<String, Object?>> exerciseSeeds = [
  // ===== GROUP A — KNEE REHAB =====
  {
    'id': 'knee_extension',
    'name': 'Extensión de rodilla',
    'group': 'A',
    'reps': 15,
    'sets': 3,
    'durationSeconds': null,
    'targetMuscles': ['cuádriceps'],
    'difficulty': 'principiante',
    'instructions': [
      'Siéntate en una silla con la espalda recta.',
      'Extiende la pierna hasta tenerla totalmente recta.',
      'Mantén 2 segundos y baja lentamente.',
    ],
    'analyzerId': 'knee_extension',
  },
  {
    'id': 'hamstring_curl',
    'name': 'Curl de isquiotibiales',
    'group': 'A',
    'reps': 12,
    'sets': 3,
    'durationSeconds': null,
    'targetMuscles': ['isquiotibiales'],
    'difficulty': 'intermedio',
    'instructions': [
      'De pie, sujétate de una silla.',
      'Dobla la rodilla llevando el talón al glúteo.',
      'Mantén la cadera quieta durante el movimiento.',
    ],
    'analyzerId': 'hamstring_curl',
  },
  {
    'id': 'wall_squat',
    'name': 'Sentadilla en pared',
    'group': 'A',
    'reps': null,
    'sets': 3,
    'durationSeconds': 30,
    'targetMuscles': ['cuádriceps', 'glúteos'],
    'difficulty': 'intermedio',
    'instructions': [
      'Apóyate de espaldas contra una pared.',
      'Baja hasta que rodillas y caderas formen 90°.',
      'Mantén la posición sin que las rodillas pasen los pies.',
    ],
    'analyzerId': 'wall_squat',
  },
  {
    'id': 'straight_leg_raise',
    'name': 'Elevación de pierna recta',
    'group': 'A',
    'reps': 15,
    'sets': 3,
    'durationSeconds': null,
    'targetMuscles': ['cuádriceps', 'flexores de cadera'],
    'difficulty': 'principiante',
    'instructions': [
      'Acuéstate boca arriba con una pierna flexionada.',
      'Mantén la otra pierna recta y elévala 45°-60°.',
      'Baja con control sin tocar el suelo.',
    ],
    'analyzerId': 'straight_leg_raise',
  },
  // ===== GROUP B — SHOULDER REHAB =====
  {
    'id': 'shoulder_flexion',
    'name': 'Flexión de hombro',
    'group': 'B',
    'reps': 10,
    'sets': 3,
    'durationSeconds': null,
    'targetMuscles': ['deltoides anterior', 'pectoral'],
    'difficulty': 'principiante',
    'instructions': [
      'De pie con los brazos al costado.',
      'Eleva el brazo recto al frente hasta donde puedas.',
      'Mantén el tronco recto y baja con control.',
    ],
    'analyzerId': 'shoulder_flexion',
  },
  {
    'id': 'shoulder_abduction',
    'name': 'Abducción de hombro',
    'group': 'B',
    'reps': 10,
    'sets': 3,
    'durationSeconds': null,
    'targetMuscles': ['deltoides', 'supraespinoso'],
    'difficulty': 'principiante',
    'instructions': [
      'De pie con los brazos al costado.',
      'Eleva el brazo lateralmente hasta la altura del hombro.',
      'Mantén el codo casi recto durante el movimiento.',
    ],
    'analyzerId': 'shoulder_abduction',
  },
  {
    'id': 'pendulum',
    'name': 'Péndulo de Codman',
    'group': 'B',
    'reps': null,
    'sets': 1,
    'durationSeconds': 60,
    'targetMuscles': ['manguito rotador'],
    'difficulty': 'principiante',
    'instructions': [
      'Inclínate apoyando una mano sobre una mesa.',
      'Deja que el otro brazo cuelgue relajado.',
      'Hazlo girar en círculos pequeños sin esfuerzo.',
    ],
    'analyzerId': 'pendulum',
  },
  // ===== GROUP C — HIP & GLUTE =====
  {
    'id': 'glute_bridge',
    'name': 'Puente de glúteos',
    'group': 'C',
    'reps': 15,
    'sets': 3,
    'durationSeconds': null,
    'targetMuscles': ['glúteos', 'isquiotibiales', 'core'],
    'difficulty': 'principiante',
    'instructions': [
      'Acuéstate boca arriba con rodillas flexionadas.',
      'Aprieta los glúteos y eleva la cadera.',
      'Mantén 2 segundos arriba y baja lentamente.',
    ],
    'analyzerId': 'glute_bridge',
  },
  {
    'id': 'clamshell',
    'name': 'Apertura de cadera (almeja)',
    'group': 'C',
    'reps': 15,
    'sets': 3,
    'durationSeconds': null,
    'targetMuscles': ['glúteo medio', 'rotadores externos de cadera'],
    'difficulty': 'principiante',
    'instructions': [
      'Acuéstate de lado con rodillas y caderas flexionadas.',
      'Mantén los pies juntos y abre la rodilla superior.',
      'No dejes que la cadera ruede atrás.',
    ],
    'analyzerId': 'clamshell',
  },
  // ===== GROUP D — BALANCE =====
  {
    'id': 'single_leg_stance',
    'name': 'Equilibrio en una pierna',
    'group': 'D',
    'reps': null,
    'sets': 3,
    'durationSeconds': 30,
    'targetMuscles': ['tobillo', 'core', 'equilibrio'],
    'difficulty': 'intermedio',
    'instructions': [
      'De pie, levanta una pierna del suelo.',
      'Encuentra un punto fijo para mirar.',
      'Mantén el equilibrio sin agarrarte de nada.',
    ],
    'analyzerId': 'single_leg_stance',
  },
  {
    'id': 'heel_raise',
    'name': 'Elevación de talones',
    'group': 'D',
    'reps': 20,
    'sets': 3,
    'durationSeconds': null,
    'targetMuscles': ['gemelos', 'sóleo'],
    'difficulty': 'principiante',
    'instructions': [
      'De pie con los pies separados al ancho de cadera.',
      'Eleva los talones quedando en puntillas.',
      'Baja con control sin tocar el suelo de golpe.',
    ],
    'analyzerId': 'heel_raise',
  },
  // ===== GROUP E — CERVICAL (timer + self-report, no analyzer) =====
  {
    'id': 'neck_flex_ext',
    'name': 'Flexión y extensión de cuello',
    'group': 'E',
    'reps': 10,
    'sets': 2,
    'durationSeconds': null,
    'targetMuscles': ['flexores cervicales', 'extensores cervicales'],
    'difficulty': 'principiante',
    'instructions': [
      'Lleva la barbilla al pecho 3 segundos.',
      'Mira al techo con cuidado 3 segundos.',
      'Repite el ciclo sin forzar el cuello.',
    ],
    'analyzerId': null,
  },
  {
    'id': 'neck_lateral_flex',
    'name': 'Inclinación lateral de cuello',
    'group': 'E',
    'reps': 10,
    'sets': 2,
    'durationSeconds': null,
    'targetMuscles': ['escalenos', 'esternocleidomastoideo'],
    'difficulty': 'principiante',
    'instructions': [
      'Lleva la oreja al hombro derecho 3 segundos.',
      'Vuelve al centro y repite al lado izquierdo.',
      'No subas el hombro al inclinar la cabeza.',
    ],
    'analyzerId': null,
  },
];
