# 10. SOFTWARE SEGURO

## Introducción

La seguridad del software constituye un pilar fundamental en el desarrollo de **RehabTech**, una aplicación móvil de rehabilitación física que gestiona datos clínicos sensibles de pacientes, información personal identificable (PII), historial de tratamientos, comunicaciones médico-paciente y registros de sesiones de terapia basados en captura de video. Por la naturaleza del sector salud y el nivel de sensibilidad de los datos manejados —clasificado como **alto**—, el sistema requiere un enfoque de seguridad integral que proteja la confidencialidad, integridad y disponibilidad de la información en todas las capas de la arquitectura.

El desarrollo de RehabTech se rige bajo los principios de **Security by Design**, integrando controles de seguridad desde las fases más tempranas del ciclo de vida del software. Los marcos de referencia adoptados incluyen el **OWASP Mobile Application Security Verification Standard (MASVS)** nivel L1/L2 para aplicaciones móviles, los lineamientos del **OWASP Top 10 Mobile Risks**, los controles del estándar **ISO/IEC 27001:2022** para gestión de seguridad de la información, las directrices del **NIST Cybersecurity Framework (CSF)** para gestión de riesgos, y las buenas prácticas del **CERT Secure Coding** para el desarrollo en Dart/Flutter. Adicionalmente, al manejar datos de salud, se consideran los principios de la **Ley Federal de Protección de Datos Personales en Posesión de los Particulares (LFPDPPP)** de México y las directrices generales del **RGPD/GDPR** para protección de datos personales sensibles.

---

## 10.1 IDENTIFICACIÓN DE RIESGOS

### 10.1.1 Objetivo

Identificar, clasificar y evaluar de forma sistemática los riesgos de seguridad asociados al sistema RehabTech, abarcando componentes de software, infraestructura en la nube, flujos de datos, interfaces de usuario y servicios de terceros. Esta identificación permite establecer una línea base de riesgos que fundamenta la definición de controles técnicos y organizacionales, garantizando que las decisiones de mitigación se tomen de forma informada y proporcional al nivel de riesgo.

### 10.1.2 Alcance del Análisis

El análisis de riesgos cubre los siguientes componentes y activos del sistema:

| Componente | Descripción | Tipo de Activo |
|---|---|---|
| Aplicación móvil Flutter | Cliente Android/iOS con lógica de negocio, UI y procesamiento local | Software |
| Firebase Authentication | Servicio de autenticación (email/contraseña, Google Sign-In) | Servicio de identidad |
| Cloud Firestore | Base de datos NoSQL con datos de usuarios, rutinas, citas, conversaciones y progreso | Datos |
| Firebase Storage | Almacenamiento de imágenes de perfil, videos de ejercicios, reportes PDF y capturas de sesión | Datos |
| Google Gemini API | Servicio de IA para el asistente virtual Nora (chat conversacional) | Servicio externo |
| ML Kit Pose Detection | Detección de pose mediante cámara del dispositivo | Procesamiento local |
| Firebase Cloud Messaging (FCM) | Servicio de notificaciones push | Comunicación |
| Firebase App Check | Verificación de autenticidad de la aplicación | Control de seguridad |
| Firebase Analytics | Recopilación de métricas y eventos de usuario | Datos analíticos |
| Deep Links (GoRouter) | Puntos de entrada externos a la aplicación | Interfaz |
| Variables de entorno (.env) | API keys y secretos de configuración | Credenciales |

### 10.1.3 Metodología de Identificación de Riesgos

La identificación de riesgos se realizó empleando un enfoque combinado de las siguientes metodologías:

1. **Modelo STRIDE (Microsoft):** Se aplicó el modelo de categorización de amenazas STRIDE (*Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege*) para analizar cada componente del sistema desde la perspectiva de las seis categorías de amenazas, permitiendo una cobertura estructurada.

2. **OWASP Mobile Top 10 (2024):** Se evaluaron los diez riesgos más críticos para aplicaciones móviles según OWASP, incluyendo almacenamiento inseguro de datos, comunicación insegura, autenticación insuficiente, criptografía insuficiente y calidad del código.

3. **Análisis de superficie de ataque:** Se mapeó la superficie de ataque del sistema identificando todos los puntos de entrada, flujos de datos y dependencias externas que podrían ser explotados.

4. **Revisión de código y configuración:** Se realizó revisión estática de las reglas de seguridad de Firestore y Storage, configuración de autenticación, manejo de API keys y permisos del manifiesto Android.

### 10.1.4 Categorías de Riesgos Evaluadas

#### A. Riesgos de Seguridad (Vulnerabilidades Técnicas)

Comprenden vulnerabilidades en el código fuente, dependencias de terceros, configuración de servicios Firebase y procesamiento de datos en el cliente. Se evaluaron aspectos como inyección de datos, almacenamiento inseguro, manejo inadecuado de errores y exposición de información sensible en logs.

#### B. Riesgos de Acceso y Autenticación

Incluyen amenazas relacionadas con el sistema de autenticación basado en Firebase Auth (email/contraseña y Google Sign-In), gestión de sesiones, control de acceso basado en roles (paciente/fisioterapeuta), y las reglas de seguridad de Firestore que implementan el principio de mínimo privilegio mediante funciones como `isOwner()`, `isTherapist()`, `isAssignedTherapist()` y `onlyUpdatesFields()`.

#### C. Riesgos en la Gestión de Datos

Abarcan los riesgos asociados al ciclo de vida de datos sensibles: datos personales de pacientes (nombre, email, teléfono), datos clínicos (progreso, sesiones de terapia, rutinas), conversaciones con el asistente Nora, mensajes entre paciente-terapeuta, capturas de video de sesiones de ejercicio, y tokens de notificación (FCM).

#### D. Riesgos de Infraestructura y Red

Cubren la dependencia de servicios en la nube de Google (Firebase), la comunicación entre el cliente móvil y los servicios backend, la integración con APIs externas (Gemini AI), los deep links como vectores de entrada, y la configuración de red del dispositivo móvil.

#### E. Riesgos Humanos y Operacionales

Consideran errores de configuración por parte del equipo de desarrollo, ingeniería social dirigida a usuarios (phishing), uso compartido de dispositivos, pérdida o robo del dispositivo móvil, y la gestión inadecuada de secretos y credenciales en el repositorio de código.

### 10.1.5 Registro de Riesgos Identificados

| ID | Categoría | Descripción del Riesgo | Activo Afectado | Probabilidad | Impacto | Nivel de Riesgo | Estado |
|---|---|---|---|---|---|---|---|
| R-001 | Gestión de Datos | Exposición de la API key de Gemini almacenada en archivo `.env` en el dispositivo. Un atacante con acceso al APK podría extraerla mediante ingeniería inversa y consumir la API sin autorización. | Variables de entorno (.env), Gemini API | Alta | Alto | **Crítico** | Abierto |
| R-002 | Acceso y Autenticación | Ausencia de verificación obligatoria de email tras el registro. Un usuario puede acceder a todas las funcionalidades de la aplicación con un email no verificado, permitiendo la creación de cuentas falsas. | Firebase Auth, Firestore (datos de usuario) | Alta | Medio | **Alto** | Abierto |
| R-003 | Seguridad Técnica | Validación insuficiente de contraseñas en el registro. No se exige longitud mínima robusta, caracteres especiales ni complejidad, delegando únicamente en el mínimo de 6 caracteres de Firebase Auth. | Firebase Auth, Módulo de registro | Alta | Medio | **Alto** | Abierto |
| R-004 | Gestión de Datos | Reglas de Storage demasiado permisivas para `chat_attachments/{conversationId}`. Cualquier usuario autenticado puede leer y escribir archivos en cualquier conversación sin validación de participación. | Firebase Storage (chat_attachments) | Media | Alto | **Alto** | Abierto |
| R-005 | Acceso y Autenticación | Regla de Firestore para creación de conversaciones (`conversations`) permite `allow create: if isAuthenticated()` sin validar que el usuario sea parte de la conversación, permitiendo a cualquier usuario autenticado crear conversaciones arbitrarias. | Firestore (conversations) | Media | Alto | **Alto** | Abierto |
| R-006 | Infraestructura y Red | Error de configuración `DEVELOPER_ERROR` en Google Sign-In por SHA-1 no registrado en Firebase Console. Aunque no es explotable, impide el funcionamiento correcto de la autenticación con Google, afectando disponibilidad. | Firebase Auth (Google Sign-In) | Alta | Medio | **Alto** | Abierto |
| R-007 | Seguridad Técnica | Exposición de información sensible en logs de producción. Se registran parcialmente tokens FCM (`_fcmToken?.substring(0, 20)`) y datos de contexto que podrían ser accesibles mediante herramientas de depuración o acceso físico al dispositivo. | Servicio de notificaciones, Logger | Media | Medio | **Medio** | Abierto |
| R-008 | Gestión de Datos | Acumulación indefinida de tokens FCM en Firestore. No existe mecanismo de expiración ni limpieza de tokens obsoletos, lo que puede generar envío de notificaciones a dispositivos inactivos y consumo innecesario de recursos. | Firestore (fcm_tokens), FCM | Media | Bajo | **Medio** | Abierto |
| R-009 | Seguridad Técnica | Ausencia de validación de esquema en reglas de Firestore para colecciones `notifications`, `sent_notifications` y `feedback`. Un usuario malicioso podría crear documentos con campos arbitrarios o datos excesivamente grandes. | Firestore (múltiples colecciones) | Media | Medio | **Medio** | Abierto |
| R-010 | Infraestructura y Red | Inyección o manipulación de parámetros en deep links (`rehabtech://exercise/{id}`). Un atacante podría craftar URLs maliciosas para navegar a pantallas no autorizadas o provocar comportamiento inesperado. | Deep Links (GoRouter), App móvil | Baja | Medio | **Medio** | Abierto |
| R-011 | Humano y Operacional | Pérdida o robo del dispositivo móvil con sesión activa. La sesión de Firebase Auth persiste hasta cierre explícito, lo que permitiría acceso completo a datos del paciente incluyendo historial médico y conversaciones. | Dispositivo móvil, Firebase Auth, Firestore | Media | Alto | **Alto** | Abierto |
| R-012 | Gestión de Datos | Ausencia de cifrado adicional para datos sensibles de salud almacenados en Firestore. Aunque Firebase cifra datos en reposo, no existe cifrado a nivel de campo para información especialmente sensible como historial de dolor reportado o notas clínicas. | Firestore (progress, sessions, patient_context) | Baja | Alto | **Medio** | Abierto |

### 10.1.6 Criterios de Evaluación

La evaluación de probabilidad e impacto se realizó utilizando una escala cualitativa de tres niveles, con los siguientes criterios:

**Tabla 10.1a — Criterios de Probabilidad**

| Nivel | Valor | Criterio |
|---|---|---|
| Alta (A) | 3 | El evento tiene alta probabilidad de ocurrir. Existe evidencia de ocurrencia en sistemas similares, el vector de ataque es de baja complejidad o la vulnerabilidad ha sido confirmada en el análisis. |
| Media (M) | 2 | El evento podría ocurrir bajo condiciones específicas. Requiere cierto nivel de habilidad técnica o acceso previo. Se ha identificado la vulnerabilidad pero su explotación no es trivial. |
| Baja (B) | 1 | El evento es poco probable. Requiere condiciones excepcionales, habilidades avanzadas o acceso físico al dispositivo. No se ha identificado evidencia de explotación activa. |

**Tabla 10.1b — Criterios de Impacto**

| Nivel | Valor | Criterio |
|---|---|---|
| Alto (A) | 3 | Compromiso de datos sensibles de salud, pérdida de confidencialidad masiva, daño reputacional significativo, implicaciones legales por incumplimiento de normativa de protección de datos o interrupción total del servicio. |
| Medio (M) | 2 | Acceso no autorizado parcial a datos, afectación de funcionalidades específicas, degradación del servicio o exposición limitada de información personal sin datos clínicos. |
| Bajo (B) | 1 | Impacto cosmético o menor, afectación de funcionalidades no críticas, sin exposición de datos sensibles. La recuperación es inmediata y no requiere intervención especial. |

**Tabla 10.1c — Matriz de Nivel de Riesgo**

| Probabilidad \ Impacto | Bajo (1) | Medio (2) | Alto (3) |
|---|---|---|---|
| **Alta (3)** | Medio (3) | Alto (6) | Crítico (9) |
| **Media (2)** | Bajo (2) | Medio (4) | Alto (6) |
| **Baja (1)** | Bajo (1) | Medio (2) | Medio (3) |

*Nivel de Riesgo = Probabilidad × Impacto*

- **Crítico (7-9):** Requiere acción inmediata antes de cualquier release.
- **Alto (5-6):** Debe mitigarse en el sprint actual.
- **Medio (3-4):** Planificar mitigación en los próximos 2 sprints.
- **Bajo (1-2):** Aceptar o planificar para mejora continua.

---

## 10.2 PLAN DE MITIGACIÓN DE RIESGOS

### 10.2.1 Objetivo

Definir las estrategias, acciones concretas y controles técnicos para reducir el nivel de exposición de cada riesgo identificado en la sección 10.1 a un nivel aceptable, asignando responsabilidades claras, herramientas específicas y plazos de implementación. El plan busca garantizar que la seguridad de RehabTech sea proporcional a la sensibilidad de los datos de salud que gestiona y al marco regulatorio aplicable al sector.

### 10.2.2 Estrategias de Respuesta

Se aplican las siguientes estrategias de respuesta según la naturaleza y nivel de cada riesgo:

| Estrategia | Descripción | Aplicación en RehabTech |
|---|---|---|
| **Evitar** | Eliminar la causa raíz del riesgo rediseñando el componente o eliminando la funcionalidad vulnerable. | Mover API keys de Gemini al backend (Cloud Functions) para eliminar la exposición en el cliente. |
| **Reducir/Mitigar** | Implementar controles técnicos u organizacionales que disminuyan la probabilidad o el impacto del riesgo. | Validación de contraseñas fuertes, verificación de email, sanitización de deep links, reglas de Firestore estrictas. |
| **Transferir** | Delegar la gestión del riesgo a un tercero con mayor capacidad o especialización. | Uso de Firebase Auth (gestión de identidad), Firebase App Check (verificación de app), Google Play Integrity (protección de la plataforma). |
| **Aceptar** | Reconocer el riesgo y asumir sus consecuencias cuando el costo de mitigación es desproporcionado al impacto. Requiere justificación documentada y aprobación. | Riesgo residual de cifrado a nivel de campo en Firestore (ya cifrado en reposo por Google). |

### 10.2.3 Plan de Mitigación

| ID Riesgo | Riesgo | Estrategia | Acción de Mitigación | Responsable | Herramienta/Control | Fecha Límite | Estado |
|---|---|---|---|---|---|---|---|
| R-001 | Exposición de API key de Gemini en `.env` | Evitar | 1. Migrar las llamadas a Gemini API a una Cloud Function de Firebase que actúe como proxy seguro. 2. Eliminar `GEMINI_API_KEY` del archivo `.env` del cliente. 3. La Cloud Function validará el token de Firebase Auth y App Check antes de invocar a Gemini. 4. Rotar la API key actual inmediatamente. | Desarrollador Backend | Firebase Cloud Functions, Secret Manager de GCP, Firebase App Check | Sprint actual | Pendiente |
| R-002 | Ausencia de verificación obligatoria de email | Reducir | 1. Implementar pantalla de verificación de email post-registro (`EmailVerificationScreen`). 2. Bloquear acceso a pantallas principales hasta que `emailVerified == true`. 3. Agregar botón de reenvío de correo de verificación con cooldown de 60 segundos. 4. Validar `emailVerified` en el redirect guard de GoRouter. | Desarrollador Frontend | Firebase Auth (`sendEmailVerification`), GoRouter (redirect guard) | Sprint actual | Pendiente |
| R-003 | Validación insuficiente de contraseñas | Reducir | 1. Implementar validador de contraseñas con reglas: mínimo 8 caracteres, al menos 1 mayúscula, 1 minúscula, 1 número y 1 carácter especial. 2. Agregar indicador visual de fortaleza de contraseña en `RegisterScreen`. 3. Reutilizar validador en `SecurityScreen` (cambio de contraseña). | Desarrollador Frontend | Regex de validación en Dart, widget `PasswordStrengthIndicator` | Sprint actual | Pendiente |
| R-004 | Storage Rules permisivas en chat_attachments | Reducir | 1. Modificar reglas de Storage para `chat_attachments` validando que el usuario sea participante de la conversación mediante consulta cruzada a Firestore. 2. Agregar validación de tipo de archivo (`isImage() \|\| isPDF()`) además de la validación de tamaño existente. | Desarrollador Backend | Firebase Storage Rules, Firestore cross-reference | Sprint actual | Pendiente |
| R-005 | Creación de conversaciones sin validación | Reducir | 1. Modificar regla de Firestore para `conversations` requiriendo que `request.resource.data.therapistId == request.auth.uid \|\| request.resource.data.patientId == request.auth.uid`. 2. Validar que el `therapistId` y `patientId` correspondan a usuarios existentes con los roles correctos. | Desarrollador Backend | Firestore Security Rules | Sprint actual | Pendiente |
| R-006 | DEVELOPER_ERROR en Google Sign-In | Reducir | 1. Generar SHA-1 y SHA-256 del keystore de debug y release. 2. Registrar ambos fingerprints en Firebase Console → Configuración del proyecto → Aplicaciones Android. 3. Descargar `google-services.json` actualizado. 4. Documentar proceso en guía de desarrollo. | DevOps / Desarrollador | Firebase Console, `keytool`, `google-services.json` | Sprint actual | Pendiente |
| R-007 | Información sensible en logs de producción | Reducir | 1. Implementar nivel de log condicional: deshabilitar logs de nivel `DEBUG` e `INFO` sensibles en modo release usando `kReleaseMode`. 2. Ofuscar tokens FCM completamente en logs (reemplazar por hash). 3. Auditar todos los `AppLogger.info()` y `AppLogger.debug()` que contengan datos sensibles. | Desarrollador Frontend | `AppLogger` con filtro por `kReleaseMode`, revisión de código | Próximo sprint | Pendiente |
| R-008 | Acumulación de tokens FCM obsoletos | Reducir | 1. Crear Cloud Function programada (Cloud Scheduler) que elimine tokens FCM con `updatedAt` mayor a 30 días. 2. Agregar campo `lastUsed` actualizado en cada uso del token. 3. Invalidar tokens al cerrar sesión (ya implementado parcialmente en `removeToken()`). | Desarrollador Backend | Firebase Cloud Functions, Cloud Scheduler | Próximo sprint | Pendiente |
| R-009 | Ausencia de validación de esquema en Firestore | Reducir | 1. Agregar funciones de validación en Firestore Rules para cada colección: verificar campos obligatorios, tipos de datos y longitud máxima. 2. Implementar función `hasRequiredFields()` reutilizable. 3. Limitar tamaño de campos de texto (máximo 5000 caracteres para mensajes, 500 para títulos). | Desarrollador Backend | Firestore Security Rules | Próximo sprint | Pendiente |
| R-010 | Manipulación de deep links | Reducir | 1. Sanitizar y validar todos los parámetros recibidos por deep links en `DeepLinkService`. 2. Validar formato de IDs (alfanumérico, longitud esperada). 3. Verificar autenticación antes de navegar a rutas protegidas. 4. Manejar URLs malformadas con redirección a pantalla principal. | Desarrollador Frontend | `DeepLinkService`, GoRouter redirect guards, validación con RegExp | Próximo sprint | Pendiente |
| R-011 | Dispositivo perdido/robado con sesión activa | Reducir | 1. Implementar timeout de sesión configurable (inactividad > 30 minutos → re-autenticación). 2. Agregar opción de cerrar sesiones remotamente desde perfil. 3. Implementar bloqueo biométrico opcional (huella/Face ID) para acceder a la app. 4. Documentar al usuario la importancia del bloqueo de pantalla. | Desarrollador Frontend | `local_auth` (biometría), `SharedPreferences` (timeout), Firebase Auth (revoke tokens) | Sprint +2 | Pendiente |
| R-012 | Ausencia de cifrado adicional a nivel de campo | Aceptar | **Justificación de aceptación:** Firebase Firestore y Firebase Storage implementan cifrado en reposo (AES-256) y en tránsito (TLS 1.3) de forma nativa. Los datos están protegidos por las reglas de seguridad de Firestore que restringen acceso por usuario/rol. El costo de implementar cifrado a nivel de campo (E2EE) es desproporcionado para el nivel de riesgo residual y degradaría la funcionalidad de búsqueda y consultas. Se monitorea como riesgo aceptado con revisión trimestral. | Líder de Seguridad | Revisión trimestral, Firebase Built-in Encryption | Revisión: Q2 2026 | Aceptado |

### 10.2.4 Controles Técnicos Implementados

Adicionalmente a las acciones de mitigación específicas, RehabTech implementa los siguientes controles de seguridad transversales:

**Tabla 10.2a — Controles Técnicos Transversales**

| Control | Descripción | Estado | Evidencia |
|---|---|---|---|
| **Cifrado en tránsito** | Todas las comunicaciones entre la app y Firebase utilizan TLS 1.2+ de forma obligatoria. Las llamadas a Gemini API se realizan sobre HTTPS. | ✅ Implementado | Configuración nativa de Firebase SDK |
| **Cifrado en reposo** | Firebase Firestore y Storage cifran todos los datos en reposo mediante AES-256, gestionado automáticamente por Google Cloud. | ✅ Implementado | Infraestructura de Firebase/GCP |
| **Firebase App Check** | Verificación de que las solicitudes provienen de una instancia legítima de la aplicación. Android utiliza Play Integrity en producción y Debug Provider en desarrollo. | ✅ Implementado | `lib/core/utils/app_check_service.dart` |
| **Reglas de acceso Firestore** | Control de acceso basado en roles con funciones `isOwner()`, `isTherapist()`, `isAssignedTherapist()`, `isPatient()`. Principio de mínimo privilegio implementado por colección. | ✅ Implementado | `firestore.rules` (214 líneas) |
| **Reglas de acceso Storage** | Validación de tipo de archivo (`isImage()`, `isVideo()`, `isPDF()`), tamaño máximo (5MB/50MB) y propiedad por usuario. | ✅ Implementado | `storage.rules` (93 líneas) |
| **Restricción de campos actualizables** | Función `onlyUpdatesFields()` en Firestore Rules que limita qué campos puede modificar cada rol, previniendo escalación de privilegios. | ✅ Implementado | `firestore.rules` (función auxiliar) |
| **Manejo centralizado de errores** | `ErrorHandler` captura errores globales de Flutter y zona, clasificándolos por tipo (network, auth, permission, validation, server). Evita exposición de stack traces al usuario. | ✅ Implementado | `lib/core/utils/error_handler.dart` |
| **Logging estructurado** | `AppLogger` con niveles (DEBUG, INFO, WARNING, ERROR) y tags por módulo. Facilita auditoría sin exponer datos en la UI. | ✅ Implementado | `lib/core/utils/logger.dart` |
| **Verificación de email** | Se envía correo de verificación al registrarse (`sendEmailVerification`). Pendiente: bloquear acceso hasta verificación. | ⚠️ Parcial | `register_screen.dart` línea 96 |
| **Eliminación de tokens FCM** | Al cerrar sesión, se eliminan los tokens FCM de Firestore para evitar notificaciones a dispositivos desvinculados. | ✅ Implementado | `notification_service.dart` (`removeToken()`) |
| **Principio de denegación por defecto** | En Storage y Firestore, las colecciones no declaradas explícitamente son denegadas por defecto. La colección `achievements` tiene `allow write: if false`. | ✅ Implementado | `firestore.rules`, `storage.rules` |

### 10.2.5 Procedimiento de Seguimiento de Riesgos

El seguimiento de los riesgos identificados y las acciones de mitigación se ejecutará con el siguiente procedimiento:

**Frecuencia de Revisión:**

| Nivel de Riesgo | Frecuencia de Revisión | Responsable |
|---|---|---|
| Crítico | Cada sprint (2 semanas) | Líder de Desarrollo + Seguridad |
| Alto | Cada 2 sprints (4 semanas) | Líder de Desarrollo |
| Medio | Mensual | Equipo de Desarrollo |
| Bajo | Trimestral | Equipo de Desarrollo |
| Aceptado | Trimestral | Líder de Seguridad |

**Actividades de Seguimiento:**

1. **Revisión de estado de mitigaciones:** En cada Sprint Review se verifica el avance de las acciones de mitigación pendientes contra los plazos establecidos.

2. **Actualización del registro de riesgos:** Se actualizan los estados (Abierto → En progreso → Mitigado → Cerrado) y se re-evalúa el nivel de riesgo residual.

3. **Identificación de nuevos riesgos:** Cada nueva funcionalidad o dependencia incorporada al proyecto se somete a análisis de riesgos antes del merge a la rama principal.

4. **Ejecución de `flutter analyze`:** Tras cada conjunto de cambios, se ejecuta el análisis estático de código para detectar problemas de calidad y potenciales vulnerabilidades. El criterio de aceptación es **cero issues**.

5. **Revisión de dependencias:** Mensualmente se ejecuta `flutter pub outdated` para identificar paquetes con vulnerabilidades conocidas y planificar actualizaciones.

6. **Auditoría de reglas de seguridad:** Antes de cada deploy de reglas (`firebase deploy --only firestore:rules,storage:rules`), se realiza revisión peer de los cambios propuestos.

**Herramientas de Seguimiento:**

| Herramienta | Uso |
|---|---|
| GitHub Issues / Projects | Tracking de riesgos y acciones de mitigación con etiquetas `security` |
| Firebase Console | Monitoreo de reglas de seguridad, App Check, Auth, y alertas |
| Flutter Analyze | Análisis estático de código (SAST básico) |
| `flutter pub outdated` | Verificación de dependencias desactualizadas |
| `docs/TODO.md` | Registro interno de tareas pendientes de seguridad |

### 10.2.6 Indicadores de Control (KPIs de Seguridad)

Los siguientes indicadores clave se monitorearán para evaluar la efectividad del plan de mitigación:

| KPI | Descripción | Meta | Frecuencia de Medición |
|---|---|---|---|
| **Vulnerabilidades críticas abiertas** | Número de riesgos con nivel crítico en estado "Abierto". | 0 | Sprint |
| **Vulnerabilidades altas abiertas** | Número de riesgos con nivel alto en estado "Abierto". | ≤ 2 | Sprint |
| **Tiempo medio de resolución (MTTR)** | Tiempo promedio desde la identificación de un riesgo hasta su mitigación efectiva. | Crítico: < 7 días, Alto: < 30 días | Mensual |
| **Cobertura de reglas de Firestore** | Porcentaje de colecciones con reglas de seguridad definidas que incluyen validación de esquema. | 100% | Mensual |
| **Issues de `flutter analyze`** | Número de warnings, hints o errores reportados por el análisis estático. | 0 | Cada commit |
| **Dependencias desactualizadas críticas** | Número de paquetes con actualizaciones de seguridad pendientes. | 0 | Mensual |
| **Tasa de éxito de App Check** | Porcentaje de solicitudes que pasan la verificación de App Check vs. solicitudes rechazadas. | > 99% | Semanal |
| **Cobertura de tests de seguridad** | Porcentaje de servicios críticos (Auth, Notifications, DeepLinks) con tests unitarios que cubren flujos de seguridad. | > 80% | Sprint |
| **Incidentes de seguridad reportados** | Número de incidentes de seguridad reportados por usuarios o detectados internamente. | 0 | Mensual |
| **Tokens FCM obsoletos** | Porcentaje de tokens FCM con `updatedAt` > 30 días respecto al total. | < 5% | Mensual |

**Fórmula del Nivel de Riesgo Residual:**

$$
\text{Riesgo Residual} = \text{Riesgo Inherente} \times (1 - \text{Efectividad del Control})
$$

Donde la efectividad del control se evalúa como:
- **Alta (0.8):** Control automatizado verificable
- **Media (0.5):** Control implementado con supervisión manual
- **Baja (0.2):** Control parcial o no verificable

---

*Documento elaborado conforme a los lineamientos de OWASP MASVS, ISO/IEC 27001:2022, NIST CSF y LFPDPPP.*

*Próxima revisión programada: Marzo 2026.*
