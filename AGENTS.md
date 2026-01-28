# 🤖 AGENTS.md - Contexto del Proyecto RehabTech

> **Propósito**: Este documento proporciona todo el contexto necesario para que una IA o agente de código pueda entender y trabajar en el proyecto RehabTech sin conocimiento previo.

---

## 📋 RESUMEN EJECUTIVO

**RehabTech** es una aplicación móvil de rehabilitación física con IA que conecta pacientes con fisioterapeutas. Incluye un asistente virtual llamado "Nora" basado en Gemini AI.

```
Tipo: Aplicación móvil multiplataforma
Framework: Flutter 3.x / Dart
Backend: Firebase (serverless)
IA: Google Gemini
Plataformas: Android (principal), iOS (pendiente)
Idioma: Español (México/LATAM)
```

---

## 🏗️ ARQUITECTURA

### Stack Tecnológico

| Capa        | Tecnología                       | Propósito                         |
| ----------- | --------------------------------- | ---------------------------------- |
| UI          | Flutter + Material 3              | Interfaz de usuario                |
| Estado      | Provider                          | Gestión de estado                 |
| Navegación | GoRouter                          | Routing declarativo + Deep links   |
| Auth        | Firebase Auth                     | Autenticación (email + Google)    |
| Database    | Cloud Firestore                   | Base de datos NoSQL en tiempo real |
| Storage     | Firebase Storage                  | Archivos (imágenes, videos, PDFs) |
| Analytics   | Firebase Analytics                | Métricas y eventos                |
| Push        | FCM + flutter_local_notifications | Notificaciones                     |
| IA Chat     | Google Gemini API                 | Asistente virtual Nora             |
| Pose        | ML Kit Pose Detection             | Detección de pose en ejercicios   |
| Charts      | FL Chart                          | Gráficos de progreso              |
| Icons       | Lucide Icons                      | Iconografía                       |
| PDF         | pdf + printing                    | Generación de reportes            |

### Estructura de Carpetas

```
lib/
├── main.dart                    # Entry point
├── firebase_options.dart        # Config Firebase (auto-generado)
├── core/
│   └── utils/
│       ├── logger.dart          # AppLogger para logging
│       ├── error_handler.dart   # Manejo global de errores
│       └── app_check_service.dart # Firebase App Check
├── domain/
│   └── entities/                # Modelos de dominio
│       ├── user_entity.dart
│       ├── patient_entity.dart
│       ├── routine_entity.dart
│       ├── appointment_entity.dart
│       └── chat_entity.dart
├── models/
│   └── exercise.dart            # Modelo de ejercicio
├── router/
│   └── app_router.dart          # Configuración de GoRouter
├── screens/
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── forgot_password_screen.dart
│   ├── main/                    # 👤 MÓDULO PACIENTE
│   │   ├── main_nav_screen.dart
│   │   ├── home_screen.dart
│   │   ├── exercises_screen.dart
│   │   ├── exercise_detail_screen.dart
│   │   ├── countdown_screen.dart
│   │   ├── therapy_session_screen.dart
│   │   ├── session_report_screen.dart
│   │   ├── messages_screen.dart
│   │   ├── ai_chat_screen.dart
│   │   ├── therapist_chat_screen.dart
│   │   ├── progress_screen.dart
│   │   └── profile_screen.dart
│   ├── therapist/               # 👨‍⚕️ MÓDULO FISIOTERAPEUTA
│   │   ├── therapist_main_nav_screen.dart
│   │   ├── patients_screen.dart
│   │   ├── patient_detail_screen.dart
│   │   ├── routines_screen.dart
│   │   ├── calendar_screen.dart
│   │   ├── therapist_messages_screen.dart
│   │   ├── therapist_chat_detail_screen.dart
│   │   └── therapist_profile_screen.dart
│   └── profile/                 # Pantallas de configuración
│       ├── edit_profile_screen.dart
│       ├── security_screen.dart
│       ├── notifications_screen.dart
│       ├── my_therapist_screen.dart
│       └── help_center_screen.dart
├── services/
│   ├── analytics_service.dart   # Firebase Analytics
│   ├── notification_service.dart # FCM + Local notifications
│   ├── deep_link_service.dart   # Manejo de deep links
│   ├── progress_service.dart    # Cálculo de progreso
│   └── pdf_service.dart         # Generación de PDFs
├── widgets/
│   ├── exercise_card.dart
│   └── common/
│       ├── common_widgets.dart  # Barrel export
│       ├── error_widget.dart    # AppErrorWidget, InlineErrorWidget
│       ├── empty_state_widget.dart # EmptyStateWidget
│       └── loading_widget.dart  # AppLoadingWidget, ShimmerLoading
└── presentation/
    └── providers/
        └── theme_provider.dart  # Tema claro/oscuro
```

---

## 🗄️ BASE DE DATOS (Firestore)

### Colecciones Principales

```javascript
// USUARIOS
users/{userId} {
  name: string,
  lastName: string,
  email: string,
  userType: "patient" | "therapist",
  patientId: string | null,      // Solo pacientes - ID único 6 dígitos
  therapistId: string | null,    // Solo pacientes - UID del terapeuta asignado
  photoUrl: string | null,
  phone: string | null,
  specialty: string | null,      // Solo terapeutas
  createdAt: timestamp
}

// SUBCOLECCIONES DE USUARIO
users/{userId}/nora_chats/{chatId} {
  title: string,
  createdAt: timestamp,
  lastMessageAt: timestamp
}

users/{userId}/nora_chats/{chatId}/messages/{messageId} {
  text: string,
  author: "user" | "nora",
  timestamp: timestamp
}

users/{userId}/progress/{progressId} {
  date: timestamp,
  exercisesCompleted: number,
  totalExercises: number,
  duration: number
}

users/{userId}/routines/{routineId} {
  // Rutinas asignadas al paciente
}

// RUTINAS (globales)
routines/{routineId} {
  name: string,
  description: string,
  therapistId: string,
  patientId: string | null,
  createdAt: timestamp
}

routines/{routineId}/exercises/{exerciseId} {
  name: string,
  reps: number,
  sets: number,
  duration: number,
  instructions: string
}

// CITAS
appointments/{appointmentId} {
  therapistId: string,
  patientId: string,
  dateTime: timestamp,
  status: "scheduled" | "completed" | "cancelled",
  notes: string | null
}

// CONVERSACIONES (paciente-terapeuta)
conversations/{conversationId} {
  therapistId: string,
  patientId: string,
  lastMessage: string,
  lastMessageAt: timestamp
}

conversations/{conversationId}/messages/{messageId} {
  senderId: string,
  text: string,
  timestamp: timestamp,
  read: boolean
}

// EJERCICIOS (catálogo global)
exercises/{exerciseId} {
  name: string,
  description: string,
  category: string,
  videoUrl: string | null,
  imageUrl: string | null,
  difficulty: "beginner" | "intermediate" | "advanced"
}

// TOKENS FCM
fcm_tokens/{tokenId} {
  userId: string,
  token: string,
  platform: "android" | "ios" | "web",
  createdAt: timestamp
}

// CONFIGURACIÓN DE NOTIFICACIONES
notification_settings/{userId} {
  dailyReminder: boolean,
  reminderTime: string,        // "HH:mm"
  therapistMessages: boolean,
  progressUpdates: boolean
}

// FEEDBACK
feedback/{feedbackId} {
  userId: string,
  type: "bug" | "feature" | "general",
  message: string,
  createdAt: timestamp
}
```

---

## 🔐 AUTENTICACIÓN Y ROLES

### Flujo de Autenticación

```
1. Usuario abre app
2. Si no autenticado → LoginScreen
3. Login con email/password O Google Sign-In
4. Se obtiene userType de Firestore
5. Redirección según rol:
   - patient → MainNavScreen (módulo paciente)
   - therapist → TherapistMainNavScreen (módulo terapeuta)
```

### Verificación de Rol

```dart
// En AppRouter
Future<String?> _getUserType() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;
  
  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();
  
  return doc.data()?['userType'] as String?;
}
```

---

## 🤖 ASISTENTE NORA (IA)

### Configuración

```dart
// Archivo: lib/screens/main/ai_chat_screen.dart

final systemPrompt = '''
Eres Nora, asistente virtual de rehabilitación física de RehabTech.

PERSONALIDAD:
- Empática y motivadora
- Profesional pero cálida
- Paciente con las preguntas

CAPACIDADES:
- Explicar ejercicios de rehabilitación
- Motivar al paciente
- Responder dudas sobre el tratamiento

LIMITACIONES ESTRICTAS:
- NUNCA diagnosticar condiciones médicas
- NUNCA prescribir medicamentos
- NUNCA reemplazar al fisioterapeuta
- Siempre recomendar consultar al profesional para dolor severo
''';

// Uso de Gemini
final model = GenerativeModel(
  model: 'gemini-1.5-flash',
  apiKey: dotenv.env['GEMINI_API_KEY']!,
  systemInstruction: Content.system(systemPrompt),
);
```

### Almacenamiento de Chats

Los chats con Nora se guardan en:

- `users/{userId}/nora_chats/{chatId}` - Metadata de conversación
- `users/{userId}/nora_chats/{chatId}/messages/{messageId}` - Mensajes

---

## 📱 NAVEGACIÓN (GoRouter)

### Rutas Principales

```dart
// Archivo: lib/router/app_router.dart

'/' → Redirect basado en auth
'/login' → LoginScreen
'/register' → RegisterScreen
'/forgot-password' → ForgotPasswordScreen

// Paciente
'/home' → MainNavScreen (con BottomNav)
'/exercise/:id' → ExerciseDetailScreen
'/session/:exerciseId' → TherapySessionScreen
'/ai-chat' → AIChatScreen
'/therapist-chat' → TherapistChatScreen

// Terapeuta
'/therapist' → TherapistMainNavScreen
'/therapist/patient/:id' → PatientDetailScreen
'/therapist/routine/create' → CreateRoutineScreen
```

### Deep Links

```
rehabtech://exercise/{id}     → Detalle de ejercicio
rehabtech://chat/nora         → Chat con Nora
rehabtech://chat/therapist    → Chat con terapeuta
rehabtech://profile           → Perfil
https://rehabtech.app/...     → App Links (Android)
```

---

## 🎨 ESTILOS Y DISEÑO

### Tema

```dart
// Archivo: lib/presentation/providers/theme_provider.dart

// Colores principales
primaryColor: Color(0xFF6366F1)    // Indigo
secondaryColor: Color(0xFF3B82F6)  // Blue

// Gradiente de fondo
LinearGradient(
  colors: [
    Color(0xFFDBEAFE), // blue-100
    Color(0xFFDCFCE7), // green-50
    Color(0xFFEFF6FF), // blue-50
  ],
)

// Cards: Glassmorphism
Container(
  decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.8),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.white.withOpacity(0.2)),
  ),
)
```

### Iconos

```dart
// Usar Lucide Icons
import 'package:lucide_icons_flutter/lucide_icons.dart';

Icon(LucideIcons.home)
Icon(LucideIcons.dumbbell)
Icon(LucideIcons.messageCircle)
Icon(LucideIcons.trendingUp)
Icon(LucideIcons.user)
```

---

## 📊 ANALYTICS

### Eventos Principales

```dart
// Archivo: lib/services/analytics_service.dart

// Autenticación
AnalyticsService().logLogin(method: 'email');
AnalyticsService().logSignUp(method: 'google');
AnalyticsService().logLogout();

// Ejercicios
AnalyticsService().logExerciseStarted(exerciseId, name, category);
AnalyticsService().logExerciseCompleted(exerciseId, name, reps, duration, percentage);
AnalyticsService().logExerciseAbandoned(exerciseId, name, reps, duration);

// Chat
AnalyticsService().logChatMessage(isUser: true);
AnalyticsService().logAIChatStarted();

// Progreso
AnalyticsService().logProgressViewed(period: 'weekly');
AnalyticsService().logStreakAchieved(days: 7);
```

---

## 🔔 NOTIFICACIONES

### Configuración FCM

```dart
// Archivo: lib/services/notification_service.dart

// Inicialización
await NotificationService().initialize();

// Suscribirse a topics
await NotificationService().subscribeToTopic('patient');
await NotificationService().subscribeToTopic('therapist');

// Programar recordatorio diario
await NotificationService().scheduleDailyReminder(
  hour: 9,
  minute: 0,
  title: 'Hora de tus ejercicios',
  body: 'No olvides tu rutina de hoy',
);
```

---

## ⚠️ REGLAS IMPORTANTES

### Seguridad

1. **NUNCA** hardcodear API keys en el código
2. **SIEMPRE** usar `.env` para secrets (ya está en `.gitignore`)
3. Las Firebase API keys en `firebase_options.dart` son públicas por diseño (protegidas por App Check)
4. **SIEMPRE** validar `request.auth` en Firestore Rules

### Firestore Rules Pattern

```javascript
// Solo el propietario puede leer/escribir
allow read, write: if request.auth != null && request.auth.uid == userId;

// Terapeuta asignado puede leer
allow read: if request.auth != null && 
  get(/databases/$(database)/documents/users/$(userId)).data.therapistId == request.auth.uid;
```

### Código Dart

```dart
// ✅ CORRECTO: Usar const para widgets estáticos
const SizedBox(height: 16),
const Text('Hola'),

// ✅ CORRECTO: Verificar mounted antes de usar context async
if (mounted) {
  Navigator.pop(context);
}

// ✅ CORRECTO: Manejar errores de Firebase
try {
  await FirebaseAuth.instance.signInWithEmailAndPassword(...);
} on FirebaseAuthException catch (e) {
  // Manejar error específico
}

// ❌ INCORRECTO: No usar LucideIcons.alertCircle (deprecado)
// ✅ CORRECTO: Usar LucideIcons.circleAlert

// ❌ INCORRECTO: Booleanos en Analytics parameters
'is_active': true  // Firebase Analytics no acepta bool

// ✅ CORRECTO: Convertir a int
'is_active': isActive ? 1 : 0
```

---

## 🚀 COMANDOS ÚTILES

```bash
# Instalar dependencias
flutter pub get

# Ejecutar en debug
flutter run

# Analizar código
flutter analyze

# Ejecutar tests
flutter test

# Build Android
flutter build apk --release

# Deploy Firebase Rules
firebase deploy --only firestore:rules,storage:rules

# Deploy Firebase Indexes
firebase deploy --only firestore:indexes
```

---

## 📁 ARCHIVOS IMPORTANTES

| Archivo                                      | Propósito                            |
| -------------------------------------------- | ------------------------------------- |
| `pubspec.yaml`                             | Dependencias del proyecto             |
| `.env`                                     | Variables de entorno (GEMINI_API_KEY) |
| `firebase.json`                            | Config de Firebase CLI                |
| `firestore.rules`                          | Reglas de seguridad Firestore         |
| `firestore.indexes.json`                   | Índices de Firestore                 |
| `storage.rules`                            | Reglas de seguridad Storage           |
| `android/app/google-services.json`         | Config Firebase Android               |
| `android/app/build.gradle.kts`             | Build config Android                  |
| `android/app/src/main/AndroidManifest.xml` | Permisos y config Android             |

---

## 🐛 TROUBLESHOOTING

### Error: DEVELOPER_ERROR en Google Sign-In

**Causa**: SHA-1 no configurado en Firebase Console
**Solución**: Agregar SHA-1 de debug keystore en Firebase Console

### Error: Core library desugaring required

**Causa**: flutter_local_notifications requiere APIs Java 8+
**Solución**: Ya configurado en `build.gradle.kts`:

```kotlin
compileOptions {
    isCoreLibraryDesugaringEnabled = true
}
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
```

### Error: Firebase Analytics boolean parameter

**Causa**: Firebase Analytics solo acepta String o num
**Solución**: Convertir `bool` a `int`: `value ? 1 : 0`

---

## 📝 CONVENCIONES DE CÓDIGO

### Nombres de Archivos

- `snake_case` para archivos: `exercise_detail_screen.dart`
- Sufijo `_screen` para pantallas
- Sufijo `_service` para servicios
- Sufijo `_widget` para widgets reutilizables

### Nombres de Clases

- `PascalCase`: `ExerciseDetailScreen`
- Widgets con sufijo descriptivo: `AppErrorWidget`, `EmptyStateWidget`

### Strings

- Español para UI visible al usuario
- Inglés para código, logs y documentación técnica

### Imports

```dart
// Orden de imports:
// 1. Dart SDK
import 'dart:async';

// 2. Flutter
import 'package:flutter/material.dart';

// 3. Packages externos
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// 4. Imports del proyecto
import 'package:rehabtech/services/analytics_service.dart';
import '../widgets/exercise_card.dart';
```

---

## 🎯 FEATURES PENDIENTES

Ver `docs/TODO.md` para lista completa. Principales:

1. **Sistema de rachas** - Tracking de días consecutivos
2. **Sistema de logros** - Gamificación
3. **Modo offline** - Cache local
4. **iOS** - Configurar proyecto Xcode
5. **Monetización** - Suscripciones con RevenueCat

---

## 📞 CONTACTO

Para dudas sobre el proyecto, revisar:

- `docs/futures.md` - Tareas pendientes
- `docs/MONETIZATION.md` - Modelo de negocio
- `docs/FIREBASE_CONSOLE_GUIDE.md` - Configuración Firebase
- `docs/articles/` - Artículos académicos

---

> **Última actualización**: Enero 2026
>
> **Tip para agentes IA**: Siempre ejecutar `flutter analyze` después de hacer cambios para verificar que no hay errores.
