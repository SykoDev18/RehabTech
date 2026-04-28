// One-shot seed script. Run with:
//   flutter run -t lib/data/seeds/run_seed.dart
// Writes one document per entry in [exerciseSeeds] under collection
// `routines`, keyed by `id`. Idempotent — re-running overwrites with merge.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

import '../../firebase_options.dart';
import 'exercise_seeds.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final fs = FirebaseFirestore.instance;
  final batch = fs.batch();
  for (final seed in exerciseSeeds) {
    final id = seed['id'] as String;
    batch.set(
      fs.collection('routines').doc(id),
      seed,
      SetOptions(merge: true),
    );
  }
  await batch.commit();
  debugPrint('Seeded ${exerciseSeeds.length} exercises into routines/.');
}
