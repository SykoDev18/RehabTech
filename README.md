# RehabTech 🏃‍♂️💪

Aplicación de rehabilitación física impulsada por Inteligencia Artificial.

## 📱 Descripción

RehabTech es una aplicación móvil diseñada para asistir a pacientes en su proceso de rehabilitación física. Combina ejercicios personalizados con un asistente de IA llamado **Nora** que guía y motiva a los usuarios durante sus rutinas.

## ✨ Características

- **Ejercicios Personalizados**: Rutinas de rehabilitación adaptadas a cada paciente
- **Asistente IA (Nora)**: Guía inteligente que responde dudas y ofrece retroalimentación
- **Seguimiento de Progreso**: Estadísticas diarias, semanales y mensuales
- **Mensajería**: Comunicación con Nora (IA) y tu fisioterapeuta
- **Sesiones de Terapia**: Programación y gestión de citas
- **Reportes PDF**: Generación de informes de progreso

## 🛠️ Tecnologías

- **Flutter** - Framework de desarrollo multiplataforma
- **Firebase** - Autenticación y base de datos
- **Gemini AI** - Motor de inteligencia artificial para Nora
- **FL Chart** - Visualización de gráficos de progreso

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

4. Ejecuta la aplicación
```bash
flutter run
```

## 📁 Estructura del Proyecto

```
lib/
├── main.dart
├── firebase_options.dart
├── models/
│   └── exercise.dart
├── screens/
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── forgot_password_screen.dart
│   ├── main/
│   │   ├── main_nav_screen.dart
│   │   ├── home_screen.dart
│   │   ├── exercises_screen.dart
│   │   ├── messages_screen.dart
│   │   ├── progress_screen.dart
│   │   ├── profile_screen.dart
│   │   ├── ai_chat_screen.dart
│   │   └── therapist_chat_screen.dart
│   └── profile/
│       └── help_center_screen.dart
├── services/
│   ├── progress_service.dart
│   └── pdf_service.dart
└── widgets/
    └── exercise_card.dart
```

## 👥 Equipo

Desarrollado con ❤️ para mejorar la calidad de vida de pacientes en rehabilitación.

## 📄 Licencia

Este proyecto es privado y está protegido por derechos de autor.
