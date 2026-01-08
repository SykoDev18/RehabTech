import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rehabtech/services/progress_service.dart';
import 'package:rehabtech/services/notification_service.dart';
import 'package:rehabtech/services/analytics_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _dailyReminder = true;
  bool _weeklyProgress = true;
  bool _achievements = true;
  bool _therapistMessages = true;
  bool _appUpdates = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isLoading = true;
  
  final ProgressService _progressService = ProgressService();
  final NotificationService _notificationService = NotificationService();
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    // Cargar preferencias de notificaciones reales
    final notifPrefs = await _notificationService.getReminderSettings();
    
    // Cargar configuraciones guardadas localmente
    final daily = _progressService.getSetting('notif_daily');
    final weekly = _progressService.getSetting('notif_weekly');
    final achieve = _progressService.getSetting('notif_achievements');
    final therapist = _progressService.getSetting('notif_therapist');
    final updates = _progressService.getSetting('notif_updates');
    
    setState(() {
      // Preferencias del NotificationService tienen prioridad
      _dailyReminder = notifPrefs['enabled'] ?? 
          (daily != null ? daily == 1.0 : true);
      _reminderTime = TimeOfDay(
        hour: notifPrefs['hour'] ?? 9,
        minute: notifPrefs['minute'] ?? 0,
      );
      _therapistMessages = notifPrefs['therapistMessages'] ?? 
          (therapist != null ? therapist == 1.0 : true);
      
      // Preferencias locales
      if (weekly != null) _weeklyProgress = weekly == 1.0;
      if (achieve != null) _achievements = achieve == 1.0;
      if (updates != null) _appUpdates = updates == 1.0;
      
      _isLoading = false;
    });
  }
  
  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (time != null) {
      setState(() => _reminderTime = time);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[50]!,
              Colors.green[50]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(LucideIcons.arrowLeft, size: 22),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Notificaciones',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Recordatorios
                      _buildSectionTitle('Recordatorios'),
                      const SizedBox(height: 12),
                      _buildNotificationCard([
                        _buildNotificationTile(
                          icon: LucideIcons.alarmClock,
                          title: 'Recordatorio Diario',
                          subtitle: 'Recibe un recordatorio para hacer tus ejercicios',
                          value: _dailyReminder,
                          onChanged: (v) => setState(() => _dailyReminder = v),
                        ),
                        if (_dailyReminder) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Divider(color: Colors.grey.withValues(alpha: 0.2)),
                          ),
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                LucideIcons.clock,
                                color: Color(0xFF3B82F6),
                                size: 22,
                              ),
                            ),
                            title: const Text(
                              'Hora del recordatorio',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                              ),
                            ),
                            subtitle: Text(
                              _reminderTime.format(context),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            trailing: TextButton(
                              onPressed: _selectTime,
                              child: const Text('Cambiar'),
                            ),
                          ),
                        ],
                      ]),
                      
                      const SizedBox(height: 24),
                      
                      // Progreso
                      _buildSectionTitle('Progreso'),
                      const SizedBox(height: 12),
                      _buildNotificationCard([
                        _buildNotificationTile(
                          icon: LucideIcons.chartBar,
                          title: 'Resumen Semanal',
                          subtitle: 'Recibe un resumen de tu progreso cada semana',
                          value: _weeklyProgress,
                          onChanged: (v) => setState(() => _weeklyProgress = v),
                        ),
                        _buildNotificationTile(
                          icon: LucideIcons.trophy,
                          title: 'Logros',
                          subtitle: 'Notificaciones cuando alcances nuevas metas',
                          value: _achievements,
                          onChanged: (v) => setState(() => _achievements = v),
                        ),
                      ]),
                      
                      const SizedBox(height: 24),
                      
                      // Comunicación
                      _buildSectionTitle('Comunicación'),
                      const SizedBox(height: 12),
                      _buildNotificationCard([
                        _buildNotificationTile(
                          icon: LucideIcons.messageSquare,
                          title: 'Mensajes del Terapeuta',
                          subtitle: 'Notificaciones de mensajes de tu terapeuta',
                          value: _therapistMessages,
                          onChanged: (v) => setState(() => _therapistMessages = v),
                        ),
                        _buildNotificationTile(
                          icon: LucideIcons.sparkles,
                          title: 'Actualizaciones de la App',
                          subtitle: 'Nuevas funciones y mejoras',
                          value: _appUpdates,
                          onChanged: (v) => setState(() => _appUpdates = v),
                        ),
                      ]),
                      
                      const SizedBox(height: 32),
                      
                      // Botón guardar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Guardar Configuración',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
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
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF6B7280),
      ),
    );
  }
  
  Widget _buildNotificationCard(List<Widget> children) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: children.asMap().entries.map((entry) {
              final index = entry.key;
              final child = entry.value;
              return Column(
                children: [
                  child,
                  if (index < children.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(
                        height: 1,
                        color: Colors.grey.withValues(alpha: 0.2),
                      ),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
  
  Widget _buildNotificationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF3B82F6), size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF111827),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeTrackColor: const Color(0xFF3B82F6).withAlpha(128),
        activeThumbColor: const Color(0xFF3B82F6),
      ),
    );
  }
  
  void _saveSettings() async {
    setState(() => _isLoading = true);
    
    try {
      // Guardar preferencias locales
      await _progressService.saveSetting('notif_daily', _dailyReminder ? 1.0 : 0.0);
      await _progressService.saveSetting('notif_weekly', _weeklyProgress ? 1.0 : 0.0);
      await _progressService.saveSetting('notif_achievements', _achievements ? 1.0 : 0.0);
      await _progressService.saveSetting('notif_therapist', _therapistMessages ? 1.0 : 0.0);
      await _progressService.saveSetting('notif_updates', _appUpdates ? 1.0 : 0.0);
      
      // Configurar recordatorio diario real
      if (_dailyReminder) {
        await _notificationService.scheduleDailyReminder(
          hour: _reminderTime.hour,
          minute: _reminderTime.minute,
        );
      } else {
        await _notificationService.cancelDailyReminder();
      }
      
      // Guardar preferencia de mensajes del terapeuta
      await _notificationService.setTherapistMessagesEnabled(_therapistMessages);
      
      // Track analytics
      AnalyticsService().logEvent(
        name: 'notification_settings_changed',
        parameters: {
          'daily_reminder': _dailyReminder,
          'reminder_time': '${_reminderTime.hour}:${_reminderTime.minute}',
          'therapist_messages': _therapistMessages,
        },
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.check, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(_dailyReminder 
                  ? 'Recordatorio configurado a las ${_reminderTime.format(context)}'
                  : 'Configuración guardada'),
            ],
          ),
          backgroundColor: const Color(0xFF22C55E),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
