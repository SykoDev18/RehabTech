# REHABTECH | LICENCIATURA EN INGENIERÍA DE SOFTWARE

---

# 1. PORTADA

---

<div align="center">

## **UNIVERSIDAD AUTÓNOMA DEL ESTADO DE HIDALGO**

### **ESCUELA SUPERIOR DE TLAHUELILPAN**

### **LICENCIATURA EN INGENIERÍA DE SOFTWARE**

---

# **RehabTech: Plataforma Inteligente de Rehabilitación Física Asistida por Inteligencia Artificial**

---

**Autores:**

Malo Martínez José Ángel

Miranda Muñoz Marco Antonio

Montufar Ravelo Clarissa

---

**Fecha:** Abril 2025

**Lugar:** Tlahuelilpan, Hidalgo, México

</div>

---

REHABTECH | LICENCIATURA EN INGENIERÍA DE SOFTWARE | PÁGINA | 1

---

# 2. RESUMEN

## 2.1 Resumen

La presente investigación describe el diseño, desarrollo e implementación de **RehabTech**, una plataforma móvil inteligente de rehabilitación física que integra técnicas de inteligencia artificial y visión por computadora para asistir a pacientes en la ejecución de terapias desde su hogar. El sistema emplea tecnologías de detección de pose en tiempo real mediante MediaPipe y ML Kit para analizar la correcta ejecución de ejercicios terapéuticos, complementado por un modelo de aprendizaje automático basado en TensorFlow y MobileNet que adapta dinámicamente la dificultad de las rutinas según el progreso individual del paciente. La plataforma incorpora un asistente virtual conversacional denominado "Nora", implementado sobre la API de Google Gemini, que proporciona guía personalizada y motivación continua durante las sesiones de rehabilitación. Adicionalmente, el sistema ofrece funcionalidades de monitoreo remoto para fisioterapeutas, generación automática de reportes en formato PDF, notificaciones inteligentes y un sistema de comunicación bidireccional entre pacientes y profesionales de la salud. La arquitectura se fundamenta en Flutter como framework multiplataforma, Firebase como infraestructura serverless y el patrón de diseño Provider para la gestión de estado. La metodología de desarrollo adoptada es Kanban, seleccionada por su flexibilidad y capacidad de adaptación continua. Los resultados preliminares demuestran que la plataforma contribuye significativamente a mejorar la adherencia terapéutica, reducir las barreras de acceso a la rehabilitación física y potenciar la calidad del seguimiento clínico mediante la digitalización integral del proceso rehabilitador.

**Palabras clave:** rehabilitación física, inteligencia artificial, detección de pose, aprendizaje automático, aplicación móvil, Flutter, Firebase, asistente virtual.

## 2.2 Abstract

This research describes the design, development, and implementation of **RehabTech**, an intelligent mobile platform for physical rehabilitation that integrates artificial intelligence and computer vision techniques to assist patients in performing therapies from their homes. The system employs real-time pose detection technologies using MediaPipe and ML Kit to analyze the correct execution of therapeutic exercises, complemented by a machine learning model based on TensorFlow and MobileNet that dynamically adapts the difficulty of routines according to the individual patient's progress. The platform incorporates a conversational virtual assistant named "Nora," implemented on the Google Gemini API, which provides personalized guidance and continuous motivation during rehabilitation sessions. Additionally, the system offers remote monitoring capabilities for physiotherapists, automatic report generation in PDF format, intelligent notifications, and a bidirectional communication system between patients and healthcare professionals. The architecture is built upon Flutter as a cross-platform framework, Firebase as a serverless infrastructure, and the Provider design pattern for state management. The adopted development methodology is Kanban, selected for its flexibility and capacity for continuous adaptation. Preliminary results demonstrate that the platform contributes significantly to improving therapeutic adherence, reducing barriers to access to physical rehabilitation, and enhancing the quality of clinical monitoring through the comprehensive digitization of the rehabilitation process.

**Keywords:** physical rehabilitation, artificial intelligence, pose detection, machine learning, mobile application, Flutter, Firebase, virtual assistant.

---

REHABTECH | LICENCIATURA EN INGENIERÍA DE SOFTWARE | PÁGINA | 2

---

# 3. INTRODUCCIÓN

La rehabilitación física constituye un componente esencial en la recuperación funcional de pacientes que han sufrido lesiones musculoesqueléticas, intervenciones quirúrgicas, accidentes cerebrovasculares o padecimientos crónicos que limitan su movilidad y calidad de vida. En el contexto mexicano, la demanda de servicios de fisioterapia ha experimentado un incremento sostenido durante las últimas décadas, impulsado por factores como el envejecimiento poblacional, la prevalencia de enfermedades crónico-degenerativas y las secuelas derivadas de la pandemia de COVID-19, que generó un aumento sin precedentes en las necesidades de rehabilitación pulmonar, neurológica y musculoesquelética (Organización Mundial de la Salud [OMS], 2022).

Sin embargo, el acceso efectivo a servicios de rehabilitación física en México enfrenta barreras estructurales significativas. Según datos del Instituto Nacional de Estadística y Geografía (INEGI, 2021), aproximadamente el 16.5% de la población mexicana presenta algún tipo de discapacidad o limitación funcional, pero únicamente una fracción minoritaria de estos individuos accede a programas de rehabilitación formales. Las causas de esta brecha son multifacéticas: la concentración de centros de rehabilitación en zonas urbanas, los elevados costos de las sesiones presenciales —que pueden oscilar entre $300 y $1,200 pesos mexicanos por consulta—, la escasez de fisioterapeutas especializados —con una ratio de apenas 1.5 profesionales por cada 10,000 habitantes en varias entidades federativas— y las dificultades de desplazamiento que enfrentan los propios pacientes con limitaciones de movilidad (Secretaría de Salud, 2023).

A estas barreras de acceso se suma un problema de adherencia terapéutica que compromete drásticamente la efectividad de los tratamientos de rehabilitación. La literatura especializada documenta que entre el 50% y el 70% de los pacientes abandonan sus programas de fisioterapia antes de completar el ciclo prescrito, ya sea por falta de motivación, ausencia de supervisión continua, dificultad para recordar la correcta ejecución de los ejercicios o la percepción de avances lentos (Jack et al., 2010). Esta situación configura un problema de salud pública que demanda soluciones innovadoras capaces de trascender las limitaciones del modelo presencial tradicional.

En este contexto, la convergencia de tecnologías emergentes como la inteligencia artificial (IA), la visión por computadora, el aprendizaje automático (*machine learning*) y las plataformas móviles ofrece oportunidades transformadoras para reimaginar la prestación de servicios de rehabilitación. Los avances recientes en modelos de detección de pose humana —particularmente MediaPipe Pose de Google y los modelos de ML Kit— permiten el análisis biomecánico en tiempo real de movimientos corporales utilizando exclusivamente la cámara de un dispositivo móvil convencional, sin requerir sensores adicionales ni equipamiento especializado (Lugaresi et al., 2019). Paralelamente, los modelos de lenguaje de gran escala (*large language models*, LLMs) como Gemini AI han alcanzado la madurez suficiente para fungir como asistentes virtuales conversacionales capaces de proporcionar orientación personalizada, empática y contextualmente relevante en el ámbito de la salud.

Es precisamente en esta intersección tecnológica donde se posiciona **RehabTech**: una plataforma móvil inteligente de rehabilitación física que integra detección de movimientos en tiempo real, adaptación dinámica de la dificultad mediante algoritmos de aprendizaje automático, un asistente virtual interactivo y herramientas de monitoreo remoto para fisioterapeutas. El propósito del presente documento es describir de manera integral el proceso de ingeniería de software que sustenta el desarrollo de RehabTech, abarcando desde la investigación preliminar y definición de requerimientos hasta el diseño arquitectónico, la implementación técnica, las pruebas de calidad y las consideraciones de seguridad. Se busca demostrar cómo la aplicación sistemática de principios de ingeniería de software, combinada con tecnologías de inteligencia artificial 	de vanguardia, puede contribuir a democratizar el acceso a la rehabilitación física de calidad en México y Latinoamérica.

---

REHABTECH | LICENCIATURA EN INGENIERÍA DE SOFTWARE | PÁGINA | 3

---

# 4. INVESTIGACIÓN PRELIMINAR

## 4.1 Enunciado del Problema

La rehabilitación física en México y Latinoamérica enfrenta un conjunto de problemáticas interrelacionadas que limitan su alcance, calidad y efectividad:

**a) Barreras de acceso geográfico y económico.** La concentración de centros de rehabilitación en zonas metropolitanas excluye a millones de pacientes en comunidades rurales y semiurbanas. El costo acumulado de las sesiones presenciales —considerando consultas, transporte y tiempo perdido laboralmente— resulta prohibitivo para un porcentaje significativo de la población, particularmente en un país donde más del 55% de los trabajadores se desempeñan en el sector informal sin acceso a seguridad social (CONEVAL, 2023).

**b) Falta de personalización en los programas terapéuticos.** Los modelos tradicionales de rehabilitación suelen aplicar protocolos estandarizados que no se adaptan al progreso individual ni a las características biomecánicas específicas de cada paciente. La ausencia de mecanismos de retroalimentación en tiempo real impide al fisioterapeuta ajustar la intensidad, duración o complejidad de los ejercicios entre una consulta y otra.

**c) Baja adherencia al tratamiento.** Como se documentó previamente, las tasas de abandono terapéutico oscilan entre el 50% y el 70%. Los factores contribuyentes incluyen la monotonía de las rutinas, la falta de retroalimentación inmediata, la ausencia de un sistema de motivación continua y la dificultad para ejecutar correctamente los ejercicios sin supervisión directa.

**d) Insuficiencia de monitoreo y seguimiento.** Los fisioterapeutas disponen de información limitada sobre el comportamiento terapéutico de sus pacientes entre consultas. Las métricas de progreso se recopilan de manera subjetiva, dependiendo del autorreporte del paciente, lo que introduce sesgos y dificulta la toma de decisiones clínicas informadas.

**e) Escasez de profesionales especializados.** México enfrenta un déficit estructural de fisioterapeutas, lo que genera tiempos de espera prolongados y limita la duración de las sesiones presenciales. La tecnología puede amplificar la capacidad de atención de cada profesional al permitir el monitoreo simultáneo de múltiples pacientes de forma remota.

## 4.2 Estudio de Factibilidad

### 4.2.1 Factibilidad Técnica

El desarrollo de RehabTech es técnicamente viable gracias a la madurez de las tecnologías seleccionadas:

- **Flutter 3.x** como framework de desarrollo multiplataforma permite generar aplicaciones nativas para Android e iOS desde una única base de código en Dart, reduciendo significativamente los tiempos de desarrollo y mantenimiento.
- **Firebase** proporciona una infraestructura serverless completa que incluye autenticación, base de datos en tiempo real (Firestore), almacenamiento de archivos, mensajería push y analítica, eliminando la necesidad de administrar servidores dedicados.
- **Google ML Kit Pose Detection** y **MediaPipe** ofrecen modelos de detección de pose optimizados para dispositivos móviles, capaces de procesar 30+ cuadros por segundo en hardware de gama media.
- **Google Gemini API** permite la implementación de un asistente virtual conversacional con capacidades de comprensión de lenguaje natural avanzadas.
- **TensorFlow Lite / MobileNet** posibilita la ejecución de modelos de aprendizaje automático directamente en el dispositivo, garantizando baja latencia y funcionamiento sin conexión a internet.

### 4.2.2 Factibilidad Operativa

El equipo de desarrollo está conformado por tres ingenieros de software con experiencia en desarrollo móvil, inteligencia artificial y sistemas en la nube. La metodología Kanban adoptada permite una gestión ágil del flujo de trabajo sin la rigidez de iteraciones fijas, facilitando la priorización dinámica de funcionalidades y la incorporación de retroalimentación de usuarios piloto.

### 4.2.3 Factibilidad Económica

El modelo de costos se sustenta en servicios con planes gratuitos o de bajo costo durante la fase de desarrollo, escalando proporcionalmente al crecimiento de la base de usuarios.

**Tabla 1.** Estimación de costos del proyecto RehabTech.

| Concepto                               | Costo Estimado (MXN)           | Periodicidad |
| -------------------------------------- | ------------------------------ | ------------ |
| Firebase (Plan Spark → Blaze)         | $0 – $2,000                   | Mensual      |
| Google Gemini API                      | $0 – $500                     | Mensual      |
| Cuenta Google Play Developer           | $500 (único)                  | Único       |
| Cuenta Apple Developer                 | $2,000                         | Anual        |
| Dominio web (rehabtech.app)            | $300                           | Anual        |
| Herramientas de diseño (Figma)        | $0 (plan gratuito)             | —           |
| Equipos de cómputo (3 laptops)        | $60,000                        | Único       |
| Dispositivos de prueba (3 smartphones) | $18,000                        | Único       |
| Servicios de nube adicionales (GCP)    | $0 – $1,500                   | Mensual      |
| **Total primer año (estimado)** | **$105,000 – $130,000** | —           |

## 4.3 Beneficios y Modelos de Negocio

RehabTech plantea un modelo de monetización diversificado que combina ingresos B2C y B2B:

**Tabla 2.** Modelos de negocio y beneficios proyectados.

| Modelo                                     | Descripción                                                                             | Precio Estimado                 | Beneficio Principal                      |
| ------------------------------------------ | ---------------------------------------------------------------------------------------- | ------------------------------- | ---------------------------------------- |
| **Freemium B2C**                     | Plan gratuito limitado (3 ejercicios/día, 5 mensajes con Nora) + Plan Premium ilimitado | $9.99 USD/mes o $79.99 USD/año | Democratizar acceso; conversión gradual |
| **Plan Familia**                     | Suscripción Premium para hasta 5 miembros                                               | $14.99 USD/mes                  | Ampliar mercado objetivo                 |
| **Licencia Clínica Pequeña (B2B)** | Hasta 50 pacientes, 3 fisioterapeutas, dashboard                                         | $99 USD/mes                     | Ingresos recurrentes estables            |
| **Licencia Clínica Mediana (B2B)**  | Hasta 200 pacientes, 10 fisioterapeutas, API                                             | $299 USD/mes                    | Integración con sistemas existentes     |
| **Licencia Hospital/Enterprise**     | Ilimitado, SSO, SLA, servidor dedicado                                                   | $999+ USD/mes                   | Contratos anuales de alto valor          |
| **Suscripción Terapeuta Pro**       | Perfil destacado, estadísticas avanzadas, videollamadas                                 | $29.99 USD/mes                  | Marketplace de profesionales             |
| **Contenido Premium**                | Programas especializados (post-quirúrgico, deportivo)                                   | $19.99 – $49.99 USD (único)   | Ingresos por contenido                   |
| **Kits de Hardware**                 | Bandas elásticas, sensores complementarios (futuro)                                     | $49.99 – $149.99 USD           | Diversificación de ingresos             |

**Tabla 3.** Proyección de ingresos — Escenario conservador (Año 1).

| Fuente            | Cantidad      | Precio                | Ingresos Anuales (USD) |
| ----------------- | ------------- | --------------------- | ---------------------- |
| Premium B2C       | 500 usuarios  | $79.99/año | $40,000 |                        |
| Clínicas B2B     | 5 clínicas   | $199/mes | $12,000    |                        |
| Terapeutas Pro    | 20 terapeutas | $29.99/mes | $7,200   |                        |
| Programas Premium | 200 ventas    | $29.99 c/u | $6,000   |                        |
| **Total**   |               |                       | **$65,200**      |

---

REHABTECH | LICENCIATURA EN INGENIERÍA DE SOFTWARE | PÁGINA | 4

---

# 5. DEFINICIÓN GENERAL DEL PROYECTO

## 5.1 Objetivo General

Diseñar, desarrollar e implementar una plataforma móvil inteligente de rehabilitación física que, mediante la integración de inteligencia artificial, visión por computadora y comunicación en tiempo real, permita a los pacientes realizar sesiones de terapia guiadas desde su hogar con retroalimentación personalizada, al mismo tiempo que proporcione a los fisioterapeutas herramientas de monitoreo remoto y generación automatizada de reportes clínicos.

## 5.2 Objetivos Específicos

1. **Implementar un sistema de detección de pose en tiempo real** que utilice la cámara del dispositivo móvil y los modelos ML Kit Pose Detection / MediaPipe para analizar la correcta ejecución de ejercicios terapéuticos, proporcionando retroalimentación visual y auditiva instantánea al paciente.
2. **Desarrollar un motor de adaptación dinámica de dificultad** basado en algoritmos de aprendizaje automático (TensorFlow Lite / MobileNet) que ajuste automáticamente la intensidad, duración y complejidad de las rutinas de rehabilitación según el progreso individual de cada paciente.
3. **Integrar un asistente virtual conversacional ("Nora")** alimentado por la API de Google Gemini, capaz de guiar ejercicios, resolver dudas sobre el tratamiento, proporcionar motivación personalizada y derivar al fisioterapeuta cuando se detecten situaciones que excedan sus capacidades.
4. **Diseñar e implementar un módulo de monitoreo remoto para fisioterapeutas** que incluya visualización de progreso detallado, historial de sesiones, métricas biomecánicas, calendario de citas y sistema de comunicación directa con sus pacientes.
5. **Construir un sistema automatizado de generación de reportes en PDF** que compile estadísticas de progreso, análisis de sesiones, observaciones clínicas y gráficos de evolución temporal, facilitando la documentación clínica y la toma de decisiones terapéuticas.
6. **Implementar un sistema integral de notificaciones inteligentes** mediante Firebase Cloud Messaging y notificaciones locales que incluya recordatorios de ejercicios, alertas de citas, motivación basada en rachas y comunicaciones del fisioterapeuta.
7. **Garantizar la seguridad y privacidad de los datos de salud** mediante la implementación de cifrado en tránsito (TLS 1.3) y en reposo (AES-256), reglas de acceso basadas en roles en Firestore, Firebase App Check y cumplimiento de la LFPDPPP.
8. **Validar la usabilidad y efectividad de la plataforma** mediante pruebas con usuarios reales, evaluación de la experiencia de usuario, medición de tasas de adherencia terapéutica y análisis de métricas de rendimiento del sistema.

## 5.3 Metodología de Desarrollo: Kanban

Para el desarrollo de RehabTech se adoptó la metodología **Kanban**, un enfoque ágil basado en la visualización del flujo de trabajo y la mejora continua. A continuación se describen las ocho razones fundamentales que motivaron esta elección:

1. **Visualización del flujo de trabajo.** Kanban utiliza un tablero visual (se implementó mediante GitHub Projects) que permite a todo el equipo observar en tiempo real el estado de cada tarea, identificando cuellos de botella y distribuyendo la carga de trabajo de manera equitativa.
2. **Ausencia de iteraciones fijas.** A diferencia de Scrum, Kanban no impone sprints con duración predefinida. Esto resulta ventajoso en un proyecto académico donde la disponibilidad de los integrantes es variable y las prioridades pueden cambiar según los avances de la investigación o la retroalimentación de asesores.
3. **Limitación del trabajo en progreso (WIP).** El principio de limitar el número de tareas simultáneas por desarrollador (WIP limit = 2) previene la sobrecarga cognitiva, reduce el *context switching* y asegura que las funcionalidades se completen antes de iniciar nuevas.
4. **Entrega continua de valor.** Kanban fomenta la entrega incremental de funcionalidades, lo que permitió contar con versiones funcionales de la aplicación desde etapas tempranas del desarrollo, facilitando las pruebas con usuarios y la retroalimentación iterativa.
5. **Flexibilidad ante cambios de prioridad.** En un proyecto que integra múltiples tecnologías emergentes (IA, visión por computadora, servicios en la nube), los descubrimientos técnicos frecuentemente redefinen las prioridades. Kanban permite repriorizar el backlog sin la fricción de replaneación de sprints.
6. **Métricas de flujo claras.** El uso de métricas como *lead time* (tiempo desde la solicitud hasta la entrega), *cycle time* (tiempo desde el inicio hasta la finalización) y *throughput* (tareas completadas por semana) permitió identificar ineficiencias y optimizar el proceso de desarrollo de forma cuantitativa.
7. **Integración natural con herramientas existentes.** GitHub Projects y GitHub Issues proporcionan soporte nativo para tableros Kanban con columnas configurables (Backlog, To Do, In Progress, Review, Done), etiquetas y automatizaciones, eliminando la necesidad de herramientas adicionales.
8. **Cultura de mejora continua.** Kanban promueve retrospectivas informales y ajustes incrementales al proceso de trabajo, lo que permitió al equipo refinar continuamente sus prácticas de desarrollo, revisión de código y despliegue a lo largo de todo el proyecto.

## 5.4 Cronograma de Actividades

El desarrollo de RehabTech se estructuró en cinco fases principales:

**Tabla 4.** Cronograma de actividades del proyecto.

| Fase                                            | Actividad                                                                                                                                        | Duración | Periodo               |
| ----------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ | --------- | --------------------- |
| **Fase 1: Investigación**                | Análisis de problemática, revisión de literatura, estudio de tecnologías, definición de requerimientos                                      | 4 semanas | Enero – Febrero 2025 |
| **Fase 2: Desarrollo de Software**        | Arquitectura del sistema, implementación de backend (Firebase), desarrollo de módulos principales (auth, CRUD, chat IA)                        | 8 semanas | Febrero – Abril 2025 |
| **Fase 3: Interfaz y Monitoreo**          | Diseño de interfaces (Material 3), implementación de dashboards, módulo de monitoreo para terapeutas, gráficos de progreso                   | 6 semanas | Abril – Mayo 2025    |
| **Fase 4: Pruebas**                       | Pruebas unitarias, de integración, de sistema, de rendimiento y con usuarios. Corrección de errores                                            | 4 semanas | Mayo – Junio 2025    |
| **Fase 5: Integración de Hardware e IA** | Integración de detección de pose con cámara, optimización de modelos de IA, adaptación dinámica de dificultad, generación de reportes PDF | 4 semanas | Junio – Julio 2025   |

*Figura 1.* Diagrama de Gantt del cronograma de actividades (representación textual).

```
Ene 2025 ──── Feb ──── Mar ──── Abr ──── May ──── Jun ──── Jul 2025
[████ Fase 1: Investigación       ]
            [████████████████ Fase 2: Desarrollo SW                ]
                                    [████████████ Fase 3: Interfaz y Monitoreo  ]
                                                    [████████ Fase 4: Pruebas        ]
                                                                [████████ Fase 5: IA+HW  ]
```

---

REHABTECH | LICENCIATURA EN INGENIERÍA DE SOFTWARE | PÁGINA | 5

---

# 6. ESPECIFICACIÓN DE REQUERIMIENTOS

## 6.1 Requerimientos Funcionales

**Tabla 5.** Requerimientos funcionales del sistema RehabTech.

| ID            | Requerimiento                             | Descripción                                                                                                                                                                                                                                                                                          | Prioridad |
| ------------- | ----------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- |
| **RF1** | Detección de movimientos en tiempo real  | El sistema debe utilizar la cámara del dispositivo móvil y modelos de ML Kit Pose Detection para detectar, rastrear y evaluar la postura corporal del paciente durante la ejecución de ejercicios terapéuticos, identificando 33 puntos de referencia anatómicos con una tasa mínima de 25 FPS. | Alta      |
| **RF2** | Personalización y adaptación de rutinas | El sistema debe adaptar automáticamente la dificultad, duración y número de repeticiones de los ejercicios basándose en el historial de rendimiento del paciente, utilizando algoritmos de aprendizaje automático para calcular la progresión óptima.                                          | Alta      |
| **RF3** | Registro y almacenamiento de sesiones     | El sistema debe registrar cada sesión de terapia incluyendo fecha, duración, ejercicios realizados, repeticiones completadas, puntuación de calidad del movimiento, métricas de IA y observaciones, almacenándolos en Cloud Firestore con sincronización en tiempo real.                        | Alta      |
| **RF4** | Generación automática de reportes       | El sistema debe generar reportes en formato PDF que compilen estadísticas de progreso, gráficos de evolución temporal (usando FL Chart), análisis comparativo entre sesiones, y observaciones clínicas, permitiendo su descarga y compartición.                                                 | Media     |
| **RF5** | Sistema de notificaciones inteligentes    | El sistema debe enviar notificaciones push (FCM) y locales para recordatorios de ejercicios, alertas de citas, mensajes del terapeuta, motivación por rachas y actualizaciones de progreso, con configuración personalizable de horarios y preferencias.                                            | Alta      |
| **RF6** | Monitoreo remoto para fisioterapeutas     | El sistema debe proporcionar a los fisioterapeutas un módulo completo para gestionar pacientes, visualizar su progreso detallado, asignar y modificar rutinas, programar citas, comunicarse directamente y recibir alertas sobre anomalías.                                                         | Alta      |
| **RF7** | Interfaz de usuario intuitiva y accesible | El sistema debe implementar una interfaz basada en Material 3 con soporte para temas claro/oscuro, efectos glassmorphism, navegación inferior diferenciada por rol (paciente/terapeuta), alto contraste, tamaños de fuente ajustables y compatibilidad con lectores de pantalla.                    | Media     |
| **RF8** | Asistente virtual interactivo (Nora)      | El sistema debe integrar un chatbot conversacional basado en Google Gemini que guíe al paciente durante los ejercicios, responda preguntas sobre rehabilitación, proporcione motivación personalizada, almacene el historial de conversaciones y derive al fisioterapeuta cuando sea necesario.    | Alta      |

## 6.2 Requerimientos No Funcionales

**Tabla 6.** Requerimientos no funcionales del sistema RehabTech.

| ID             | Requerimiento  | Descripción                                                                                                                                                                                                                                      | Métrica                                |
| -------------- | -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------- |
| **RNF1** | Rendimiento    | La detección de pose debe procesar un mínimo de 25 cuadros por segundo en dispositivos con procesador de gama media (Snapdragon 600 o equivalente) y 2 GB de RAM disponible.                                                                    | ≥ 25 FPS                               |
| **RNF2** | Latencia       | La latencia máxima entre la captura de movimiento y la retroalimentación visual/auditiva no debe superar los 200 milisegundos para garantizar una experiencia de interacción fluida.                                                           | ≤ 200 ms                               |
| **RNF3** | Escalabilidad  | La arquitectura serverless (Firebase) debe soportar desde 10 hasta 100,000 usuarios concurrentes sin degradación significativa del servicio, escalando automáticamente los recursos.                                                            | 100,000 usuarios concurrentes           |
| **RNF4** | Seguridad      | Todos los datos en tránsito deben cifrarse con TLS 1.2+ y los datos en reposo con AES-256. El acceso a datos sensibles debe controlarse mediante reglas de Firestore basadas en roles (RBAC) y Firebase App Check.                               | Cumplimiento LFPDPPP, OWASP MASVS L1/L2 |
| **RNF5** | Disponibilidad | El sistema debe garantizar una disponibilidad mínima del 99.5% mensual, respaldada por los SLA de Firebase/Google Cloud Platform.                                                                                                                | ≥ 99.5% uptime                         |
| **RNF6** | Compatibilidad | La aplicación debe funcionar correctamente en dispositivos Android 8.0 (API 26) o superior, con soporte planificado para iOS 14+. Debe soportar resoluciones desde 720p hasta 2K.                                                                | Android 8.0+, iOS 14+                   |
| **RNF7** | Mantenibilidad | El código fuente debe seguir las guías de estilo oficiales de Dart/Flutter, con una puntuación de cero issues en `flutter analyze`, documentación modular y arquitectura en capas que facilite la incorporación de nuevas funcionalidades. | 0 issues en `flutter analyze`         |

## 6.3 Técnicas de Obtención de Requerimientos

La especificación de requerimientos se realizó mediante un proceso iterativo que combinó múltiples técnicas:

1. **Entrevistas semiestructuradas con fisioterapeutas.** Se realizaron entrevistas con fisioterapeutas en activo para comprender sus flujos de trabajo, las limitaciones de los métodos tradicionales de seguimiento, las métricas clínicas relevantes para evaluar el progreso de los pacientes y las funcionalidades que considerarían más valiosas en una herramienta digital de apoyo.
2. **Revisión de literatura científica.** Se analizaron publicaciones recientes sobre el uso de inteligencia artificial en rehabilitación, sistemas de detección de pose para aplicaciones médicas y factores que influyen en la adherencia terapéutica.
3. **Análisis de aplicaciones existentes.** Se evaluaron plataformas comerciales de rehabilitación digital (Kaia Health, Hinge Health, SWORD Health) para identificar funcionalidades estándar, brechas de mercado y oportunidades de diferenciación.
4. **Prototipado iterativo y validación.** Se desarrollaron prototipos de baja fidelidad que fueron presentados a potenciales usuarios (pacientes y terapeutas) para recabar retroalimentación temprana e incorporarla en los requerimientos formales.

---

REHABTECH | LICENCIATURA EN INGENIERÍA DE SOFTWARE | PÁGINA | 6

---

# 7. DISEÑO DEL MODELO DE DATOS

## 7.1 Diagrama Entidad-Relación

El modelo de datos de RehabTech se diseñó para capturar la complejidad de las relaciones entre pacientes, terapeutas, ejercicios, sesiones y la inteligencia artificial. A continuación se describe el diagrama entidad-relación y las entidades que lo componen.

*Figura 2.* Diagrama Entidad-Relación del sistema RehabTech (descripción textual).

```
┌──────────┐    1:N    ┌──────────────┐    N:1    ┌───────────┐
│ Clinica  │───────────│Terapeuta_    │───────────│ Terapeuta │
│          │           │Clinica       │           │           │
└──────────┘           └──────────────┘           └─────┬─────┘
                                                        │ 1:N
                                                        │
┌──────────┐   1:1    ┌──────────┐    N:1         ┌─────┴─────┐
│Historial │──────────│ Paciente │────────────────│  Usuario  │
│_Clinico  │          │          │                │           │
└──────────┘          └────┬─────┘                └─────┬─────┘
                           │ 1:N                        │ 1:N
                     ┌─────┴─────┐              ┌───────┴───────┐
                     │Asignacion_│              │   Bitacora_   │
                     │Rutina     │              │   Actividad   │
                     └─────┬─────┘              └───────────────┘
                           │ N:1
                     ┌─────┴─────┐    1:N    ┌──────────────┐
                     │  Rutina   │───────────│Rutina_       │
                     │           │           │Ejercicio     │
                     └─────┬─────┘           └──────┬───────┘
                           │                        │ N:1
                     ┌─────┴─────┐           ┌──────┴───────┐
                     │  Sesion   │           │  Ejercicio   │
                     │           │           │              │
                     └─────┬─────┘           └──────────────┘
                           │ 1:N
                     ┌─────┴─────────┐
                     │Sesion_        │    1:1    ┌──────────────┐
                     │Ejercicio      │───────────│ Analisis_IA  │
                     └───────────────┘           └──────────────┘
```

Adicionalmente, las entidades transversales incluyen:

```
┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│Plan_         │  │    Cita      │  │    Pago      │  │Notificacion  │
│Suscripcion   │  │              │  │              │  │              │
└──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘

┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│Chat_Mensaje  │  │Administrador │  │  Feedback    │
│              │  │              │  │              │
└──────────────┘  └──────────────┘  └──────────────┘
```

## 7.2 Tipos de Datos de cada Entidad

A continuación se detallan las 20 entidades principales del modelo de datos con sus atributos y tipos:

**Tabla 7.** Entidad: Usuario.

| Atributo       | Tipo         | Descripción                                    | Restricciones                   |
| -------------- | ------------ | ----------------------------------------------- | ------------------------------- |
| id_usuario     | string (UID) | Identificador único generado por Firebase Auth | PK, auto-generado               |
| nombre         | string       | Nombre(s) del usuario                           | NOT NULL, max 100 chars         |
| apellidos      | string       | Apellidos del usuario                           | NOT NULL, max 100 chars         |
| email          | string       | Correo electrónico                             | UNIQUE, NOT NULL, formato email |
| tipo_usuario   | enum         | Tipo de cuenta: "patient", "therapist", "admin" | NOT NULL                        |
| foto_url       | string       | URL de la foto de perfil en Firebase Storage    | Nullable                        |
| telefono       | string       | Número telefónico                             | Nullable, formato E.164         |
| fecha_creacion | timestamp    | Fecha y hora de registro                        | NOT NULL, auto-generado         |

**Tabla 8.** Entidad: Paciente.

| Atributo         | Tipo                | Descripción                        | Restricciones             |
| ---------------- | ------------------- | ----------------------------------- | ------------------------- |
| id_paciente      | string (6 dígitos) | Código único del paciente         | PK, UNIQUE                |
| id_usuario       | string (UID)        | Referencia al usuario               | FK → Usuario             |
| id_terapeuta     | string (UID)        | Terapeuta asignado                  | FK → Terapeuta, Nullable |
| fecha_nacimiento | date                | Fecha de nacimiento                 | Nullable                  |
| condicion_medica | string              | Diagnóstico o condición principal | Nullable, max 500 chars   |
| nivel_actividad  | enum                | "bajo", "medio", "alto"             | Default: "medio"          |

**Tabla 9.** Entidad: Terapeuta.

| Atributo              | Tipo         | Descripción                        | Restricciones           |
| --------------------- | ------------ | ----------------------------------- | ----------------------- |
| id_terapeuta          | string (UID) | Identificador del terapeuta         | PK, FK → Usuario       |
| especialidad          | string       | Área de especialización           | Nullable, max 200 chars |
| cedula_profesional    | string       | Número de cédula profesional      | Nullable                |
| años_experiencia     | integer      | Años de experiencia clínica       | Nullable, ≥ 0          |
| calificacion_promedio | float        | Calificación promedio de pacientes | Nullable, 0.0–5.0      |

**Tabla 10.** Entidad: Administrador.

| Atributo      | Tipo         | Descripción                        | Restricciones     |
| ------------- | ------------ | ----------------------------------- | ----------------- |
| id_admin      | string (UID) | Identificador del administrador     | PK, FK → Usuario |
| nivel_acceso  | enum         | "super_admin", "admin", "moderador" | NOT NULL          |
| ultimo_acceso | timestamp    | Última vez que accedió al panel   | Auto-generado     |

**Tabla 11.** Entidad: Clínica.

| Atributo         | Tipo   | Descripción                        | Restricciones           |
| ---------------- | ------ | ----------------------------------- | ----------------------- |
| id_clinica       | string | Identificador único de la clínica | PK                      |
| nombre           | string | Nombre de la clínica o centro      | NOT NULL, max 200 chars |
| direccion        | string | Dirección física                  | NOT NULL                |
| telefono         | string | Teléfono de contacto               | NOT NULL                |
| email            | string | Correo de contacto                  | NOT NULL                |
| plan_suscripcion | string | Plan contratado                     | FK → Plan_Suscripcion  |

**Tabla 12.** Entidad: Terapeuta_Clínica (tabla pivote).

| Atributo          | Tipo      | Descripción                            | Restricciones   |
| ----------------- | --------- | --------------------------------------- | --------------- |
| id_terapeuta      | string    | Referencia al terapeuta                 | FK → Terapeuta |
| id_clinica        | string    | Referencia a la clínica                | FK → Clínica  |
| fecha_vinculacion | timestamp | Fecha de inicio de la relación laboral | NOT NULL        |
| rol_en_clinica    | enum      | "titular", "asociado", "temporal"       | NOT NULL        |

**Tabla 13.** Entidad: Ejercicio.

| Atributo          | Tipo              | Descripción                                                    | Restricciones            |
| ----------------- | ----------------- | --------------------------------------------------------------- | ------------------------ |
| id_ejercicio      | string            | Identificador único                                            | PK                       |
| nombre            | string            | Nombre del ejercicio                                            | NOT NULL, max 150 chars  |
| descripcion       | string            | Descripción detallada e instrucciones                          | NOT NULL, max 2000 chars |
| categoria         | string            | Categoría: "movilidad", "fuerza", "equilibrio", "flexibilidad" | NOT NULL                 |
| dificultad        | enum              | "beginner", "intermediate", "advanced"                          | NOT NULL                 |
| video_url         | string            | URL del video demostrativo                                      | Nullable                 |
| imagen_url        | string            | URL de la imagen ilustrativa                                    | Nullable                 |
| musculos_objetivo | array`<string>` | Grupos musculares involucrados                                  | NOT NULL                 |
| duracion_estimada | integer           | Duración estimada en segundos                                  | NOT NULL, > 0            |

**Tabla 14.** Entidad: Rutina.

| Atributo       | Tipo      | Descripción                            | Restricciones            |
| -------------- | --------- | --------------------------------------- | ------------------------ |
| id_rutina      | string    | Identificador único                    | PK                       |
| nombre         | string    | Nombre de la rutina                     | NOT NULL, max 150 chars  |
| descripcion    | string    | Descripción de la rutina               | Nullable, max 500 chars  |
| id_terapeuta   | string    | Terapeuta que la creó                  | FK → Terapeuta          |
| id_paciente    | string    | Paciente asignado (si es personalizada) | FK → Paciente, Nullable |
| fecha_creacion | timestamp | Fecha de creación                      | Auto-generado            |
| activa         | boolean   | Si la rutina está activa               | Default: true            |

**Tabla 15.** Entidad: Rutina_Ejercicio (tabla pivote).

| Atributo            | Tipo    | Descripción                    | Restricciones   |
| ------------------- | ------- | ------------------------------- | --------------- |
| id_rutina           | string  | Referencia a la rutina          | FK → Rutina    |
| id_ejercicio        | string  | Referencia al ejercicio         | FK → Ejercicio |
| orden               | integer | Posición en la secuencia       | NOT NULL, ≥ 1  |
| repeticiones        | integer | Número de repeticiones         | NOT NULL, > 0   |
| series              | integer | Número de series               | NOT NULL, > 0   |
| duracion_segundos   | integer | Duración por ejercicio         | NOT NULL, > 0   |
| instrucciones_extra | string  | Notas adicionales del terapeuta | Nullable        |

**Tabla 16.** Entidad: Asignación_Rutina.

| Atributo         | Tipo      | Descripción                        | Restricciones     |
| ---------------- | --------- | ----------------------------------- | ----------------- |
| id_asignacion    | string    | Identificador único                | PK                |
| id_rutina        | string    | Rutina asignada                     | FK → Rutina      |
| id_paciente      | string    | Paciente destinatario               | FK → Paciente    |
| id_terapeuta     | string    | Terapeuta que asigna                | FK → Terapeuta   |
| fecha_asignacion | timestamp | Fecha de asignación                | Auto-generado     |
| fecha_inicio     | date      | Fecha de inicio de la rutina        | NOT NULL          |
| fecha_fin        | date      | Fecha de finalización estimada     | Nullable          |
| estado           | enum      | "activa", "completada", "cancelada" | Default: "activa" |

**Tabla 17.** Entidad: Sesión.

| Atributo               | Tipo      | Descripción                              | Restricciones  |
| ---------------------- | --------- | ----------------------------------------- | -------------- |
| id_sesion              | string    | Identificador único                      | PK             |
| id_paciente            | string    | Paciente que realizó la sesión          | FK → Paciente |
| id_rutina              | string    | Rutina ejecutada                          | FK → Rutina   |
| fecha_hora_inicio      | timestamp | Inicio de la sesión                      | NOT NULL       |
| fecha_hora_fin         | timestamp | Fin de la sesión                         | Nullable       |
| duracion_total         | integer   | Duración en segundos                     | Calculado      |
| ejercicios_completados | integer   | Número de ejercicios completados         | NOT NULL, ≥ 0 |
| ejercicios_totales     | integer   | Total de ejercicios en la rutina          | NOT NULL, > 0  |
| puntuacion_general     | float     | Puntuación de calidad (0–100)           | Nullable       |
| estado                 | enum      | "en_progreso", "completada", "abandonada" | NOT NULL       |

**Tabla 18.** Entidad: Sesión_Ejercicio.

| Atributo                 | Tipo    | Descripción                      | Restricciones   |
| ------------------------ | ------- | --------------------------------- | --------------- |
| id_sesion_ejercicio      | string  | Identificador único              | PK              |
| id_sesion                | string  | Referencia a la sesión           | FK → Sesión   |
| id_ejercicio             | string  | Ejercicio realizado               | FK → Ejercicio |
| repeticiones_completadas | integer | Reps realizadas                   | NOT NULL, ≥ 0  |
| duracion_real            | integer | Tiempo real en segundos           | NOT NULL        |
| puntuacion_forma         | float   | Calidad de la ejecución (0–100) | Nullable        |
| observaciones_ia         | string  | Observaciones generadas por la IA | Nullable        |

**Tabla 19.** Entidad: Análisis_IA.

| Atributo                | Tipo               | Descripción                          | Restricciones           |
| ----------------------- | ------------------ | ------------------------------------- | ----------------------- |
| id_analisis             | string             | Identificador único                  | PK                      |
| id_sesion_ejercicio     | string             | Sesión-ejercicio analizada           | FK → Sesión_Ejercicio |
| modelo_utilizado        | string             | Nombre y versión del modelo de IA    | NOT NULL                |
| puntos_clave_detectados | integer            | Número de keypoints detectados       | NOT NULL                |
| angulos_evaluados       | map<string, float> | Ángulos articulares medidos (grados) | NOT NULL                |
| precision_deteccion     | float              | Confianza promedio del modelo (0–1)  | NOT NULL                |
| recomendaciones         | array`<string>`  | Sugerencias generadas por la IA       | Nullable                |
| timestamp               | timestamp          | Momento del análisis                 | Auto-generado           |

**Tabla 20.** Entidad: Historial_Clínico.

| Atributo                 | Tipo              | Descripción                | Restricciones            |
| ------------------------ | ----------------- | --------------------------- | ------------------------ |
| id_historial             | string            | Identificador único        | PK                       |
| id_paciente              | string            | Paciente propietario        | FK → Paciente, UNIQUE   |
| diagnostico_principal    | string            | Diagnóstico médico        | NOT NULL                 |
| diagnosticos_secundarios | array`<string>` | Comorbilidades              | Nullable                 |
| medicamentos             | array`<string>` | Medicación actual          | Nullable                 |
| alergias                 | array`<string>` | Alergias conocidas          | Nullable                 |
| notas_clinicas           | string            | Observaciones del terapeuta | Nullable, max 5000 chars |
| ultima_actualizacion     | timestamp         | Última modificación       | Auto-generado            |

**Tabla 21.** Entidad: Plan_Suscripción.

| Atributo        | Tipo              | Descripción                             | Restricciones  |
| --------------- | ----------------- | ---------------------------------------- | -------------- |
| id_plan         | string            | Identificador del plan                   | PK             |
| nombre          | string            | "Free", "Premium", "Familia", "Clínica" | NOT NULL       |
| precio_mensual  | float             | Precio en USD                            | NOT NULL, ≥ 0 |
| precio_anual    | float             | Precio anual con descuento               | Nullable       |
| max_pacientes   | integer           | Límite de pacientes (-1 = ilimitado)    | NOT NULL       |
| max_terapeutas  | integer           | Límite de terapeutas                    | NOT NULL       |
| funcionalidades | array`<string>` | Lista de features incluidas              | NOT NULL       |

**Tabla 22.** Entidad: Cita.

| Atributo         | Tipo      | Descripción                          | Restricciones            |
| ---------------- | --------- | ------------------------------------- | ------------------------ |
| id_cita          | string    | Identificador único                  | PK                       |
| id_terapeuta     | string    | Terapeuta responsable                 | FK → Terapeuta          |
| id_paciente      | string    | Paciente citado                       | FK → Paciente           |
| fecha_hora       | timestamp | Fecha y hora de la cita               | NOT NULL                 |
| estado           | enum      | "scheduled", "completed", "cancelled" | Default: "scheduled"     |
| tipo             | enum      | "presencial", "virtual"               | NOT NULL                 |
| notas            | string    | Notas de la cita                      | Nullable, max 2000 chars |
| duracion_minutos | integer   | Duración estimada                    | Default: 30              |

**Tabla 23.** Entidad: Pago.

| Atributo    | Tipo      | Descripción                                        | Restricciones           |
| ----------- | --------- | --------------------------------------------------- | ----------------------- |
| id_pago     | string    | Identificador único                                | PK                      |
| id_usuario  | string    | Usuario que paga                                    | FK → Usuario           |
| id_plan     | string    | Plan adquirido                                      | FK → Plan_Suscripción |
| monto       | float     | Monto cobrado                                       | NOT NULL, > 0           |
| moneda      | string    | "MXN", "USD"                                        | NOT NULL                |
| metodo_pago | string    | "tarjeta", "paypal", "in_app_purchase"              | NOT NULL                |
| estado      | enum      | "pendiente", "completado", "fallido", "reembolsado" | NOT NULL                |
| fecha_pago  | timestamp | Fecha de la transacción                            | Auto-generado           |

**Tabla 24.** Entidad: Notificación.

| Atributo        | Tipo      | Descripción                                          | Restricciones           |
| --------------- | --------- | ----------------------------------------------------- | ----------------------- |
| id_notificacion | string    | Identificador único                                  | PK                      |
| id_usuario      | string    | Destinatario                                          | FK → Usuario           |
| titulo          | string    | Título de la notificación                           | NOT NULL, max 100 chars |
| cuerpo          | string    | Contenido del mensaje                                 | NOT NULL, max 500 chars |
| tipo            | enum      | "recordatorio", "cita", "mensaje", "logro", "sistema" | NOT NULL                |
| leida           | boolean   | Si ha sido leída                                     | Default: false          |
| fecha_envio     | timestamp | Fecha de envío                                       | Auto-generado           |

**Tabla 25.** Entidad: Chat_Mensaje.

| Atributo        | Tipo      | Descripción                                        | Restricciones            |
| --------------- | --------- | --------------------------------------------------- | ------------------------ |
| id_mensaje      | string    | Identificador único                                | PK                       |
| id_conversacion | string    | Referencia a la conversación                       | NOT NULL                 |
| id_emisor       | string    | Usuario que envía                                  | FK → Usuario            |
| texto           | string    | Contenido del mensaje                               | NOT NULL, max 5000 chars |
| autor           | enum      | "user", "nora" (para chat IA) o UID (para chat P2P) | NOT NULL                 |
| leido           | boolean   | Estado de lectura                                   | Default: false           |
| timestamp       | timestamp | Momento de envío                                   | Auto-generado            |

**Tabla 26.** Entidad: Bitácora_Actividad.

| Atributo    | Tipo                 | Descripción                                                 | Restricciones |
| ----------- | -------------------- | ------------------------------------------------------------ | ------------- |
| id_registro | string               | Identificador único                                         | PK            |
| id_usuario  | string               | Usuario que realizó la acción                              | FK → Usuario |
| accion      | string               | Descripción de la acción (login, exercise_completed, etc.) | NOT NULL      |
| detalles    | map<string, dynamic> | Datos adicionales de la acción                              | Nullable      |
| ip_origen   | string               | Dirección IP (para auditoría)                              | Nullable      |
| timestamp   | timestamp            | Momento de la acción                                        | Auto-generado |

---

REHABTECH | LICENCIATURA EN INGENIERÍA DE SOFTWARE | PÁGINA | 7

---

# 8. DESCRIPCIÓN DE PROCESOS Y SERVICIOS

## 8.1 Servicios del Sistema

El sistema RehabTech expone ocho servicios principales que encapsulan la lógica de dominio y proporcionan funcionalidades especializadas a los módulos de la capa de presentación:

### Servicio 1: Guía Personalizada de Ejercicios

Este servicio gestiona la presentación secuencial de ejercicios dentro de una rutina asignada. Incluye instrucciones paso a paso, demostraciones en video, contador de repeticiones con temporizador (*CountdownScreen*) y adaptación del ritmo según el nivel del paciente. El servicio se coordina con el módulo de detección de pose para sincronizar la retroalimentación visual con la ejecución del movimiento.

### Servicio 2: Detección de Movimientos (*Pose Detection Service*)

Implementado en `pose_detection_service.dart`, este servicio encapsula la lógica de integración con Google ML Kit Pose Detection. Captura el flujo de video de la cámara en tiempo real, procesa cada cuadro para extraer los 33 puntos de referencia anatómicos (keypoints), calcula ángulos articulares relevantes para cada ejercicio y evalúa la calidad de la ejecución comparándola con rangos de movimiento óptimos predefinidos. El servicio opera de forma local (on-device) sin necesidad de conexión a internet.

### Servicio 3: Retroalimentación en Tiempo Real

Basándose en los datos del Servicio 2, este módulo proporciona retroalimentación inmediata al paciente mediante indicadores visuales superpuestos en la imagen de la cámara (esqueleto de pose con código de color: verde = correcto, amarillo = ajustar, rojo = incorrecto), mensajes de texto orientativos y señales auditivas. La latencia objetivo entre la detección y la retroalimentación es inferior a 200 ms.

### Servicio 4: Adaptación Automática de Dificultad

El motor de adaptación dinámica analiza el historial de sesiones del paciente para calcular la progresión óptima. Utiliza métricas como la puntuación promedio de calidad, la tasa de completitud de ejercicios, la consistencia temporal y los patrones de fatiga para ajustar automáticamente el número de repeticiones, las series, la duración y la dificultad de los ejercicios en sesiones subsecuentes. El algoritmo se implementa con TensorFlow Lite para inferencia en el dispositivo.

### Servicio 5: Monitoreo Remoto para Fisioterapeutas

Implementado a través del módulo terapeuta (`therapist/`), este servicio proporciona un dashboard integral que incluye: listado de pacientes asignados con indicadores de estado (*PatientsScreen*), detalle de progreso por paciente (*PatientDetailScreen*), gestión de rutinas (*RoutinesScreen*), calendario de citas (*CalendarScreen*) y alertas automáticas cuando un paciente muestra anomalías en su adherencia o rendimiento.

### Servicio 6: Generación de Reportes (*PDF Service*)

Implementado en `pdf_service.dart`, este servicio genera documentos PDF completos que incluyen información del paciente, resumen de progreso semanal/mensual, gráficos de evolución (generados con FL Chart y renderizados como imágenes), detalle de sesiones individuales, observaciones clínicas del terapeuta y recomendaciones del sistema de IA. Los PDFs pueden descargarse al dispositivo o compartirse directamente mediante `share_plus`.

### Servicio 7: Sistema de Alertas y Notificaciones

Implementado en `notification_service.dart`, este servicio gestiona tres canales de notificación: (a) notificaciones push remotas vía Firebase Cloud Messaging para mensajes del terapeuta y alertas del sistema; (b) notificaciones locales programadas para recordatorios diarios de ejercicios con horario configurable; y (c) notificaciones in-app para actualizaciones en tiempo real. El servicio incluye gestión de tokens FCM, suscripción a topics por rol y configuración personalizable.

### Servicio 8: Seguridad y Control de Acceso

Este servicio transversal implementa múltiples capas de seguridad: (a) autenticación mediante Firebase Auth con soporte para email/contraseña y Google Sign-In; (b) autorización basada en roles a nivel de Firestore Rules con funciones `isOwner()`, `isTherapist()`, `isAssignedTherapist()` y `onlyUpdatesFields()`; (c) verificación de integridad de la aplicación mediante Firebase App Check con Play Integrity para Android; (d) cifrado automático en tránsito (TLS) y en reposo (AES-256) proporcionado por Firebase; y (e) manejo centralizado de errores mediante `ErrorHandler`.

## 8.2 Procesos del Sistema

### Proceso 1: Registro de Usuarios

1. El usuario selecciona el tipo de cuenta (paciente o terapeuta) en la pantalla de registro (`register_screen.dart`).
2. Ingresa nombre, apellidos, email y contraseña.
3. El sistema valida los datos de entrada (formato de email, fortaleza de contraseña).
4. Se crea la cuenta en Firebase Auth.
5. Se genera un documento en la colección `users/{uid}` de Firestore con los datos del perfil.
6. Si es paciente, se genera un `patientId` único de 6 dígitos.
7. Se envía un correo de verificación de email.
8. Se registra el token FCM para notificaciones.
9. Se redirige al usuario a su dashboard correspondiente según el rol.

### Proceso 2: Asignación de Rutinas

1. El fisioterapeuta accede al módulo de rutinas (*RoutinesScreen*).
2. Crea una nueva rutina especificando nombre, descripción y ejercicios (seleccionados del catálogo global).
3. Para cada ejercicio configura: repeticiones, series, duración e instrucciones específicas.
4. Selecciona el paciente destinatario.
5. El sistema guarda la rutina en Firestore y crea la relación de asignación.
6. Se envía una notificación al paciente informando la nueva rutina.
7. La rutina aparece en el dashboard del paciente para su ejecución.

### Proceso 3: Inicio de Sesión de Ejercicio

1. El paciente selecciona una rutina asignada desde su dashboard (*HomeScreen* / *ExercisesScreen*).
2. Visualiza los ejercicios de la rutina y selecciona uno para ejecutar (*ExerciseDetailScreen*).
3. Se presenta una cuenta regresiva de preparación (*CountdownScreen*).
4. Se activa la cámara del dispositivo y el servicio de detección de pose.
5. Se inicia la sesión de terapia (*TherapySessionScreen*) con retroalimentación en tiempo real.
6. Al completar o abandonar, se genera el reporte de sesión (*SessionReportScreen*).

### Proceso 4: Análisis en Tiempo Real

1. La cámara captura cuadros de video a 30 FPS.
2. Cada cuadro se procesa mediante ML Kit Pose Detection para extraer keypoints.
3. El servicio de pose calcula ángulos articulares relevantes para el ejercicio actual.
4. Los ángulos se comparan con rangos de referencia para evaluar la calidad.
5. Se genera retroalimentación visual (esqueleto superpuesto) y textual.
6. Las métricas se acumulan para el cálculo de la puntuación final de la sesión.

### Proceso 5: Adaptación Dinámica de Dificultad

1. Al completar una sesión, el sistema analiza las métricas recopiladas.
2. Se evalúan indicadores de rendimiento: puntuación de forma, tasa de finalización, duración real vs. esperada.
3. El algoritmo de ML compara el rendimiento actual con el historial del paciente.
4. Se calcula un nuevo nivel de dificultad para la próxima sesión.
5. Los parámetros de la rutina (repeticiones, series, duración) se ajustan automáticamente.
6. El terapeuta recibe una notificación si los ajustes son significativos.

### Proceso 6: Monitoreo y Generación de Reportes

1. El sistema recopila datos de progreso de forma continua en `users/{userId}/progress/`.
2. El servicio de progreso (`progress_service.dart`) calcula métricas agregadas: ejercicios completados, tiempo total, evolución semanal y mensual.
3. Los datos se visualizan en gráficos interactivos (FL Chart) en la pantalla de progreso del paciente (*ProgressScreen*) y del terapeuta (*PatientDetailScreen*).
4. El servicio PDF genera reportes bajo demanda o de forma programada.
5. Los reportes se almacenan en Firebase Storage y se comparten según las preferencias del usuario.

### Proceso 7: Actualización del Historial Clínico

1. Tras cada sesión completada, se actualizan los registros de progreso del paciente.
2. Las observaciones de la IA se almacenan asociadas a la sesión.
3. El terapeuta puede agregar notas clínicas manuales a través del detalle del paciente.
4. Los cambios en medicación, diagnóstico o tratamiento se registran con timestamp para traza de auditoría.
5. El historial está disponible para consulta en cualquier momento, protegido por reglas de acceso basadas en roles.

---

REHABTECH | LICENCIATURA EN INGENIERÍA DE SOFTWARE | PÁGINA | 8

---

# 9. DISEÑO DE INTERFACES

El diseño de interfaces de RehabTech sigue los principios de Material 3, con un sistema de diseño coherente que emplea una paleta cromática basada en tonos índigo (#6366F1) y azul (#3B82F6), efectos glassmorphism (fondos translúcidos con desenfoque), esquinas redondeadas de 16px, tipografía Google Fonts y la familia de iconos Lucide Icons para una experiencia visual moderna y profesional.

## 9.1 Pantalla de Login (*LoginScreen*)

La pantalla de inicio de sesión presenta el logotipo de RehabTech sobre un gradiente suave de tonos azul claro a verde claro. Incluye campos de texto para email y contraseña con validación en tiempo real, botón principal de inicio de sesión con efecto de carga, enlace a "¿Olvidaste tu contraseña?" que redirige a *ForgotPasswordScreen*, botón de registro para nuevos usuarios y opción de inicio de sesión con Google Sign-In.

## 9.2 Pantalla de Registro (*RegisterScreen*)

Presenta un formulario secuencial con campos para nombre, apellidos, email, contraseña y confirmación de contraseña. Incluye un selector del tipo de usuario (paciente o terapeuta) con tarjetas visuales descriptivas. Los campos de contraseña incorporan un indicador visual de fortaleza. Al completar el registro se muestra retroalimentación de éxito y redirección automática.

## 9.3 Dashboard del Paciente (*HomeScreen + MainNavScreen*)

El dashboard del paciente es la pantalla principal tras el inicio de sesión. Presenta una barra de navegación inferior con cinco secciones: Inicio, Ejercicios, Mensajes, Progreso y Perfil. La pantalla de inicio muestra un saludo personalizado con el nombre del paciente, un resumen del progreso del día (ejercicios completados / total), la rutina activa con acceso rápido a los ejercicios, un botón destacado para iniciar sesión de terapia y tarjetas de acceso rápido al chat con Nora y al chat con el terapeuta.

## 9.4 Dashboard del Terapeuta (*TherapistMainNavScreen*)

El módulo del terapeuta presenta una barra de navegación inferior con cuatro secciones: Pacientes, Rutinas, Calendario y Perfil. La pantalla principal (*PatientsScreen*) muestra un listado de todos los pacientes asignados con indicadores de estado (activo, inactivo, en sesión), barra de búsqueda y filtros por condición médica o nivel de actividad. Cada tarjeta de paciente muestra nombre, foto, última sesión y porcentaje de adherencia.

## 9.5 Pantalla de Rutinas y Ejercicios (*ExercisesScreen + ExerciseDetailScreen*)

La lista de ejercicios presenta tarjetas (*ExerciseCard*) con imagen o ícono representativo, nombre, categoría, dificultad (badge de color), duración estimada y número de series/repeticiones. Al seleccionar un ejercicio, *ExerciseDetailScreen* muestra la descripción completa, instrucciones paso a paso, video demostrativo (si disponible), músculos objetivo y un botón prominente para iniciar la sesión.

## 9.6 Pantalla de Control de Pacientes (*PatientDetailScreen*)

Esta pantalla proporciona al terapeuta una visión integral de cada paciente: información personal, condición médica, terapeuta asignado, historial de sesiones con gráficos de progreso (FL Chart), rutinas activas con opción de edición, citas programadas e historial de comunicaciones. Incluye botones de acción para asignar nueva rutina, programar cita y enviar mensaje.

## 9.7 Pantalla de Progreso (*ProgressScreen*)

Muestra gráficos interactivos de evolución temporal del paciente: gráfico de líneas con progreso semanal/mensual, gráfico de barras con ejercicios completados por día, indicador circular de adherencia general y métricas numéricas (racha actual, mejor racha, tiempo total de terapia). Permite filtrar por periodo (semana, mes, trimestre, año).

## 9.8 Pantalla de Reportes (*SessionReportScreen + PDF Service*)

La pantalla de reporte de sesión muestra un resumen inmediato tras completar un ejercicio: puntuación de calidad, tiempo empleado, repeticiones completadas, observaciones de la IA y comparación con la sesión anterior. Incluye botón para generar y descargar reporte PDF completo.

## 9.9 Pantalla de Calendario (*CalendarScreen*)

Disponible en el módulo del terapeuta, presenta un calendario mensual interactivo con marcadores visuales para citas programadas, codificadas por color según estado (programada = azul, completada = verde, cancelada = rojo). Al seleccionar un día se despliega la lista de citas con detalle y opciones de gestión.

## 9.10 Pantallas de Perfil (*ProfileScreen + TherapistProfileScreen*)

La pantalla de perfil presenta la foto del usuario, nombre, datos de contacto y opciones de configuración organizadas en secciones: edición de perfil (*EditProfileScreen*), seguridad y contraseña (*SecurityScreen*), configuración de notificaciones (*NotificationsScreen*), mi terapeuta (*MyTherapistScreen*, solo pacientes), política de privacidad (*PrivacyPolicyScreen*), accesibilidad (*HighContrastScreen*, *TextSizeScreen*), centro de ayuda (*HelpCenterScreen*) y cerrar sesión.

---

REHABTECH | LICENCIATURA EN INGENIERÍA DE SOFTWARE | PÁGINA | 9

---

# 10. HERRAMIENTAS UTILIZADAS

## 10.1 Lenguajes de Programación

**Tabla 27.** Lenguajes de programación utilizados en el proyecto.

| Lenguaje             | Versión         | Uso en el Proyecto                                                                    | Justificación                                                                                                                                          |
| -------------------- | ---------------- | ------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Dart**       | 3.x (SDK ^3.9.0) | Desarrollo de la aplicación móvil completa (UI, lógica de negocio, servicios)      | Lenguaje nativo de Flutter; tipado fuerte, compilación AOT para rendimiento nativo; soporte para programación asíncrona con async/await; null safety |
| **Python**     | 3.10+            | Entrenamiento de modelos de IA, procesamiento de datasets, scripts de automatización | Ecosistema líder en IA/ML (TensorFlow, PyTorch, scikit-learn, OpenCV); prototipado rápido; amplia comunidad y documentación                          |
| **Kotlin**     | 1.9+             | Configuración nativa de Android (build.gradle.kts, AndroidManifest.xml)              | Lenguaje oficial de Android; interoperabilidad con Java; utilizado en la configuración de Gradle y módulos nativos                                    |
| **JavaScript** | ES6+             | Reglas de seguridad de Firestore y Storage, Cloud Functions                           | Lenguaje nativo de las reglas de Firebase; requerido para Cloud Functions                                                                               |

## 10.2 Paradigmas de Programación

- **Programación Orientada a Objetos (OOP).** El proyecto implementa herencia, encapsulamiento, polimorfismo y abstracción de forma extensiva. Las entidades del dominio (`UserEntity`, `PatientEntity`, `RoutineEntity`, etc.) se modelan como clases con atributos tipados. Los servicios (`AnalyticsService`, `NotificationService`, `PdfService`) siguen el patrón Singleton.
- **Programación Funcional.** Dart soporta características funcionales que se emplean en el proyecto: funciones de primera clase, colecciones inmutables con `const`, operaciones de mapa/filtro/reducción sobre listas, y expresiones lambda para callbacks y la construcción declarativa de widgets.
- **Programación Reactiva.** La integración con Firestore utiliza streams reactivos para escuchar cambios en tiempo real, y el patrón Provider gestiona el estado de forma reactiva mediante `ChangeNotifier` y `Consumer`.

## 10.3 Plataformas y Herramientas de Desarrollo

**Tabla 28.** Herramientas y plataformas utilizadas.

| Herramienta                    | Categoría                        | Uso                                                                       |
| ------------------------------ | --------------------------------- | ------------------------------------------------------------------------- |
| **Visual Studio Code**   | IDE principal                     | Desarrollo en Dart/Flutter con extensiones de Flutter, Dart, Firebase     |
| **Android Studio**       | IDE complementario                | Configuración de emuladores, SDK Manager, inspección de layouts nativos |
| **Flutter SDK 3.x**      | Framework                         | Desarrollo multiplataforma de la aplicación móvil                       |
| **Firebase Console**     | Plataforma en la nube             | Gestión de Auth, Firestore, Storage, FCM, Analytics, App Check           |
| **Git + GitHub**         | Control de versiones              | Repositorio de código, Issues, Projects (tablero Kanban)                 |
| **Figma**                | Diseño de interfaces             | Prototipos de alta fidelidad, sistema de diseño                          |
| **Postman**              | Pruebas de API                    | Pruebas de endpoints de Gemini API y Cloud Functions                      |
| **Firebase CLI**         | Herramienta de línea de comandos | Deploy de reglas de Firestore/Storage, índices                           |
| **Google Cloud Console** | Administración de servicios      | Gestión de API keys, App Check, Secret Manager                           |

---

REHABTECH | LICENCIATURA EN INGENIERÍA DE SOFTWARE | PÁGINA | 10

---

# 11. ARQUITECTURA DEL SISTEMA

## 11.1 Diagrama de Módulos por Capas

La arquitectura de RehabTech sigue un patrón de tres capas lógicas con un componente transversal de seguridad, que garantiza la separación de responsabilidades, la testabilidad y la mantenibilidad del sistema.

*Figura 3.* Arquitectura de tres capas del sistema RehabTech.

```
┌─────────────────────────────────────────────────────────────────────┐
│                    CAPA DE PRESENTACIÓN (UI)                        │
│                                                                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌───────────┐ │
│  │   Módulo    │  │   Módulo    │  │   Módulo    │  │  Módulo   │ │
│  │  Paciente   │  │  Terapeuta  │  │  Auth (Login│  │  Perfil   │ │
│  │(HomeScreen, │  │(Patients,   │  │  Register,  │  │(Profile,  │ │
│  │ Exercises,  │  │ Routines,   │  │  Forgot     │  │ Edit,     │ │
│  │ Progress,   │  │ Calendar,   │  │  Password)  │  │ Security) │ │
│  │ Messages)   │  │ PatientDet) │  │             │  │           │ │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └─────┬─────┘ │
│         │                │                │                │       │
│         └────────────────┴────────────────┴────────────────┘       │
│                                │                                    │
│                    ┌──────────────────────┐                        │
│                    │  GoRouter + Provider │                        │
│                    │  (Navegación+Estado) │                        │
│                    └──────────┬───────────┘                        │
├──────────────────────────────┼──────────────────────────────────────┤
│                    CAPA DE NEGOCIO (Lógica)                        │
│                                                                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌───────────┐ │
│  │  Analytics  │  │Notification │  │  Progress   │  │    PDF    │ │
│  │  Service    │  │  Service    │  │  Service    │  │  Service  │ │
│  └─────────────┘  └─────────────┘  └─────────────┘  └───────────┘ │
│                                                                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐               │
│  │Pose Detect. │  │  Deep Link  │  │  Gemini AI  │               │
│  │  Service    │  │  Service    │  │  (Nora)     │               │
│  └─────────────┘  └─────────────┘  └─────────────┘               │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │           Domain Entities (Modelos de Datos)                  │ │
│  │  UserEntity, PatientEntity, RoutineEntity, AppointmentEntity, │ │
│  │  ChatEntity, Exercise                                         │ │
│  └───────────────────────────────────────────────────────────────┘ │
├──────────────────────────────────────────────────────────────────────┤
│                    CAPA DE DATOS (Persistencia)                     │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                    Firebase Suite                             │  │
│  │  ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌──────────┐ │  │
│  │  │  Firestore │ │  Storage   │ │    Auth    │ │   FCM    │ │  │
│  │  │  (NoSQL)   │ │ (Archivos) │ │(Identidad)│ │ (Push)   │ │  │
│  │  └────────────┘ └────────────┘ └────────────┘ └──────────┘ │  │
│  │  ┌────────────┐ ┌────────────┐ ┌────────────┐             │  │
│  │  │ Analytics  │ │ App Check  │ │ Cloud Func.│             │  │
│  │  │ (Métricas) │ │(Integridad)│ │ (Servidor) │             │  │
│  │  └────────────┘ └────────────┘ └────────────┘             │  │
│  └──────────────────────────────────────────────────────────────┘  │
├──────────────────────────────────────────────────────────────────────┤
│  ░░░░░░░░░░░░ COMPONENTE TRANSVERSAL: SEGURIDAD ░░░░░░░░░░░░░░░░  │
│  ░  ErrorHandler · AppLogger · Firestore Rules · Storage Rules  ░  │
│  ░  App Check · TLS 1.3 · AES-256 · RBAC · LFPDPPP Compliance  ░  │
│  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  │
└──────────────────────────────────────────────────────────────────────┘
```

## 11.2 Descripción de los Componentes

### Componente 1: Frontend (Capa de Presentación)

Construido en Flutter con Material 3, este componente comprende todas las pantallas de la aplicación organizadas en tres módulos funcionales: módulo paciente (12 pantallas), módulo terapeuta (8 pantallas) y módulo de perfil/configuración (8 pantallas). La navegación se gestiona mediante GoRouter con soporte para deep links y redirección basada en roles. El estado global se maneja con Provider y `ThemeProvider` para el sistema de temas claro/oscuro.

### Componente 2: Backend (Capa de Negocio)

La lógica de negocio se encapsula en servicios independientes (`AnalyticsService`, `NotificationService`, `ProgressService`, `PdfService`, `DeepLinkService`) que implementan el patrón Singleton y proporcionan APIs internas para la capa de presentación. La comunicación con Firebase se realiza a través de los SDKs oficiales de Flutter.

### Componente 3: Motor de Inteligencia Artificial

Comprende dos subsistemas: (a) el asistente virtual Nora, basado en Google Gemini API (`gemini-1.5-flash`), que procesa conversaciones en lenguaje natural con un prompt de sistema que define su personalidad, capacidades y limitaciones; y (b) el módulo de detección de pose (`pose_detection_service.dart`), que utiliza ML Kit Pose Detection para análisis biomecánico en tiempo real.

### Componente 4: Data Access Layer

Abstrae las operaciones de lectura y escritura hacia Firebase Firestore y Storage, proporcionando métodos tipados para las operaciones CRUD de cada entidad. Las entidades del dominio (`UserEntity`, `PatientEntity`, `RoutineEntity`, `AppointmentEntity`, `ChatEntity`) definen los modelos de datos con serialización/deserialización JSON.

### Componente 5: Firebase Database

Cloud Firestore como base de datos NoSQL en tiempo real, organizada en colecciones principales (`users`, `routines`, `exercises`, `appointments`, `conversations`, `fcm_tokens`, `notification_settings`, `feedback`) con subcolecciones para datos relacionados (`nora_chats`, `messages`, `progress`). Firebase Storage para archivos multimedia.

### Componente 6: Sistema de Notificaciones

Firebase Cloud Messaging (FCM) para notificaciones push remotas combinado con `flutter_local_notifications` para notificaciones locales programadas. El servicio gestiona tokens FCM con ciclo de vida completo (registro, actualización, eliminación), suscripción a topics por rol y canales de notificación configurables.

### Componente 7: Seguridad (Transversal)

Componente que permea todas las capas: Firebase Auth para autenticación, reglas de Firestore (214 líneas) y Storage (93 líneas) para autorización, Firebase App Check para verificación de integridad, `ErrorHandler` para manejo centralizado de errores y `AppLogger` para logging estructurado con niveles de severidad.

---

REHABTECH | LICENCIATURA EN INGENIERÍA DE SOFTWARE | PÁGINA | 11

---

# 12. CALIDAD DEL SOFTWARE

## 12.1 Estándares de Calidad Adoptados

El proyecto RehabTech implementa los siguientes estándares de calidad en el proceso de desarrollo:

1. **Control de versiones con GitHub.** Todo el código fuente se gestiona en un repositorio Git con ramas protegidas, pull requests obligatorios para integración a la rama principal, revisión de código por pares y mensajes de commit descriptivos que facilitan la trazabilidad de cambios.
2. **Documentación modular.** Cada componente del sistema cuenta con documentación asociada: el archivo `AGENTS.md` proporciona contexto integral del proyecto, `docs/10_SOFTWARE_SEGURO.md` detalla la seguridad, `docs/MONETIZATION.md` describe el modelo de negocio, y `docs/futures.md` registra las tareas pendientes categorizadas por prioridad.
3. **Análisis estático obligatorio.** Se ejecuta `flutter analyze` después de cada conjunto de cambios, con el criterio de aceptación de cero issues (errors, warnings, hints). El archivo `analysis_options.yaml` define las reglas de linting adoptadas.
4. **Pruebas previas a integración.** Toda funcionalidad nueva o modificada debe pasar pruebas unitarias y de widgets antes de su integración a la rama principal, garantizando que no se introduzcan regresiones.

## 12.2 Métricas de Calidad

### 12.2.1 Métricas del Sistema

| Métrica                                  | Descripción                                                  | Valor Objetivo |
| ----------------------------------------- | ------------------------------------------------------------- | -------------- |
| Tiempo de respuesta del chat IA (Nora)    | Tiempo desde el envío del mensaje hasta la respuesta visible | < 3 segundos   |
| FPS de detección de pose                 | Cuadros procesados por segundo                                | ≥ 25 FPS      |
| Tiempo de carga inicial                   | Tiempo desde el tap del ícono hasta la pantalla principal    | < 4 segundos   |
| Tamaño del APK                           | Peso del archivo de instalación                              | < 50 MB        |
| Consumo de RAM durante sesión de terapia | Memoria utilizada con cámara + pose detection activos        | < 350 MB       |

### 12.2.2 Métricas del Proceso

| Métrica              | Descripción                                              | Valor Objetivo     |
| --------------------- | --------------------------------------------------------- | ------------------ |
| Lead time             | Tiempo desde la creación de la tarea hasta el despliegue | < 5 días          |
| Cycle time            | Tiempo desde el inicio de trabajo hasta la finalización  | < 3 días          |
| Throughput            | Tareas completadas por semana                             | ≥ 8 tareas/semana |
| Defect density        | Defectos por 1000 líneas de código                      | < 2 defectos/KLOC  |
| Code coverage (tests) | Porcentaje de código cubierto por pruebas                | ≥ 60%             |

### 12.2.3 Métricas de Experiencia de Usuario

| Métrica                     | Descripción                                                         | Valor Objetivo |
| ---------------------------- | -------------------------------------------------------------------- | -------------- |
| SUS (System Usability Scale) | Puntuación de usabilidad estandarizada                              | ≥ 70/100      |
| Tasa de adherencia           | Porcentaje de pacientes que completan ≥80% de sus rutinas semanales | ≥ 60%         |
| NPS (Net Promoter Score)     | Probabilidad de recomendación                                       | ≥ 30          |
| Tasa de abandono (churn)     | Porcentaje de usuarios que dejan de usar la app por mes              | < 10%          |
| CSAT (Customer Satisfaction) | Satisfacción generalde los usuarios                                 | ≥ 4.0/5.0     |

## 12.3 Plan de Pruebas

### 12.3.1 Pruebas Unitarias

Se implementan pruebas unitarias para la lógica de negocio aislada de dependencias externas, utilizando el framework `flutter_test` y mocks para los servicios de Firebase:

- `AnalyticsService` — Verificación de registro correcto de eventos con parámetros válidos (sin booleanos, con conversión a int)..
- `NotificationService` — Validación de inicialización, gestión de tokens FCM y programación de recordatorios.
- `ProgressService` — Verificación de cálculos de progreso, promedios y estadísticas.
- `DeepLinkService` — Parsing correcto de URLs, sanitización de parámetros y manejo de enlaces malformados.

### 12.3.2 Pruebas de Widgets

Pruebas de componentes de interfaz que validan el renderizado correcto y la interacción del usuario:

- `AppErrorWidget` — Renderizado de cada factory method (network, permission, auth, notFound, general).
- `EmptyStateWidget` — Verificación de todos los constructores de estado vacío.
- `LoadingWidget` — Validación del efecto shimmer y estados de carga.
- `ExerciseCard` — Renderizado correcto con datos completos e incompletos.

### 12.3.3 Pruebas de Integración

Validación de flujos completos que involucran múltiples componentes:

- Flujo de registro e inicio de sesión (Firebase Auth + Firestore + FCM).
- Flujo de completar un ejercicio (cámara + pose detection + almacenamiento de resultados).
- Flujo de chat con Nora (envío de mensaje + llamada a Gemini API + almacenamiento en Firestore).
- Flujo de asignación de rutina por terapeuta (creación + asignación + notificación al paciente).

### 12.3.4 Pruebas de Rendimiento

- Medición de FPS de detección de pose en dispositivos de gama baja, media y alta.
- Pruebas de estrés con múltiples sesiones simultáneas de escritura en Firestore.
- Evaluación del consumo de batería durante sesiones de terapia de 30 minutos.
- Análisis de latencia de Gemini API bajo diferentes condiciones de red.

### 12.3.5 Pruebas con Usuarios

Se condujeron sesiones de prueba con usuarios reales (pacientes en rehabilitación y fisioterapeutas) para evaluar:

- Facilidad de aprendizaje y navegación intuitiva.
- Comprensión de la retroalimentación de pose en tiempo real.
- Utilidad percibida del asistente Nora.
- Satisfacción con la calidad de los reportes generados.

## 12.4 Resultados de Pruebas

**Tabla 29.** Resumen de resultados de pruebas.

| Tipo de Prueba        | Total de Casos | Aprobados         | Fallidos            | Tasa de Éxito  |
| --------------------- | -------------- | ----------------- | ------------------- | --------------- |
| Unitarias             | 45             | 42                | 3                   | 93.3%           |
| Widgets               | 20             | 19                | 1                   | 95.0%           |
| Integración          | 12             | 10                | 2                   | 83.3%           |
| Rendimiento           | 8              | 7                 | 1                   | 87.5%           |
| Usuarios (usabilidad) | 15 sesiones    | 13 satisfactorios | 2 con observaciones | 86.7%           |
| **Total**       | **100**  | **91**      | **9**         | **91.0%** |

Los casos fallidos se documentaron como issues en GitHub Projects con prioridad asignada y se abordaron en iteraciones subsecuentes. Los principales hallazgos incluyeron: (1) latencia ocasionalmente superior a 200 ms en dispositivos de gama baja durante la detección de pose, resuelta optimizando la resolución de entrada de la cámara; (2) un caso de error en la generación de PDF con caracteres especiales en nombres de ejercicios, corregido mediante sanitización de strings; y (3) retroalimentación de usuarios solicitando instrucciones más detalladas previas al inicio de la sesión de terapia, implementada en una actualización posterior.

---

REHABTECH | LICENCIATURA EN INGENIERÍA DE SOFTWARE | PÁGINA | 12

---

# 13. SOFTWARE SEGURO

## 13.1 Identificación de Riesgos

La seguridad constituye un pilar fundamental en RehabTech dado que el sistema gestiona datos clínicos sensibles de pacientes, información personal identificable (PII), historial de tratamientos, comunicaciones médico-paciente y registros de sesiones basados en captura de video. La clasificación de sensibilidad de los datos se establece como **alta**, requiriendo un enfoque de seguridad integral bajo los principios de *Security by Design*.

La identificación de riesgos se realizó empleando una metodología combinada que incluye: el modelo **STRIDE** (Microsoft) para categorización de amenazas, el **OWASP Mobile Top 10 (2024)** para riesgos específicos de aplicaciones móviles, análisis de superficie de ataque y revisión de código y configuración de seguridad.

**Tabla 30.** Principales riesgos identificados.

| ID    | Riesgo                                                                                                                                    | Probabilidad | Impacto | Nivel              |
| ----- | ----------------------------------------------------------------------------------------------------------------------------------------- | ------------ | ------- | ------------------ |
| R-001 | Exposición de API key de Gemini en archivo `.env` del dispositivo. Un atacante podría extraerla mediante ingeniería inversa del APK. | Alta         | Alto    | **Crítico** |
| R-002 | Ausencia de verificación obligatoria de email tras registro, permitiendo cuentas con emails no verificados.                              | Alta         | Medio   | **Alto**     |
| R-003 | Validación insuficiente de contraseñas (mínimo 6 caracteres de Firebase Auth sin requisitos de complejidad).                           | Alta         | Medio   | **Alto**     |
| R-004 | Reglas de Storage permisivas para `chat_attachments` sin validación de participación en la conversación.                             | Media        | Alto    | **Alto**     |
| R-005 | Creación de conversaciones en Firestore sin validar que el usuario sea parte de la conversación.                                        | Media        | Alto    | **Alto**     |
| R-006 | Exposición de información sensible en logs de producción (tokens FCM parciales).                                                       | Media        | Medio   | **Medio**    |
| R-007 | Acumulación indefinida de tokens FCM obsoletos en Firestore sin mecanismo de limpieza.                                                   | Media        | Bajo    | **Medio**    |
| R-008 | Ausencia de validación de esquema en reglas de Firestore para colecciones `notifications` y `feedback`.                              | Media        | Medio   | **Medio**    |
| R-009 | Manipulación de parámetros en deep links (`rehabtech://exercise/{id}`) con URLs maliciosas.                                           | Baja         | Medio   | **Medio**    |
| R-010 | Pérdida o robo del dispositivo con sesión activa persistente de Firebase Auth.                                                          | Media        | Alto    | **Alto**     |
| R-011 | Ausencia de cifrado adicional a nivel de campo para datos de salud en Firestore.                                                          | Baja         | Alto    | **Medio**    |

## 13.2 Plan de Mitigación

Para cada riesgo identificado se definió una estrategia de respuesta con acciones concretas, responsables y plazos de implementación:

**Tabla 31.** Plan de mitigación de riesgos.

| ID    | Estrategia        | Acción de Mitigación                                                                                                                                                                                                     |
| ----- | ----------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| R-001 | **Evitar**  | Migrar llamadas a Gemini API a Cloud Functions de Firebase como proxy seguro. Eliminar `GEMINI_API_KEY` del cliente. Validar tokens de Auth y App Check antes de invocar la API. Rotar la API key actual inmediatamente. |
| R-002 | **Reducir** | Implementar pantalla de verificación post-registro. Bloquear acceso hasta que `emailVerified == true`. Agregar botón de reenvío con cooldown de 60 segundos.                                                          |
| R-003 | **Reducir** | Implementar validador con reglas: mínimo 8 caracteres, 1 mayúscula, 1 minúscula, 1 número y 1 carácter especial. Agregar indicador visual de fortaleza.                                                               |
| R-004 | **Reducir** | Modificar reglas de Storage para validar participación en la conversación mediante consulta cruzada a Firestore. Validar tipo de archivo.                                                                                |
| R-005 | **Reducir** | Requerir que `therapistId` o `patientId` del recurso coincida con `request.auth.uid`. Validar existencia y roles de los participantes.                                                                               |
| R-006 | **Reducir** | Deshabilitar logs sensibles en modo release con `kReleaseMode`. Ofuscar tokens FCM completamente.                                                                                                                        |
| R-007 | **Reducir** | Crear Cloud Function programada para eliminar tokens FCM con `updatedAt > 30 días`. Agregar campo `lastUsed`.                                                                                                         |
| R-008 | **Reducir** | Agregar funciones de validación de esquema en Firestore Rules con `hasRequiredFields()`. Limitar tamaño de campos de texto.                                                                                            |
| R-009 | **Reducir** | Sanitizar y validar parámetros de deep links en `DeepLinkService`. Verificar autenticación antes de navegar a rutas protegidas.                                                                                        |
| R-010 | **Reducir** | Implementar timeout de sesión por inactividad (30 min). Agregar bloqueo biométrico opcional con `local_auth`.                                                                                                          |
| R-011 | **Aceptar** | Firebase cifra en reposo (AES-256) y en tránsito (TLS 1.3) nativamente. El costo de E2EE es desproporcionado. Revisión trimestral.                                                                                       |

### 13.2.1 Controles Técnicos Implementados

**Tabla 32.** Controles de seguridad activos en RehabTech.

| Control                              | Estado          | Descripción                                                                                                   |
| ------------------------------------ | --------------- | -------------------------------------------------------------------------------------------------------------- |
| Cifrado en tránsito (TLS 1.2+)      | ✅ Implementado | Comunicaciones app-Firebase y app-Gemini sobre HTTPS                                                           |
| Cifrado en reposo (AES-256)          | ✅ Implementado | Firestore y Storage cifrados por infraestructura de GCP                                                        |
| Firebase App Check                   | ✅ Implementado | Play Integrity (prod) + Debug Provider (dev)                                                                   |
| Firestore Security Rules (RBAC)      | ✅ Implementado | 214 líneas con funciones `isOwner()`, `isTherapist()`, `isAssignedTherapist()`, `onlyUpdatesFields()` |
| Storage Security Rules               | ✅ Implementado | 93 líneas con validación de tipo y tamaño de archivo                                                        |
| Manejo centralizado de errores       | ✅ Implementado | `ErrorHandler` con clasificación por tipo                                                                   |
| Logging estructurado                 | ✅ Implementado | `AppLogger` con niveles DEBUG, INFO, WARNING, ERROR                                                          |
| Eliminación de tokens FCM al logout | ✅ Implementado | `removeToken()` en `NotificationService`                                                                   |
| Denegación por defecto              | ✅ Implementado | Colecciones no declaradas denegadas;`achievements` con `write: false`                                      |

### 13.2.2 Marcos de Referencia Normativos

El diseño de seguridad de RehabTech se alinea con los siguientes marcos de referencia:

- **OWASP Mobile Application Security Verification Standard (MASVS)** nivel L1/L2.
- **OWASP Top 10 Mobile Risks 2024.**
- **ISO/IEC 27001:2022** para gestión de seguridad de la información.
- **NIST Cybersecurity Framework (CSF)** para gestión de riesgos.
- **CERT Secure Coding** para desarrollo en Dart/Flutter.
- **Ley Federal de Protección de Datos Personales en Posesión de los Particulares (LFPDPPP)** de México.
- Directrices generales del **RGPD/GDPR** para protección de datos personales sensibles.

---

REHABTECH | LICENCIATURA EN INGENIERÍA DE SOFTWARE | PÁGINA | 13

---

# 14. CORRECCIONES Y MEJORAS A FUTURO

El desarrollo de RehabTech establece una base sólida que contempla múltiples fases de evolución para ampliar su alcance, precisión y valor clínico. A continuación se describen las principales líneas de mejora planificadas:

## 14.1 Mejoras de Inteligencia Artificial

- **Modelos de pose especializados por patología.** Entrenar modelos específicos de TensorFlow Lite para condiciones como lesiones de rodilla, hombro, espalda baja y rehabilitación neurológica, mejorando la precisión del análisis biomecánico y la relevancia de las recomendaciones.
- **Nora contextual con historial clínico.** Ampliar las capacidades del asistente virtual incorporando el historial médico completo del paciente como contexto para la generación de respuestas más personalizadas y médicamente relevantes.
- **Predicción de riesgo de abandono.** Implementar modelos predictivos que identifiquen pacientes con alta probabilidad de abandonar el tratamiento, activando intervenciones proactivas (mensajes motivacionales, ajuste de dificultad, notificación al terapeuta).
- **Reconocimiento de patrones de fatiga.** Utilizar datos temporales de las sesiones para detectar signos de fatiga muscular y sugerir descansos o modificaciones de ejercicios en tiempo real.

## 14.2 Accesibilidad

- **Soporte completo de VoiceOver (iOS) y TalkBack (Android)** con descripciones auditivas de todos los elementos interactivos.
- **Alto contraste mejorado** con modos de daltonismo (protanopía, deuteranopía, tritanopía).
- **Tamaños de fuente dinámicos** que respeten las preferencias de accesibilidad del sistema operativo.
- **Guía por voz** para pacientes con limitaciones visuales durante las sesiones de terapia.

## 14.3 Integración con Hardware

- **Sensores inerciales (IMU)** en bandas elásticas inteligentes para captura de datos biomecánicos complementarios a la detección visual.
- **Integración con wearables** (Apple Watch, Fitbit, Garmin) para monitoreo de frecuencia cardíaca, esfuerzo y patrones de sueño.
- **Dispositivos hápticos** de retroalimentación vibrotáctil que indiquen la correcta posición corporal.

## 14.4 Escalabilidad en la Nube

- **Migración a Cloud Functions** para lógica de negocio crítica (procesamiento de pagos, cálculo de estadísticas, limpieza de datos).
- **Implementación de CDN** para distribución eficiente de contenido multimedia (videos de ejercicios).
- **Base de datos distribuida** para soporte multi-región con latencia optimizada.
- **Modo offline robusto** con sincronización bidireccional y resolución de conflictos.

## 14.5 Pruebas Piloto Clínicas

- **Estudios clínicos controlados** en colaboración con instituciones de salud para validar la efectividad clínica de la plataforma comparada con la rehabilitación presencial tradicional.
- **Certificación como dispositivo médico** en categoría de software (SaMD) ante COFEPRIS para habilitar su uso clínico formal.
- **Publicación de resultados** en revistas científicas indexadas del ámbito de la rehabilitación y la salud digital.

---

REHABTECH | LICENCIATURA EN INGENIERÍA DE SOFTWARE | PÁGINA | 14

---

# 15. CONCLUSIONES

El desarrollo de RehabTech representa una contribución significativa en la intersección entre la ingeniería de software, la inteligencia artificial y la salud pública en México. A lo largo del presente documento se ha descrito de manera integral el proceso de concepción, diseño, implementación y validación de una plataforma móvil que aborda directamente las barreras estructurales que limitan el acceso a la rehabilitación física de calidad: la concentración geográfica de los servicios, los costos prohibitivos para amplios sectores de la población, la insuficiencia de profesionales especializados y las alarmantes tasas de abandono terapéutico que comprometen la efectividad de los tratamientos.

Desde una perspectiva de **impacto social**, RehabTech demuestra que la tecnología móvil, combinada con inteligencia artificial accesible, puede funcionar como un ecualizador de oportunidades en el ámbito de la salud. Al permitir que un paciente en una comunidad rural de Hidalgo acceda a guía personalizada de rehabilitación, retroalimentación biomecánica en tiempo real y comunicación directa con su fisioterapeuta utilizando únicamente un smartphone convencional, la plataforma trasciende las limitaciones del modelo presencial tradicional sin pretender reemplazarlo. La relación paciente-terapeuta se enriquece, no se sustituye: el profesional dispone de datos objetivos de progreso, métricas de adherencia y herramientas de comunicación que le permiten tomar decisiones clínicas más informadas y oportunas.

Los **retos técnicos superados** durante el desarrollo fueron considerables. La integración de detección de pose en tiempo real con retroalimentación de baja latencia (< 200 ms) en dispositivos móviles de gama media requirió un trabajo exhaustivo de optimización del pipeline de procesamiento de video. La implementación de un asistente virtual que sea útil, empático y a la vez estrictamente acotado en sus capacidades —Nora no diagnostica, no prescribe, no reemplaza al profesional— demandó un diseño cuidadoso del prompt de sistema y pruebas extensivas para evitar respuestas inapropiadas. La arquitectura de seguridad, que protege datos clínicos sensibles bajo estándares OWASP MASVS, ISO 27001 y LFPDPPP, implicó el diseño de 214 líneas de reglas de Firestore con funciones granulares de control de acceso basadas en roles.

La **propuesta de valor** de RehabTech se articula en cuatro dimensiones: (1) para el paciente, acceso a rehabilitación guiada desde el hogar con retroalimentación inteligente que mejora la calidad de ejecución y la motivación; (2) para el fisioterapeuta, herramientas de monitoreo remoto que amplían su capacidad de atención y mejoran la toma de decisiones; (3) para el sistema de salud, una solución escalable que puede aliviar la presión sobre los centros de rehabilitación presenciales y reducir los costos agregados de tratamiento; y (4) para la comunidad académica, una demostración práctica de cómo las metodologías ágiles (Kanban), los patrones de arquitectura de software y las tecnologías de IA pueden convergir para resolver problemas reales de salud pública.

En cuanto al **trabajo futuro**, las líneas de evolución más prometedoras incluyen: el entrenamiento de modelos de IA especializados por patología para mejorar la precisión del análisis biomecánico; la realización de pruebas piloto clínicas controladas en colaboración con instituciones de salud para validar científicamente la efectividad de la plataforma; la integración con dispositivos wearables para enriquecer los datos biométricos disponibles; la certificación como software de dispositivo médico (SaMD) ante COFEPRIS; y la expansión de la accesibilidad para garantizar que la plataforma sea utilizable por personas con diversas capacidades. Adicionalmente, la implementación del modelo freemium con licencias B2B para clínicas y hospitales viabiliza la sostenibilidad económica del proyecto a largo plazo.

En conclusión, RehabTech constituye no solo un producto de software funcional, sino una propuesta integral que demuestra cómo la ingeniería de software rigurosa, aplicada con sensibilidad social y visión interdisciplinaria, puede generar soluciones tecnológicas que impacten positivamente la vida de las personas. El proyecto sienta las bases para una nueva generación de herramientas de salud digital en México y Latinoamérica, contribuyendo a la construcción de un ecosistema de rehabilitación más accesible, personalizado, basado en datos y centrado en el bienestar del paciente.

---

REHABTECH | LICENCIATURA EN INGENIERÍA DE SOFTWARE | PÁGINA | 15

---

# 16. REFERENCIAS BIBLIOGRÁFICAS

1. Adherencia terapéutica. (2023). En *Diccionario de la Real Academia de Medicina*. Organización Médica Colegial de España.
2. Anderson, D. J. (2010). *Kanban: Successful Evolutionary Change for Your Technology Business*. Blue Hole Press.
3. Burns, D. M., Leung, N., Hardisty, M., Whyne, C. M., Henry, P., & McLachlin, S. (2020). Shoulder physiotherapy exercise recognition: Machine learning the inertial signals from a smartwatch. *Physiological Measurement*, *41*(7), 075002. https://doi.org/10.1088/1361-6579/ab9782
4. Consejo Nacional de Evaluación de la Política de Desarrollo Social. (2023). *Informe de pobreza y evaluación 2023*. CONEVAL.
5. Géron, A. (2019). *Hands-On Machine Learning with Scikit-Learn, Keras, and TensorFlow* (2a ed.). O'Reilly Media.
6. Google. (2024). *Firebase Documentation*. https://firebase.google.com/docs
7. Google. (2024). *ML Kit Pose Detection*. https://developers.google.com/ml-kit/vision/pose-detection
8. Google. (2024). *Gemini API Documentation*. https://ai.google.dev/docs
9. Howard, A. G., Zhu, M., Chen, B., Kalenichenko, D., Wang, W., Weyand, T., Andreetto, M., & Adam, H. (2017). MobileNets: Efficient convolutional neural networks for mobile vision applications. *arXiv preprint arXiv:1704.04861*. https://doi.org/10.48550/arXiv.1704.04861
10. Instituto Nacional de Estadística y Geografía. (2021). *Censo de Población y Vivienda 2020. Discapacidad*. INEGI.
11. Jack, K., McLean, S. M., Moffett, J. K., & Gardiner, E. (2010). Barriers to treatment adherence in physiotherapy outpatient clinics: A systematic review. *Manual Therapy*, *15*(3), 220–228. https://doi.org/10.1016/j.math.2009.12.004
12. Lugaresi, C., Tang, J., Nash, H., McClanahan, C., Uboweja, E., Hays, M., Zhang, F., Chang, C.-L., Yong, M. G., Lee, J., Chang, W.-T., Hua, W., Georg, M., & Grundmann, M. (2019). MediaPipe: A Framework for Building Perception Pipelines. *arXiv preprint arXiv:1906.08172*. https://doi.org/10.48550/arXiv.1906.08172
13. Martin, R. C. (2017). *Clean Architecture: A Craftsman's Guide to Software Structure and Design*. Pearson.
14. Organización Mundial de la Salud. (2022). *Informe mundial sobre rehabilitación*. OMS.
15. OWASP Foundation. (2024). *OWASP Mobile Application Security Verification Standard (MASVS) v2.0*. https://mas.owasp.org/MASVS/
16. Pressman, R. S., & Maxim, B. R. (2020). *Ingeniería del Software: Un Enfoque Práctico* (9a ed.). McGraw-Hill.
17. Russell, S. J., & Norvig, P. (2021). *Artificial Intelligence: A Modern Approach* (4a ed.). Pearson.
18. Secretaría de Salud. (2023). *Programa Nacional de Rehabilitación 2023-2024*. Gobierno de México.
19. Sommerville, I. (2020). *Software Engineering* (10a ed.). Pearson.
20. TensorFlow. (2024). *TensorFlow Lite for Mobile and Edge Devices*. https://www.tensorflow.org/lite

---

REHABTECH | LICENCIATURA EN INGENIERÍA DE SOFTWARE | PÁGINA | 16

---

# 17. ANEXO A: MANUAL DE USUARIO

## A.1 Guía para Pacientes

### A.1.1 Registro e Inicio de Sesión

1. **Descargar la aplicación.** Busque "RehabTech" en Google Play Store e instale la aplicación en su dispositivo Android (versión 8.0 o superior).
2. **Crear una cuenta.** Abra la aplicación y toque "Registrarse". Seleccione "Paciente" como tipo de cuenta. Complete los campos de nombre, apellidos, correo electrónico y contraseña. También puede registrarse con su cuenta de Google.
3. **Verificar su correo electrónico.** Revise su bandeja de entrada y toque el enlace de verificación enviado por RehabTech.
4. **Iniciar sesión.** Ingrese su correo y contraseña, o utilice el botón "Iniciar sesión con Google".

### A.1.2 Vincular con su Fisioterapeuta

1. En la pantalla de perfil, toque "Mi Terapeuta".
2. Proporcione su **código de paciente** (6 dígitos, visible en su perfil) a su fisioterapeuta para que lo vincule desde su módulo.
3. Una vez vinculado, podrá ver información de su terapeuta y comunicarse directamente.

### A.1.3 Realizar una Sesión de Ejercicios

1. Desde la pantalla principal, visualice su **rutina del día** asignada por su terapeuta.
2. Toque el ejercicio que desea realizar para ver las instrucciones detalladas y el video demostrativo.
3. Toque **"Iniciar Ejercicio"**. Se mostrará una cuenta regresiva de preparación.
4. Coloque su dispositivo a una distancia de 1.5-2 metros, apoyado en una superficie estable, de modo que su cuerpo completo sea visible por la cámara.
5. Realice los movimientos siguiendo las indicaciones en pantalla. El sistema mostrará su silueta con código de color:
   - **Verde:** Movimiento correcto.
   - **Amarillo:** Ajuste necesario.
   - **Rojo:** Posición incorrecta.
6. Al finalizar, revise su **reporte de sesión** con la puntuación obtenida y las observaciones de la IA.

### A.1.4 Chatear con Nora (Asistente Virtual)

1. Toque el ícono de mensajes en la barra de navegación inferior.
2. Seleccione **"Chat con Nora"**.
3. Escriba su pregunta o duda sobre rehabilitación. Nora puede:
   - Explicar ejercicios paso a paso.
   - Proporcionar motivación y consejos.
   - Resolver dudas sobre su tratamiento.
4. **Importante:** Nora no diagnostica ni prescribe medicamentos. Ante dolor severo, consulte a su fisioterapeuta.

### A.1.5 Consultar su Progreso

1. Toque "Progreso" en la barra de navegación.
2. Visualice gráficos de evolución semanal y mensual.
3. Consulte métricas como: ejercicios completados, tiempo total de terapia, racha actual y adherencia.

### A.1.6 Comunicarse con su Terapeuta

1. Toque el ícono de mensajes y seleccione **"Chat con Terapeuta"**.
2. Envíe mensajes de texto sobre dudas, molestias o avances.
3. Su terapeuta recibirá una notificación y podrá responder desde su módulo.

## A.2 Guía para Fisioterapeutas

### A.2.1 Registro y Configuración

1. Descargue e instale RehabTech. Seleccione **"Terapeuta"** como tipo de cuenta.
2. Complete sus datos profesionales: nombre, especialidad, cédula profesional.
3. Inicie sesión y acceda al módulo de terapeuta.

### A.2.2 Gestionar Pacientes

1. En la pantalla "Pacientes", toque **"+"** para vincular un nuevo paciente.
2. Ingrese el **código de paciente** (6 dígitos) proporcionado por el paciente.
3. El paciente aparecerá en su listado con indicadores de estado y adherencia.

### A.2.3 Crear y Asignar Rutinas

1. Toque "Rutinas" en la barra de navegación.
2. Toque **"Nueva Rutina"** e ingrese nombre y descripción.
3. Agregue ejercicios del catálogo configurando repeticiones, series y duración para cada uno.
4. Seleccione el paciente destinatario y confirme la asignación.
5. El paciente recibirá una notificación con la nueva rutina.

### A.2.4 Monitorear Progreso de Pacientes

1. Seleccione un paciente de su lista para ver su **detalle**.
2. Consulte los gráficos de progreso, historial de sesiones y puntuaciones de calidad.
3. Revise los reportes PDF generados automáticamente con métricas detalladas.
4. Agregue notas clínicas y observaciones desde el detalle del paciente.

### A.2.5 Gestionar Citas

1. Toque "Calendario" en la barra de navegación.
2. Seleccione una fecha y toque **"Nueva Cita"**.
3. Configure paciente, hora, tipo (presencial/virtual) y notas.
4. El paciente recibirá una notificación automática con los detalles de la cita.

### A.2.6 Comunicación con Pacientes

1. Acceda a "Mensajes" para ver todas las conversaciones activas.
2. Seleccione un paciente para enviar y recibir mensajes en tiempo real.
3. Recibirá notificaciones push cuando un paciente le envíe un mensaje.

---

REHABTECH | LICENCIATURA EN INGENIERÍA DE SOFTWARE | PÁGINA | 17

---

*Documento elaborado como parte de la Licenciatura en Ingeniería de Software de la Escuela Superior de Tlahuelilpan, Universidad Autónoma del Estado de Hidalgo.*

*© 2025 RehabTech. Todos los derechos reservados.*
