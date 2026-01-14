# 📋 Lista de Tareas Pendientes - RehabTech

> Última actualización: 14 de enero de 2026

---

## 🔴 CRÍTICO - Seguridad (Prioridad Alta)

### 1. Rotar API Key de Gemini
- [ ] Ir a [Google AI Studio](https://aistudio.google.com/app/apikey)
- [ ] Generar nueva API key
- [ ] Actualizar `.env` con la nueva key
- [ ] Verificar que la app funciona correctamente

### 2. Restringir Firebase API Keys
- [ ] Ir a [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
- [ ] Seleccionar cada API key de Firebase
- [ ] Restricciones de aplicación:
  - Android: Agregar nombre de paquete + SHA-1/SHA-256
  - Web: Restringir por dominio
- [ ] Restricciones de API: Solo las APIs necesarias

### 3. Validación de datos en Firestore Rules
- [ ] Agregar validación de esquema para `/notifications`
- [ ] Agregar validación de esquema para `/sent_notifications`
- [ ] Agregar validación de esquema para `/conversations`
- [ ] Agregar función `hasRequiredFields()` para validar estructura

### 4. Corregir Storage Rules - chat_attachments
- [ ] Validar que el usuario sea participante de la conversación
- [ ] Agregar verificación cruzada con Firestore

---

## 🟠 MEDIO - Seguridad (Prioridad Media)

### 5. Validación de contraseña fuerte
- [ ] Mínimo 8 caracteres
- [ ] Al menos una mayúscula
- [ ] Al menos un número
- [ ] Al menos un carácter especial
- [ ] Mostrar indicador de fortaleza de contraseña
- **Archivos**: `register_screen.dart`, `security_screen.dart`

### 6. Requerir verificación de email
- [ ] Bloquear acceso hasta verificar email
- [ ] Agregar pantalla de "Verifica tu email"
- [ ] Botón para reenviar email de verificación
- [ ] Verificar estado al hacer login

### 7. Limpieza de tokens FCM antiguos
- [ ] Crear Cloud Function para limpiar tokens > 30 días
- [ ] Ejecutar semanalmente con Cloud Scheduler
- [ ] Agregar campo `lastUsed` al token

### 8. Implementar CAPTCHA en login
- [ ] Integrar reCAPTCHA v3
- [ ] Activar después de 3 intentos fallidos
- [ ] Bloqueo temporal después de 5 intentos

---

## 🟡 BAJO - Mejoras de Seguridad

### 9. Deshabilitar logs sensibles en release
- [ ] Condicionar logs de tokens FCM
- [ ] Condicionar logs de API keys
- [ ] Usar `kReleaseMode` para filtrar

### 10. Validación adicional en Deep Links
- [ ] Sanitizar parámetros de URL
- [ ] Validar formato de IDs

---

## 🚀 FUNCIONALIDADES PENDIENTES

### Sistema de Rachas (Streaks)
- [ ] Implementar lógica de cálculo de rachas
- [ ] Guardar racha actual en `user_streaks`
- [ ] Notificación al alcanzar hitos (3, 7, 14, 30 días)
- [ ] Widget visual de racha en home

### Sistema de Logros
- [ ] Crear catálogo de logros en Firestore
- [ ] Implementar desbloqueo automático
- [ ] Pantalla de logros del usuario
- [ ] Notificación al desbloquear logro

### Modo Offline
- [ ] Caché local de ejercicios
- [ ] Cola de sincronización para progreso
- [ ] Indicador de estado de conexión
- [ ] Sincronización automática al reconectar

### Exportación de Datos (GDPR)
- [ ] Endpoint para descargar datos del usuario
- [ ] Botón en perfil para solicitar datos
- [ ] Formato JSON/PDF

### Eliminación de Cuenta
- [ ] Botón en configuración de seguridad
- [ ] Confirmación con contraseña
- [ ] Eliminar datos de Firestore
- [ ] Eliminar archivos de Storage
- [ ] Enviar email de confirmación

---

## 🎨 UI/UX PENDIENTES

### Onboarding
- [ ] Pantallas de introducción para nuevos usuarios
- [ ] Tutorial interactivo de primera sesión
- [ ] Selección de objetivos de rehabilitación

### Accesibilidad
- [ ] Soporte completo de VoiceOver/TalkBack
- [ ] Alto contraste mejorado
- [ ] Tamaños de fuente dinámicos
- [ ] Descripciones de imágenes

### Animaciones
- [ ] Transiciones entre pantallas
- [ ] Feedback visual en botones
- [ ] Celebración al completar ejercicio
- [ ] Animación de racha

### Dark Mode
- [ ] Revisar todos los colores hardcodeados
- [ ] Probar en todas las pantallas
- [ ] Ajustar gráficos de FL Chart

---

## 🧪 TESTING

### Unit Tests
- [ ] `AnalyticsService` - con mocks de Firebase
- [ ] `NotificationService` - con mocks de FCM
- [ ] `ProgressService` - lógica de cálculo
- [ ] `DeepLinkService` - parsing de URLs

### Widget Tests
- [ ] `AppErrorWidget` - todos los factories
- [ ] `EmptyStateWidget` - todos los factories
- [ ] `LoadingWidget` - estados

### Integration Tests
- [ ] Flujo de registro completo
- [ ] Flujo de login (email + Google)
- [ ] Completar un ejercicio
- [ ] Chat con Nora

### E2E Tests
- [ ] Configurar Flutter Driver
- [ ] Test de flujo de paciente
- [ ] Test de flujo de terapeuta

---

## 📱 PLATAFORMAS

### iOS
- [ ] Configurar proyecto Xcode
- [ ] Agregar GoogleService-Info.plist
- [ ] Configurar provisioning profiles
- [ ] Probar notificaciones push
- [ ] Configurar Deep Links (Universal Links)

### Web (si aplica)
- [ ] Optimizar para navegadores
- [ ] PWA configuration
- [ ] Service Worker para offline

---

## 🔧 DEVOPS / INFRAESTRUCTURA

### CI/CD
- [ ] Configurar GitHub Actions
- [ ] Build automático en PR
- [ ] Deploy a Firebase App Distribution
- [ ] Tests automáticos

### Monitoreo
- [ ] Configurar Firebase Crashlytics
- [ ] Alertas de errores críticos
- [ ] Dashboard de métricas

### Cloud Functions
- [ ] Función para enviar notificaciones push
- [ ] Función para limpiar tokens FCM
- [ ] Función para calcular estadísticas diarias
- [ ] Función para generar reportes semanales

---

## 📄 DOCUMENTACIÓN

### Para Desarrolladores
- [ ] Guía de contribución (CONTRIBUTING.md)
- [ ] Documentación de arquitectura
- [ ] Diagramas de flujo
- [ ] API documentation

### Para Usuarios
- [ ] Manual de usuario (PDF)
- [ ] Videos tutoriales
- [ ] FAQ

### Legal
- [ ] Política de privacidad completa
- [ ] Términos y condiciones
- [ ] Aviso de cookies (web)
- [ ] Consentimiento GDPR

---

## 🐛 BUGS CONOCIDOS

### Android
- [ ] `DEVELOPER_ERROR` en Google Sign-In (falta SHA-1 en Firebase Console)
- [ ] Skipped frames en startup (optimizar inicialización)

### General
- [ ] (Agregar bugs reportados aquí)

---

## 📊 MÉTRICAS A IMPLEMENTAR

### Firebase Analytics
- [ ] Conversiones: Marcar eventos importantes
- [ ] Funnels: Onboarding, primer ejercicio
- [ ] Audiencias personalizadas

### Dashboard
- [ ] Usuarios activos diarios/mensuales
- [ ] Ejercicios completados por día
- [ ] Tasa de retención
- [ ] NPS (Net Promoter Score)

---

## 🗓️ PRÓXIMOS RELEASES

### v1.1.0 - Seguridad
- Correcciones de seguridad críticas
- Validación de contraseña
- Verificación de email

### v1.2.0 - Engagement
- Sistema de rachas
- Sistema de logros
- Notificaciones mejoradas

### v1.3.0 - Offline
- Modo offline básico
- Sincronización automática

### v2.0.0 - iOS
- Lanzamiento en App Store
- Universal Links

---

## ✅ COMPLETADO RECIENTEMENTE

- [x] Firebase Analytics integrado
- [x] Firebase Cloud Messaging configurado
- [x] Notificaciones locales (recordatorios diarios)
- [x] Deep linking básico
- [x] Widgets reutilizables (error, empty, loading)
- [x] Firebase App Check
- [x] Firestore Rules con seguridad por usuario
- [x] Storage Rules con validación de archivos
- [x] README actualizado

---

> **Nota**: Marcar tareas como completadas con `[x]` y mover a la sección "Completado Recientemente" cuando estén listas.
