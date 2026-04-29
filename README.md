# RehabTech 🏃‍♂️💪

Aplicación de rehabilitación física impulsada por Inteligencia Artificial.

## 📱 Descripción

RehabTech es una aplicación móvil diseñada para asistir a pacientes en su proceso de rehabilitación física. Combina ejercicios personalizados con un asistente de IA llamado **Nora** que guía y motiva a los usuarios durante sus rutinas. La app cuenta con dos módulos: uno para **pacientes** y otro para **fisioterapeutas**.

## ✨ Características

### 👤 Módulo Paciente
- **Ejercicios Personalizados**: Rutinas de rehabilitación adaptadas a cada paciente
- **Asistente IA (Nora)**: Guía inteligente que responde dudas y ofrece retroalimentación
- **Seguimiento de Progreso**: Estadísticas diarias, semanales y mensuales
- **Mensajería**: Comunicación con Nora (IA) y tu fisioterapeuta
- **Sesiones de Terapia con Cámara**: Guía visual durante los ejercicios con detección de pose
- **Reportes PDF**: Generación de informes de progreso
- **Notificaciones Push**: Recordatorios diarios y mensajes del terapeuta
- **Sistema de Rachas**: Motivación mediante seguimiento de días consecutivos

### 👨‍⚕️ Módulo Fisioterapeuta
- **Gestión de Pacientes**: Lista, búsqueda y registro de pacientes
- **Creación de Rutinas**: Diseño de rutinas personalizadas con ejercicios
- **Calendario de Citas**: Programación y visualización de sesiones
- **Mensajería con Pacientes**: Chat directo con cada paciente
- **Perfil Profesional**: Datos de contacto, especialidad y estadísticas
- **Notificaciones a Pacientes**: Envío de recordatorios y alertas

### 🔔 Sistema de Notificaciones
- **Recordatorios Diarios**: Configurable por hora
- **Mensajes FCM**: Notificaciones push en tiempo real
- **Deep Links**: Navegación directa desde notificaciones

### 📊 Analytics
- **Eventos de Usuario**: Login, registro, ejercicios completados
- **Métricas de Engagement**: Uso de chat IA, rachas, progreso
- **Segmentación**: Pacientes activos/inactivos, niveles de dolor

## 🛠️ Tecnologías

- **Flutter 3.x** - Framework de desarrollo multiplataforma
- **Firebase Suite**:
  - Firebase Auth - Autenticación (email + Google)
  - Cloud Firestore - Base de datos en tiempo real
  - Firebase Storage - Almacenamiento de archivos
  - Firebase Analytics - Métricas y eventos
  - Firebase Cloud Messaging (FCM) - Notificaciones push
  - Firebase App Check - Seguridad
- **Gemini AI** - Motor de inteligencia artificial para Nora
- **ML Kit Pose Detection** - Detección de pose durante ejercicios
- **FL Chart** - Visualización de gráficos de progreso
- **Lucide Icons** - Iconografía moderna
- **GoRouter** - Navegación declarativa con deep linking

## 🚀 Instalación

1. Clona el repositorio
```bash
git clone https://github.com/tu-usuario/rehabtech.git
```

2. Instala las dependencias
```bash
flutter pub get
```

3. Configura las variables de entorno
```bash
# Crea un archivo .env en la raíz del proyecto
GEMINI_API_KEY=tu_api_key_aqui
```

4. Configura Firebase
```bash
# Asegúrate de tener firebase-tools instalado
npm install -g firebase-tools
firebase login
firebase deploy --only firestore:rules,firestore:indexes --project tu-proyecto
```

5. Ejecuta la aplicación
```bash
flutter run
```

## 📁 Estructura del Proyecto

```
lib/
├── main.dart
├── firebase_options.dart
├── core/
│   └── utils/
│       └── logger.dart
├── domain/
│   └── entities/
│       ├── user_entity.dart
│       ├── patient_entity.dart
│       ├── routine_entity.dart
│       ├── appointment_entity.dart
│       └── chat_entity.dart
├── models/
│   └── exercise.dart
├── router/
│   └── app_router.dart
├── screens/
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── forgot_password_screen.dart
│   ├── main/                          # Módulo Paciente
│   │   ├── main_nav_screen.dart
│   │   ├── home_screen.dart
│   │   ├── exercises_screen.dart
│   │   ├── messages_screen.dart
│   │   ├── progress_screen.dart
│   │   ├── profile_screen.dart
│   │   ├── ai_chat_screen.dart
│   │   ├── therapist_chat_screen.dart
│   │   ├── countdown_screen.dart
│   │   ├── therapy_session_screen.dart
│   │   ├── exercise_detail_screen.dart
│   │   └── session_report_screen.dart
│   ├── therapist/                     # Módulo Fisioterapeuta
│   │   ├── therapist_main_nav_screen.dart
│   │   ├── patients_screen.dart
│   │   ├── patient_detail_screen.dart
│   │   ├── routines_screen.dart
│   │   ├── calendar_screen.dart
│   │   ├── therapist_messages_screen.dart
│   │   ├── therapist_chat_detail_screen.dart
│   │   └── therapist_profile_screen.dart
│   └── profile/
│       ├── edit_profile_screen.dart
│       ├── security_screen.dart
│       ├── my_therapist_screen.dart
│       ├── notifications_screen.dart
│       └── help_center_screen.dart
├── services/
│   ├── analytics_service.dart         # Firebase Analytics
│   ├── notification_service.dart      # FCM + Local Notifications
│   ├── deep_link_service.dart         # Deep linking
│   ├── progress_service.dart
│   └── pdf_service.dart
└── widgets/
    ├── exercise_card.dart
    └── common/
        ├── common_widgets.dart        # Export barrel
        ├── error_widget.dart          # Widgets de error reutilizables
        ├── empty_state_widget.dart    # Estados vacíos
        └── loading_widget.dart        # Indicadores de carga
```

## 🔥 Configuración de Firebase

### Colecciones de Firestore

| Colección | Descripción |
|-----------|-------------|
| `users` | Datos de usuarios (pacientes y terapeutas) |
| `routines` | Rutinas de ejercicios |
| `appointments` | Citas programadas |
| `conversations` | Chats entre paciente-terapeuta |
| `fcm_tokens` | Tokens FCM para notificaciones |
| `sent_notifications` | Historial de notificaciones |
| `user_streaks` | Rachas de ejercicios |
| `user_achievements` | Logros desbloqueados |
| `feedback` | Retroalimentación de usuarios |

### Índices Requeridos
La app requiere los siguientes índices compuestos en Firestore:

| Colección | Campo 1 | Campo 2 |
|-----------|---------|---------|
| `routines` | therapistId (Asc) | createdAt (Desc) |
| `routines` | patientId (Asc) | createdAt (Desc) |
| `appointments` | therapistId (Asc) | dateTime (Asc) |
| `appointments` | patientId (Asc) | dateTime (Asc) |
| `conversations` | therapistId (Asc) | lastMessageAt (Desc) |
| `conversations` | patientId (Asc) | lastMessageAt (Desc) |
| `users` | therapistId (Asc) | userType (Asc) |
| `fcm_tokens` | userId (Asc) | createdAt (Desc) |
| `sent_notifications` | recipientId (Asc) | createdAt (Desc) |
| `user_achievements` | userId (Asc) | unlockedAt (Desc) |

Puedes crearlos automáticamente con:
```bash
firebase deploy --only firestore:indexes --project tu-proyecto
```

## 🔗 Deep Links

La app soporta deep linking para navegación directa:

| URL | Acción |
|-----|--------|
| `rehabtech://exercise/{id}` | Abre detalle de ejercicio |
| `rehabtech://chat/nora` | Abre chat con Nora |
| `rehabtech://chat/therapist` | Abre chat con terapeuta |
| `rehabtech://profile` | Abre perfil |
| `https://rehabtech.app/exercise/{id}` | App Links (Android) |

## 📊 Firebase Analytics - Eventos

| Evento | Descripción |
|--------|-------------|
| `login` | Usuario inició sesión |
| `sign_up` | Usuario se registró |
| `exercise_started` | Inició un ejercicio |
| `exercise_completed` | Completó un ejercicio |
| `exercise_abandoned` | Abandonó un ejercicio |
| `chat_message` | Envió mensaje a Nora |
| `streak_achieved` | Alcanzó racha de días |
| `pain_level_reported` | Reportó nivel de dolor |

Ver [docs/FIREBASE_CONSOLE_GUIDE.md](docs/FIREBASE_CONSOLE_GUIDE.md) para configuración completa.

## 🎨 Diseño

- **Tema**: Gradiente `blue-100 → green-50 → blue-50`
- **Tarjetas**: Glassmorphism con blur y transparencia
- **Bordes**: Redondeados (16-20px)
- **Iconos**: Lucide Icons
- **Fuente**: Sistema (San Francisco / Roboto)
- **Color Primario**: `#6366F1` (Indigo)
- **Color Secundario**: `#3B82F6` (Blue)

## 🧪 Testing

```bash
# Ejecutar todos los tests
flutter test

# Tests con cobertura
flutter test --coverage

# Tests específicos
flutter test test/services/
flutter test test/widgets/
```

## 📱 Requisitos

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Android: minSdk 21, targetSdk 34
- iOS: 12.0+

## ☁️ Cloud Functions (push notifications)

El directorio `functions/` contiene triggers TypeScript que disparan push
notifications via FCM cuando ocurren eventos cross-user que el cliente no
puede notificar de forma segura (porque mandar push requiere el FCM Server
Key, que jamás debe vivir en cliente).

### Triggers

- `onAppointmentCreated`: cuando se crea una cita en `appointments/`,
  notifica al paciente con el tipo de sesión y la fecha/hora
- `onConversationMessageCreated`: cuando se agrega un mensaje en
  `conversations/{id}/messages/`, notifica al participante que NO envió
  el mensaje, con el nombre del remitente y un preview de hasta 80 chars

### Setup local

```bash
cd functions
npm install        # instala firebase-admin + firebase-functions
npm run build      # compila TS -> JS en lib/
cd ..
```

### Despliegue

```bash
firebase deploy --only functions
```

Requiere:

- Plan Blaze (Cloud Functions Gen 2 no funciona en plan Spark)
- Node.js 20 instalado localmente
- `firebase login` previamente ejecutado

### Verificación rápida

Después del deploy, crea una cita desde la app de terapeuta. El paciente
asignado debe recibir el push (si tiene `fcmToken` en su doc de
`users/{uid}` — la app guarda este token en el primer arranque después
de aceptar permisos de notificación).

Logs:

```bash
firebase functions:log --only onAppointmentCreated
firebase functions:log --only onConversationMessageCreated
```

## 🤖 CI/CD (GitHub Actions)

El workflow `.github/workflows/ci.yml` corre en cada push/PR a `main`/`master`:

1. **analyze** — `flutter analyze --fatal-warnings`
2. **test** — `flutter test --coverage` (sube `lcov.info` como artefacto)
3. **build-android** — `flutter build apk --release` (sube el APK como artefacto)
4. **distribute** — Sube el APK a Firebase App Distribution (solo en push a `main`/`master`, grupo `internal-testers`)

### Secretos requeridos

Configurar en *Settings → Secrets and variables → Actions* del repositorio:

| Secret | Uso | Obligatorio |
| --- | --- | --- |
| `KEYSTORE_FILE` | Keystore de release codificado en base64 (`base64 -i upload-keystore.jks`) | Solo para APK firmado |
| `KEY_ALIAS` | Alias de la key dentro del keystore | Solo para APK firmado |
| `KEY_PASSWORD` | Password de la key | Solo para APK firmado |
| `STORE_PASSWORD` | Password del keystore | Solo para APK firmado |
| `FIREBASE_APP_ID` | App ID de Firebase (formato `1:XXX:android:YYY`) | Para distribución |
| `FIREBASE_SERVICE_ACCOUNT` | JSON completo de una service account con rol `Firebase App Distribution Admin` | Para distribución |

Si `KEYSTORE_FILE` no está configurado, el job `build-android` igual corre y genera un APK debug-firmado (útil para validación interna). El job `distribute` solo se ejecuta en pushes a la rama principal.

## 👥 Equipo

Desarrollado con ❤️ para mejorar la calidad de vida de pacientes en rehabilitación.

## 📄 Licencia

Este proyecto es privado y está protegido por derechos de autor.
