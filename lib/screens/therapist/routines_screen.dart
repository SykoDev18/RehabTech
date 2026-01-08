import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/exercise.dart';

class RoutinesScreen extends StatefulWidget {
  const RoutinesScreen({super.key});

  @override
  State<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends State<RoutinesScreen> {
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: _buildHeader(),
        ),
        // Routines list
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
          sliver: _buildRoutinesList(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Rutinas',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          GestureDetector(
            onTap: _showNewRoutineModal,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                LucideIcons.plus,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutinesList() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const SliverToBoxAdapter(
        child: Center(child: Text('No autenticado')),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('routines')
          .where('therapistId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, routinesSnapshot) {
        if (routinesSnapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!routinesSnapshot.hasData || routinesSnapshot.data!.docs.isEmpty) {
          return SliverToBoxAdapter(
            child: _buildEmptyState(),
          );
        }

        // Group routines by patient
        final routinesByPatient = <String, List<Map<String, dynamic>>>{};
        for (final doc in routinesSnapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final patientId = data['patientId'] as String? ?? '';
          routinesByPatient.putIfAbsent(patientId, () => []);
          routinesByPatient[patientId]!.add({...data, 'id': doc.id});
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final patientId = routinesByPatient.keys.elementAt(index);
              final routines = routinesByPatient[patientId]!;
              return _buildPatientRoutineCard(patientId, routines);
            },
            childCount: routinesByPatient.length,
          ),
        );
      },
    );
  }

  Widget _buildPatientRoutineCard(String patientId, List<Map<String, dynamic>> routines) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(patientId).get(),
      builder: (context, patientSnapshot) {
        String patientName = 'Paciente';
        String patientCondition = '';
        String initials = 'P';

        if (patientSnapshot.hasData && patientSnapshot.data!.exists) {
          final data = patientSnapshot.data!.data() as Map<String, dynamic>;
          final name = data['name'] ?? '';
          final lastName = data['lastName'] ?? '';
          patientName = '$name $lastName'.trim();
          patientCondition = data['condition'] ?? '';
          initials = _getInitials(patientName);
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Patient header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFEFF6FF),
                      const Color(0xFFE0E7FF).withValues(alpha: 0.5),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patientName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: Color(0xFF111827),
                            ),
                          ),
                          if (patientCondition.isNotEmpty)
                            Text(
                              patientCondition,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Icon(LucideIcons.dumbbell, color: Colors.blue[400], size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${routines.length} rutina${routines.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Routines
              ...routines.map((routine) => _buildRoutineItem(routine)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoutineItem(Map<String, dynamic> routine) {
    final exercises = (routine['exercises'] as List<dynamic>?) ?? [];
    final createdAt = (routine['createdAt'] as Timestamp?)?.toDate();
    final dateStr = createdAt != null
        ? DateFormat('dd MMM yyyy', 'es_ES').format(createdAt)
        : '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Routine header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(LucideIcons.activity, color: Colors.blue[600], size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routine['name'] ?? 'Rutina de Rehabilitación',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Color(0xFF111827),
                      ),
                    ),
                    if (dateStr.isNotEmpty)
                      Text(
                        'Creada: $dateStr',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),
              ),
              // Actions
              GestureDetector(
                onTap: () => _showEditRoutineModal(routine),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(LucideIcons.pencil, color: Colors.blue[500], size: 18),
                ),
              ),
              GestureDetector(
                onTap: () => _deleteRoutine(routine['id']),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: const Icon(LucideIcons.trash2, color: Color(0xFFEF4444), size: 18),
                ),
              ),
            ],
          ),
          // Exercises count
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              '${exercises.length} ejercicios',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Exercises list
          ...exercises.asMap().entries.map((entry) {
            final index = entry.key;
            final exercise = entry.value as Map<String, dynamic>;
            return _buildExerciseRow(index + 1, exercise);
          }),
        ],
      ),
    );
  }

  Widget _buildExerciseRow(int number, Map<String, dynamic> exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey[50]!,
            Colors.blue[50]!.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(LucideIcons.play, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$number. ${exercise['name'] ?? 'Ejercicio'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.blue[500],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${exercise['series'] ?? 3} series',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.green[500],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${exercise['reps'] ?? 10} reps',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.dumbbell, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Sin rutinas aún',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu primera rutina de ejercicios',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name.substring(0, name.length >= 3 ? 3 : name.length).toUpperCase() : 'P';
  }

  void _showNewRoutineModal() {
    _showRoutineModal(isEdit: false);
  }

  void _showEditRoutineModal(Map<String, dynamic> routine) {
    _showRoutineModal(isEdit: true, routine: routine);
  }

  void _showRoutineModal({required bool isEdit, Map<String, dynamic>? routine}) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    String? selectedPatientId = routine?['patientId'];
    final nameController = TextEditingController(text: routine?['name'] ?? 'Rutina de Rehabilitación');
    List<Map<String, dynamic>> exercises = [];

    if (routine != null && routine['exercises'] != null) {
      exercises = List<Map<String, dynamic>>.from(
        (routine['exercises'] as List).map((e) => Map<String, dynamic>.from(e)),
      );
    }

    // Controllers for new exercise
    final exerciseNameController = TextEditingController();
    final videoUrlController = TextEditingController();
    final seriesController = TextEditingController(text: '3');
    final repsController = TextEditingController(text: '10');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFDBEAFE), Color(0xFFF0FDF4), Color(0xFFEFF6FF)],
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? 'Editar Rutina' : 'Nueva Rutina',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(LucideIcons.x, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Patient selector
                      _buildPatientSelector(
                        userId: userId,
                        selectedPatientId: selectedPatientId,
                        onChanged: (id) => setModalState(() => selectedPatientId = id),
                      ),
                      const SizedBox(height: 24),
                      // Add exercise section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Agregar Ejercicio',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _showPredefinedExercises(
                                    context,
                                    setModalState,
                                    exercises,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(LucideIcons.listChecks, size: 14, color: Color(0xFF3B82F6)),
                                        SizedBox(width: 4),
                                        Text(
                                          'Predeterminados',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF3B82F6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: exerciseNameController,
                              decoration: InputDecoration(
                                hintText: 'Nombre del ejercicio',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: videoUrlController,
                              decoration: InputDecoration(
                                hintText: 'URL del video',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Series', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                      const SizedBox(height: 4),
                                      TextField(
                                        controller: seriesController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide.none,
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[100],
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Repeticiones', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                      const SizedBox(height: 4),
                                      TextField(
                                        controller: repsController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide.none,
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[100],
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () {
                                if (exerciseNameController.text.isNotEmpty) {
                                  setModalState(() {
                                    exercises.add({
                                      'name': exerciseNameController.text,
                                      'videoUrl': videoUrlController.text,
                                      'series': int.tryParse(seriesController.text) ?? 3,
                                      'reps': int.tryParse(repsController.text) ?? 10,
                                    });
                                    exerciseNameController.clear();
                                    videoUrlController.clear();
                                    seriesController.text = '3';
                                    repsController.text = '10';
                                  });
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF97316),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Text(
                                    '+ Agregar Ejercicio',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Added exercises
                      if (exercises.isNotEmpty) ...[
                        Text(
                          'Ejercicios Agregados (${exercises.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...exercises.asMap().entries.map((entry) {
                          final index = entry.key;
                          final ex = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(LucideIcons.play, color: Color(0xFF3B82F6), size: 16),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ex['name'],
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                      Text(
                                        '${ex['series']} series × ${ex['reps']} repeticiones',
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => setModalState(() => exercises.removeAt(index)),
                                  child: const Icon(LucideIcons.trash2, color: Color(0xFFEF4444), size: 18),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              // Submit button
              Container(
                padding: const EdgeInsets.all(24),
                child: GestureDetector(
                  onTap: () => _saveRoutine(
                    context,
                    isEdit: isEdit,
                    routineId: routine?['id'],
                    patientId: selectedPatientId,
                    name: nameController.text,
                    exercises: exercises,
                  ),
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        isEdit ? 'Actualizar Rutina' : 'Guardar Rutina',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientSelector({
    required String userId,
    String? selectedPatientId,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seleccionar Paciente',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('therapistId', isEqualTo: userId)
                .where('userType', isEqualTo: 'patient')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }

              final patients = snapshot.data!.docs;

              return DropdownButtonFormField<String>(
                initialValue: selectedPatientId,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                hint: const Text('Seleccionar paciente...'),
                items: patients.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = '${data['name'] ?? ''} ${data['lastName'] ?? ''}'.trim();
                  return DropdownMenuItem(
                    value: doc.id,
                    child: Text(name),
                  );
                }).toList(),
                onChanged: onChanged,
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveRoutine(
    BuildContext context, {
    required bool isEdit,
    String? routineId,
    String? patientId,
    required String name,
    required List<Map<String, dynamic>> exercises,
  }) async {
    if (patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona un paciente')),
      );
      return;
    }

    if (exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor agrega al menos un ejercicio')),
      );
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final data = {
        'name': name,
        'patientId': patientId,
        'therapistId': userId,
        'exercises': exercises,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (isEdit && routineId != null) {
        await FirebaseFirestore.instance.collection('routines').doc(routineId).update(data);
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('routines').add(data);
      }

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Rutina actualizada' : 'Rutina creada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteRoutine(String routineId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Rutina'),
        content: const Text('¿Estás seguro de que deseas eliminar esta rutina?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('routines').doc(routineId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rutina eliminada'), backgroundColor: Colors.green),
        );
      }
    }
  }

  void _showPredefinedExercises(
    BuildContext context,
    void Function(void Function()) setModalState,
    List<Map<String, dynamic>> exercises,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ejercicios Predeterminados',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(LucideIcons.x, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              // List of exercises
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: allExercises.length,
                  itemBuilder: (context, index) {
                    final exercise = allExercises[index];
                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
                          exercises.add({
                            'name': exercise.title,
                            'videoUrl': '',
                            'series': exercise.series,
                            'reps': exercise.reps,
                          });
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${exercise.title} agregado'),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: exercise.iconBgColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                exercise.icon,
                                color: exercise.iconColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exercise.title,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${exercise.series} series × ${exercise.reps} reps • ${exercise.difficulty}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                LucideIcons.plus,
                                color: Color(0xFF3B82F6),
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
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
}
