import '../pose_analysis/exercise_analyzer.dart';
import 'analyzers/clamshell_analyzer.dart';
import 'analyzers/glute_bridge_analyzer.dart';
import 'analyzers/hamstring_curl_analyzer.dart';
import 'analyzers/heel_raise_analyzer.dart';
import 'analyzers/knee_extension_analyzer.dart';
import 'analyzers/pendulum_analyzer.dart';
import 'analyzers/shoulder_abduction_analyzer.dart';
import 'analyzers/shoulder_flexion_analyzer.dart';
import 'analyzers/single_leg_stance_analyzer.dart';
import 'analyzers/straight_leg_raise_analyzer.dart';
import 'analyzers/wall_squat_analyzer.dart';

typedef AnalyzerFactory = ExerciseAnalyzer Function();

/// Maps `exerciseId` → analyzer factory. Used by the therapy session screen
/// when it knows the chosen exercise's id (typically from Firestore).
class ExerciseCatalog {
  ExerciseCatalog._();

  static final Map<String, AnalyzerFactory> _factories = {
    'knee_extension': KneeExtensionAnalyzer.new,
    'hamstring_curl': HamstringCurlAnalyzer.new,
    'wall_squat': WallSquatAnalyzer.new,
    'straight_leg_raise': StraightLegRaiseAnalyzer.new,
    'shoulder_flexion': ShoulderFlexionAnalyzer.new,
    'shoulder_abduction': ShoulderAbductionAnalyzer.new,
    'pendulum': PendulumAnalyzer.new,
    'glute_bridge': GluteBridgeAnalyzer.new,
    'clamshell': ClamshellAnalyzer.new,
    'single_leg_stance': SingleLegStanceAnalyzer.new,
    'heel_raise': HeelRaiseAnalyzer.new,
    // Neck exercises (neck_flex_ext, neck_lateral_flex) are timer + self-report
    // and intentionally have no analyzer.
  };

  static ExerciseAnalyzer? createById(String id) => _factories[id]?.call();

  static Iterable<String> get supportedIds => _factories.keys;
}
