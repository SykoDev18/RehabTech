import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _selectedMonth;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    _selectedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: _buildHeader(),
        ),
        // Calendar
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          sliver: SliverToBoxAdapter(
            child: _buildCalendar(),
          ),
        ),
        // Upcoming appointments
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          sliver: SliverToBoxAdapter(
            child: const Text(
              'Próximas Citas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
          sliver: _buildAppointmentsList(),
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
            'Calendario',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          GestureDetector(
            onTap: _showNewAppointmentModal,
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

  Widget _buildCalendar() {
    final now = DateTime.now();
    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final startWeekday = firstDayOfMonth.weekday; // 1 = Monday

    return Container(
      padding: const EdgeInsets.all(16),
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
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => setState(() {
                  _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                }),
                child: const Icon(LucideIcons.chevronLeft, color: Color(0xFF6B7280)),
              ),
              Text(
                _getMonthName(_selectedMonth),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() {
                  _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                }),
                child: const Icon(LucideIcons.chevronRight, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Weekday headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['L', 'M', 'M', 'J', 'V', 'S', 'D']
                .map((day) => SizedBox(
                      width: 36,
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          // Calendar grid
          _buildCalendarGrid(now, daysInMonth, startWeekday),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(DateTime now, int daysInMonth, int startWeekday) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    
    return StreamBuilder<QuerySnapshot>(
      stream: userId != null
          ? FirebaseFirestore.instance
              .collection('appointments')
              .where('therapistId', isEqualTo: userId)
              .snapshots()
          : null,
      builder: (context, snapshot) {
        // Get days with appointments
        final appointmentDays = <int>{};
        if (snapshot.hasData) {
          for (final doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final dateTime = (data['dateTime'] as Timestamp?)?.toDate();
            if (dateTime != null &&
                dateTime.year == _selectedMonth.year &&
                dateTime.month == _selectedMonth.month) {
              appointmentDays.add(dateTime.day);
            }
          }
        }

        final rows = <Widget>[];
        var dayCounter = 1;

        for (var week = 0; week < 6; week++) {
          if (dayCounter > daysInMonth) break;

          final weekDays = <Widget>[];
          for (var weekday = 1; weekday <= 7; weekday++) {
            if ((week == 0 && weekday < startWeekday) || dayCounter > daysInMonth) {
              weekDays.add(const SizedBox(width: 36, height: 36));
            } else {
              final day = dayCounter;
              final isToday = day == now.day &&
                  _selectedMonth.month == now.month &&
                  _selectedMonth.year == now.year;
              final hasAppointment = appointmentDays.contains(day);
              final isSelected = _selectedDay?.day == day &&
                  _selectedDay?.month == _selectedMonth.month &&
                  _selectedDay?.year == _selectedMonth.year;

              weekDays.add(
                GestureDetector(
                  onTap: () => setState(() {
                    _selectedDay = DateTime(_selectedMonth.year, _selectedMonth.month, day);
                  }),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isToday
                          ? const Color(0xFF3B82F6)
                          : hasAppointment
                              ? const Color(0xFFF97316).withValues(alpha: 0.2)
                              : isSelected
                                  ? Colors.blue[50]
                                  : null,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isToday || hasAppointment ? FontWeight.w600 : FontWeight.normal,
                          color: isToday
                              ? Colors.white
                              : hasAppointment
                                  ? const Color(0xFFF97316)
                                  : const Color(0xFF111827),
                        ),
                      ),
                    ),
                  ),
                ),
              );
              dayCounter++;
            }
          }

          rows.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: weekDays,
              ),
            ),
          );
        }

        return Column(children: rows);
      },
    );
  }

  Widget _buildAppointmentsList() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('therapistId', isEqualTo: userId)
          .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
          .orderBy('dateTime')
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(LucideIcons.calendar, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'Sin citas próximas',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return _buildAppointmentCard(data);
            },
            childCount: snapshot.data!.docs.length,
          ),
        );
      },
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final dateTime = (appointment['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now();
    final patientName = appointment['patientName'] ?? 'Paciente';
    final sessionType = appointment['sessionType'] ?? 'Sesión';
    final initials = _getInitials(patientName);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
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
                  fontSize: 14,
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
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  sessionType,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF3B82F6),
                ),
              ),
              Text(
                '${dateTime.day} ${_getMonthShort(dateTime.month)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getMonthName(DateTime date) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _getMonthShort(int month) {
    const months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return months[month - 1];
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name.substring(0, name.length >= 3 ? 3 : name.length).toUpperCase() : 'P';
  }

  void _showNewAppointmentModal() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    String? selectedPatientId;
    String? selectedPatientName;
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    final sessionTypeController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
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
                    const Text(
                      'Nueva Cita',
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Patient selector
                      _buildFieldLabel('Paciente'),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: StreamBuilder<QuerySnapshot>(
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
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              hint: const Text('Seleccionar paciente...'),
                              items: patients.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final name = '${data['name'] ?? ''} ${data['lastName'] ?? ''}'.trim();
                                return DropdownMenuItem(
                                  value: doc.id,
                                  child: Text(name),
                                  onTap: () => selectedPatientName = name,
                                );
                              }).toList(),
                              onChanged: (value) => setModalState(() {
                                selectedPatientId = value;
                              }),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Date picker
                      _buildFieldLabel('Fecha'),
                      GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setModalState(() => selectedDate = date);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(LucideIcons.calendar, color: Colors.grey[400], size: 20),
                              const SizedBox(width: 12),
                              Text(
                                selectedDate != null
                                    ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                                    : 'mm/dd/yyyy',
                                style: TextStyle(
                                  color: selectedDate != null ? const Color(0xFF111827) : Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Time picker
                      _buildFieldLabel('Hora'),
                      GestureDetector(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            setModalState(() => selectedTime = time);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(LucideIcons.clock, color: Colors.grey[400], size: 20),
                              const SizedBox(width: 12),
                              Text(
                                selectedTime != null
                                    ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                                    : '--:-- --',
                                style: TextStyle(
                                  color: selectedTime != null ? const Color(0xFF111827) : Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Session type
                      _buildFieldLabel('Tipo de sesión'),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TextField(
                          controller: sessionTypeController,
                          decoration: InputDecoration(
                            hintText: 'Ej: Evaluación, Fortalecimiento...',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Submit button
                      GestureDetector(
                        onTap: () => _createAppointment(
                          context,
                          patientId: selectedPatientId,
                          patientName: selectedPatientName,
                          date: selectedDate,
                          time: selectedTime,
                          sessionType: sessionTypeController.text,
                        ),
                        child: Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                            ),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: const Center(
                            child: Text(
                              'Agendar Cita',
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
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Future<void> _createAppointment(
    BuildContext context, {
    String? patientId,
    String? patientName,
    DateTime? date,
    TimeOfDay? time,
    required String sessionType,
  }) async {
    if (patientId == null || date == null || time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    try {
      await FirebaseFirestore.instance.collection('appointments').add({
        'patientId': patientId,
        'patientName': patientName ?? 'Paciente',
        'therapistId': userId,
        'dateTime': Timestamp.fromDate(dateTime),
        'sessionType': sessionType.isEmpty ? 'Sesión' : sessionType,
        'status': 'scheduled',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cita agendada exitosamente'),
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
}
