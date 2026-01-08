# Guía de Configuración Firebase Console

## Firebase Analytics

### Eventos Personalizados Implementados

| Evento | Descripción | Parámetros |
|--------|-------------|------------|
| `login` | Usuario inició sesión | `method` (email/google) |
| `sign_up` | Usuario se registró | `method` (email/google) |
| `logout` | Usuario cerró sesión | - |
| `exercise_started` | Inició un ejercicio | `exercise_id`, `exercise_name`, `category` |
| `exercise_completed` | Completó un ejercicio | `exercise_id`, `exercise_name`, `completed_reps`, `total_reps`, `duration_seconds`, `completion_percentage` |
| `exercise_abandoned` | Abandonó un ejercicio | `exercise_id`, `exercise_name`, `completed_reps`, `total_reps`, `duration_seconds` |
| `chat_message` | Envió mensaje a Nora | `is_user` |
| `ai_chat_started` | Inició conversación con IA | - |
| `patient_added` | Terapeuta agregó paciente | - |
| `routine_created` | Terapeuta creó rutina | `exercise_count` |
| `routine_assigned` | Terapeuta asignó rutina | `patient_id`, `routine_id` |
| `therapist_message_sent` | Terapeuta envió mensaje | - |
| `progress_viewed` | Usuario vio progreso | `period` |
| `report_generated` | Usuario generó PDF | `type` |
| `streak_achieved` | Usuario alcanzó racha | `days` |
| `pain_level_reported` | Usuario reportó dolor | `pain_level`, `exercise_id` |
| `notification_settings_changed` | Cambió configuración de notificaciones | `daily_reminder`, `reminder_time`, `therapist_messages` |

### Propiedades de Usuario

| Propiedad | Descripción | Valores |
|-----------|-------------|---------|
| `user_type` | Tipo de usuario | `patient` / `therapist` |
| `has_therapist` | Si tiene terapeuta asignado | `true` / `false` |

---

## Configurar Segmentos en Firebase Console

### 1. Acceder a Analytics → Audiencias

Ve a [Firebase Console](https://console.firebase.google.com) → Tu proyecto → Analytics → Audiencias

### 2. Segmentos Recomendados

#### Pacientes Activos
```
Condición: user_type = "patient"
AND evento "exercise_completed" en los últimos 7 días
```

#### Pacientes Inactivos (re-engagement)
```
Condición: user_type = "patient"
AND NO ha realizado evento "exercise_completed" en los últimos 14 días
```

#### Pacientes con Alta Adherencia
```
Condición: user_type = "patient"
AND evento "streak_achieved" donde days >= 7
```

#### Usuarios con Dolor
```
Condición: evento "pain_level_reported" donde pain_level >= 7
en los últimos 7 días
```

#### Terapeutas Activos
```
Condición: user_type = "therapist"
AND evento "routine_assigned" en los últimos 7 días
```

#### Usuarios de Chat IA
```
Condición: evento "chat_message" >= 5 veces
en los últimos 30 días
```

---

## Configurar Cloud Messaging (FCM)

### 1. Ir a Firebase Console → Messaging

### 2. Crear Campañas Push

#### Campaña: Recordatorio de Ejercicios
```yaml
Audiencia: Pacientes Inactivos
Título: ¡Te extrañamos! 💪
Mensaje: Han pasado unos días. ¿Retomamos tu rutina de rehabilitación?
Programación: Diaria a las 10:00 AM
Deep Link: rehabtech://main
```

#### Campaña: Motivación por Racha
```yaml
Audiencia: Pacientes Activos
Título: ¡Sigue así! 🔥
Mensaje: Llevas {streak_days} días seguidos. ¡No rompas tu racha!
Programación: Al cumplir 3, 7, 14, 30 días
Data: { "type": "streak_motivation" }
```

#### Campaña: Nuevo Mensaje del Terapeuta
```yaml
Audiencia: Por topic "patient"
Título: Mensaje de tu terapeuta 👨‍⚕️
Mensaje: {therapist_name} te ha enviado un mensaje
Deep Link: rehabtech://chat/therapist
```

### 3. Configurar Topics

Los topics se configuran automáticamente al registrarse:

| Topic | Descripción |
|-------|-------------|
| `patient` | Todos los pacientes |
| `therapist` | Todos los terapeutas |
| `all_users` | Todos los usuarios (avisos generales) |

### 4. Enviar Notificación por API (para terapeutas)

```javascript
// Desde Cloud Functions o servidor backend
const admin = require('firebase-admin');

await admin.messaging().send({
  topic: 'patient_' + patientId,  // Topic específico del paciente
  notification: {
    title: 'Nueva rutina asignada',
    body: 'Tu terapeuta te ha asignado una nueva rutina de ejercicios',
  },
  data: {
    type: 'new_routine',
    routineId: routineId,
  },
  android: {
    notification: {
      channelId: 'rehabtech_reminders',
      priority: 'high',
    },
  },
  apns: {
    payload: {
      aps: {
        sound: 'default',
        badge: 1,
      },
    },
  },
});
```

---

## Dashboards Recomendados

### Dashboard Principal
- Usuarios activos (DAU/MAU)
- Ejercicios completados por día
- Tasa de completación de ejercicios
- Usuarios por tipo (paciente/terapeuta)

### Dashboard de Engagement
- Mensajes con IA por usuario
- Tiempo promedio en sesión de ejercicio
- Rachas promedio
- Retención a 7/30 días

### Dashboard de Salud
- Niveles de dolor reportados
- Ejercicios abandonados vs completados
- Progreso por categoría de ejercicio

---

## Configuración Android

### Verificar en `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Permisos para notificaciones (Android 13+) -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

<!-- Canal de notificaciones por defecto -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="rehabtech_reminders" />

<!-- Icono de notificación por defecto -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_icon"
    android:resource="@mipmap/ic_launcher" />
```

---

## Verificar Implementación

### 1. Debug View en Firebase Console
- Ve a Analytics → DebugView
- Ejecuta la app en modo debug
- Verifica que los eventos aparezcan en tiempo real

### 2. Verificar FCM
```dart
// En la app, imprime el token FCM
final token = await FirebaseMessaging.instance.getToken();
print('FCM Token: $token');
```

### 3. Enviar notificación de prueba
- Ve a Firebase Console → Cloud Messaging
- Click en "Enviar tu primer mensaje"
- Usa el token FCM para enviar a un dispositivo específico

---

## Próximos Pasos

1. **Configurar Conversiones**: Marcar eventos importantes como conversiones (exercise_completed, sign_up)
2. **Configurar Funnels**: Crear embudos para tracking de onboarding
3. **A/B Testing**: Probar diferentes mensajes de notificación
4. **BigQuery Export**: Para análisis avanzado de datos
