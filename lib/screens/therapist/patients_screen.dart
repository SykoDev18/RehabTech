import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/patient_entity.dart';
import 'patient_detail_screen.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: _buildHeader(),
        ),
        // Search bar
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          sliver: SliverToBoxAdapter(
            child: _buildSearchBar(),
          ),
        ),
        // Patients list
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
          sliver: _buildPatientsList(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Pacientes',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          GestureDetector(
            onTap: _showAddPatientModal,
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

  Widget _buildSearchBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Buscar paciente...',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
          prefixIcon: Icon(LucideIcons.search, color: Colors.grey[400], size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildPatientsList() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const SliverToBoxAdapter(
        child: Center(child: Text('No autenticado')),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('therapistId', isEqualTo: userId)
          .where('userType', isEqualTo: 'patient')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SliverToBoxAdapter(
            child: _buildEmptyState(),
          );
        }

        final patients = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return PatientEntity(
            id: doc.id,
            name: data['name'] ?? '',
            lastName: data['lastName'] ?? '',
            email: data['email'] ?? '',
            phone: data['phone'],
            condition: data['condition'] ?? 'Sin diagnóstico',
            age: data['age'],
            status: data['patientStatus'] ?? 'in_progress',
            therapistId: userId,
            patientId: data['patientId'],
            progressPercentage: (data['progressPercentage'] ?? 0).toDouble(),
            completedSessions: data['completedSessions'] ?? 0,
            totalSessions: data['totalSessions'] ?? 0,
            pendingQuestions: data['pendingQuestions'] ?? 0,
            notes: data['therapistNotes'],
            createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            lastSessionAt: (data['lastSessionAt'] as Timestamp?)?.toDate(),
          );
        }).toList();

        // Filter by search (including patientId)
        final filteredPatients = patients.where((p) =>
            p.fullName.toLowerCase().contains(_searchQuery) ||
            p.condition.toLowerCase().contains(_searchQuery) ||
            (p.patientId?.toLowerCase().contains(_searchQuery) ?? false)).toList();

        if (filteredPatients.isEmpty) {
          return SliverToBoxAdapter(
            child: _buildEmptyState(isFiltered: true),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final patient = filteredPatients[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildPatientCard(patient),
              );
            },
            childCount: filteredPatients.length,
          ),
        );
      },
    );
  }

  Widget _buildPatientCard(PatientEntity patient) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PatientDetailScreen(patient: patient),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Text(
                  patient.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF111827),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    patient.condition,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: patient.needsAttention
                    ? const Color(0xFFF97316)
                    : const Color(0xFF22C55E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                patient.statusLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({bool isFiltered = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFiltered ? LucideIcons.searchX : LucideIcons.users,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isFiltered
                  ? 'No se encontraron pacientes'
                  : 'Sin pacientes aún',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'Intenta con otro término de búsqueda'
                  : 'Agrega tu primer paciente',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPatientModal() {
    final patientIdController = TextEditingController();
    bool isSearching = false;
    String? searchError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFDBEAFE),
                Color(0xFFF0FDF4),
                Color(0xFFEFF6FF),
              ],
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Agregar Paciente',
                      style: TextStyle(
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
                const SizedBox(height: 24),
                // Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.info, color: Color(0xFF3B82F6), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Solicita el ID de paciente a tu paciente. Lo encuentra en su perfil de la app.',
                          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Patient ID input
                const Text(
                  'ID del Paciente',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: patientIdController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Ej: ABC12345',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(LucideIcons.hash, color: Color(0xFF3B82F6)),
                    errorText: searchError,
                  ),
                ),
                const SizedBox(height: 24),
                // Search button
                GestureDetector(
                  onTap: isSearching ? null : () async {
                    final patientId = patientIdController.text.trim().toUpperCase();
                    if (patientId.isEmpty) {
                      setModalState(() => searchError = 'Ingresa un ID de paciente');
                      return;
                    }

                    setModalState(() {
                      isSearching = true;
                      searchError = null;
                    });

                    try {
                      // Search for patient by patientId
                      final query = await FirebaseFirestore.instance
                          .collection('users')
                          .where('patientId', isEqualTo: patientId)
                          .where('userType', isEqualTo: 'patient')
                          .limit(1)
                          .get();

                      if (query.docs.isEmpty) {
                        setModalState(() {
                          searchError = 'No se encontró un paciente con ese ID';
                          isSearching = false;
                        });
                        return;
                      }

                      final patientDoc = query.docs.first;
                      final patientData = patientDoc.data();
                      final userId = FirebaseAuth.instance.currentUser?.uid;

                      // Check if already linked
                      if (patientData['therapistId'] == userId) {
                        setModalState(() {
                          searchError = 'Este paciente ya está en tu lista';
                          isSearching = false;
                        });
                        return;
                      }

                      // Link patient to therapist
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(patientDoc.id)
                          .update({'therapistId': userId});

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${patientData['name']} agregado como paciente'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      setModalState(() {
                        searchError = 'Error al buscar paciente';
                        isSearching = false;
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: isSearching
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.search, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Buscar y Agregar',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddPatientManualModal() {
    final nameController = TextEditingController();
    final conditionController = TextEditingController();
    final ageController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFDBEAFE),
              Color(0xFFF0FDF4),
              Color(0xFFEFF6FF),
            ],
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
                  const Text(
                    'Nuevo Paciente',
                    style: TextStyle(
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
                  children: [
                    _buildFormField(
                      label: 'Nombre completo',
                      hint: 'Ej: Juan Pérez García',
                      controller: nameController,
                    ),
                    const SizedBox(height: 16),
                    _buildFormField(
                      label: 'Condición o diagnóstico',
                      hint: 'Ej: Lesión de rodilla',
                      controller: conditionController,
                    ),
                    const SizedBox(height: 16),
                    _buildFormField(
                      label: 'Edad',
                      hint: 'Ej: 35',
                      controller: ageController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildFormField(
                      label: 'Teléfono',
                      hint: 'Ej: +52 55 1234 5678',
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    _buildFormField(
                      label: 'Email',
                      hint: 'Ej: ejemplo@email.com',
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 32),
                    // Submit button
                    GestureDetector(
                      onTap: () => _addPatient(
                        context,
                        nameController.text,
                        conditionController.text,
                        ageController.text,
                        phoneController.text,
                        emailController.text,
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
                              color: const Color(0xFF3B82F6).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Agregar Paciente',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addPatient(
    BuildContext context,
    String name,
    String condition,
    String age,
    String phone,
    String email,
  ) async {
    if (name.isEmpty || condition.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa nombre y condición')),
      );
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      // Split name into parts
      final nameParts = name.trim().split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts[0] : '';
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      await FirebaseFirestore.instance.collection('users').add({
        'name': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'condition': condition,
        'age': int.tryParse(age),
        'userType': 'patient',
        'therapistId': userId,
        'patientStatus': 'in_progress',
        'progressPercentage': 0,
        'completedSessions': 0,
        'totalSessions': 0,
        'pendingQuestions': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paciente agregado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al agregar paciente: $e')),
        );
      }
    }
  }
}
