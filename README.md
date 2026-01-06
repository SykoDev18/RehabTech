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
- **Sesiones de Terapia con Cámara**: Guía visual durante los ejercicios
- **Reportes PDF**: Generación de informes de progreso

### 👨‍⚕️ Módulo Fisioterapeuta
- **Gestión de Pacientes**: Lista, búsqueda y registro de pacientes
- **Creación de Rutinas**: Diseño de rutinas personalizadas con ejercicios
- **Calendario de Citas**: Programación y visualización de sesiones
- **Mensajería con Pacientes**: Chat directo con cada paciente
- **Perfil Profesional**: Datos de contacto, especialidad y estadísticas

## 🛠️ Tecnologías

- **Flutter** - Framework de desarrollo multiplataforma
- **Firebase Auth** - Autenticación de usuarios
- **Cloud Firestore** - Base de datos en tiempo real
- **Gemini AI** - Motor de inteligencia artificial para Nora
- **FL Chart** - Visualización de gráficos de progreso
- **Lucide Icons** - Iconografía moderna

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
firebase deploy --only firestore:rules,firestore:indexes
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
│   │   ├── therapy_session_screen.dart
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
│       └── help_center_screen.dart
├── services/
│   ├── progress_service.dart
│   └── pdf_service.dart
└── widgets/
    └── exercise_card.dart
```

## 🔥 Configuración de Firestore

### Índices Requeridos
La app requiere los siguientes índices compuestos en Firestore:

| Colección | Campo 1 | Campo 2 |
|-----------|---------|---------|
| `routines` | therapistId (Asc) | createdAt (Desc) |
| `appointments` | therapistId (Asc) | dateTime (Asc) |
| `conversations` | therapistId (Asc) | lastMessageAt (Desc) |
| `users` | therapistId (Asc) | userType (Asc) |

Puedes crearlos automáticamente con:
```bash
firebase deploy --only firestore:indexes
```

## 🎨 Diseño

- **Tema**: Gradiente `blue-100 → green-50 → blue-50`
- **Tarjetas**: Blancas con bordes redondeados (20px)
- **Iconos**: Lucide Icons
- **Fuente**: Sistema (San Francisco / Roboto)

## 👥 Equipo

Desarrollado con ❤️ para mejorar la calidad de vida de pacientes en rehabilitación.

## 📄 Licencia

Este proyecto es privado y está protegido por derechos de autor.
