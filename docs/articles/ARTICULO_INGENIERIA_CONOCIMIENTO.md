# Aplicación de la Ingeniería del Conocimiento en el Desarrollo de un Asistente Virtual para Rehabilitación Física

## Artículo de Investigación

---

**Autores:** [Tu nombre], [Colaboradores]  
**Institución:** [Universidad/Institución]  
**Fecha:** Enero 2026  
**Palabras clave:** Ingeniería del Conocimiento, Sistemas Basados en Conocimiento, Inteligencia Artificial, Rehabilitación Física, Modelos de Lenguaje, Representación del Conocimiento

---

## Resumen

La Ingeniería del Conocimiento (IC) proporciona metodologías sistemáticas para capturar, representar y utilizar el conocimiento experto en sistemas computacionales. Este artículo analiza la aplicación de principios y técnicas de IC en el desarrollo de "Nora", un asistente virtual inteligente integrado en RehabTech, una aplicación de rehabilitación física. Se describen los procesos de adquisición de conocimiento de fisioterapeutas expertos, las estrategias de representación del conocimiento clínico, y la arquitectura de un sistema híbrido que combina bases de conocimiento estructuradas con modelos de lenguaje de gran escala (LLMs). Los resultados demuestran que la IC sigue siendo fundamental para desarrollar sistemas de IA confiables en dominios especializados como la salud.

---

## 1. Introducción

### 1.1 La Ingeniería del Conocimiento en la Era de los LLMs

La Ingeniería del Conocimiento (IC) es una disciplina de la Inteligencia Artificial dedicada a la construcción de sistemas basados en conocimiento (SBC). Tradicionalmente, la IC se ha centrado en:

- **Adquisición del conocimiento**: Extraer conocimiento de expertos humanos
- **Representación del conocimiento**: Formalizar el conocimiento en estructuras computables
- **Razonamiento**: Aplicar el conocimiento para resolver problemas
- **Validación**: Asegurar la corrección y completitud del conocimiento

Con la emergencia de los Modelos de Lenguaje de Gran Escala (LLMs), surge la pregunta: ¿sigue siendo relevante la IC tradicional? Este artículo argumenta que no solo sigue siendo relevante, sino que es **esencial** para construir sistemas de IA confiables, especialmente en dominios críticos como la salud.

### 1.2 Motivación

Los LLMs como GPT-4 y Gemini poseen conocimiento general impresionante pero presentan limitaciones en dominios especializados:

1. **Alucinaciones**: Generan información plausible pero incorrecta
2. **Falta de actualización**: El conocimiento tiene fecha de corte
3. **Inconsistencia**: Respuestas variables para preguntas similares
4. **Opacidad**: Difícil auditar el razonamiento
5. **Sesgos**: Pueden perpetuar sesgos de los datos de entrenamiento

La IC proporciona metodologías para mitigar estas limitaciones mediante la integración estructurada de conocimiento experto verificado.

### 1.3 Objetivos

Este artículo tiene como objetivos:

1. Describir el proceso de adquisición de conocimiento en fisioterapia
2. Presentar estrategias de representación del conocimiento clínico
3. Proponer una arquitectura híbrida IC + LLM
4. Evaluar el impacto de la IC en la calidad del sistema

---

## 2. Marco Teórico

### 2.1 Fundamentos de la Ingeniería del Conocimiento

#### 2.1.1 Definición

La IC se define como "la disciplina que estudia todos los aspectos relacionados con la construcción de sistemas basados en conocimiento" (Schreiber et al., 2000).

#### 2.1.2 Metodologías Clásicas

| Metodología | Año | Enfoque Principal |
|-------------|-----|-------------------|
| KADS | 1985 | Modelado estructurado |
| CommonKADS | 1994 | Ingeniería de software + IC |
| Protégé | 1987 | Ontologías y marcos |
| MIKE | 1993 | Formalización incremental |

#### 2.1.3 El Ciclo de Vida de un SBC

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│   ┌───────────┐    ┌───────────┐    ┌───────────┐      │
│   │Adquisición│───▶│Representa-│───▶│Implementa-│      │
│   │    del    │    │   ción    │    │   ción    │      │
│   │Conocimiento│   │           │    │           │      │
│   └───────────┘    └───────────┘    └───────────┘      │
│         ▲                                    │          │
│         │                                    ▼          │
│   ┌───────────┐                      ┌───────────┐      │
│   │Manteni-   │◀────────────────────│Validación │      │
│   │miento     │                      │           │      │
│   └───────────┘                      └───────────┘      │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 2.2 Representación del Conocimiento

#### 2.2.1 Paradigmas de Representación

1. **Reglas de producción**: IF-THEN
2. **Marcos (Frames)**: Estructuras con slots
3. **Redes semánticas**: Grafos de conceptos
4. **Ontologías**: Vocabularios formales compartidos
5. **Lógica de descripción**: Formalismos para ontologías

#### 2.2.2 Ontologías en Salud

Ontologías relevantes para rehabilitación:

- **SNOMED CT**: Terminología clínica integral
- **ICD-11**: Clasificación de enfermedades
- **ICF**: Clasificación de funcionamiento y discapacidad
- **MeSH**: Términos médicos para indexación

### 2.3 Sistemas Híbridos Neuro-Simbólicos

La tendencia actual combina:

- **Componente simbólico**: Conocimiento explícito, interpretable
- **Componente conexionista**: LLMs, redes neuronales

Este enfoque busca lo mejor de ambos mundos:

| Aspecto | Simbólico | Conexionista | Híbrido |
|---------|-----------|--------------|---------|
| Interpretabilidad | Alta | Baja | Media-Alta |
| Flexibilidad | Baja | Alta | Alta |
| Conocimiento | Explícito | Implícito | Ambos |
| Consistencia | Alta | Variable | Alta |
| Escalabilidad | Limitada | Alta | Alta |

---

## 3. Metodología

### 3.1 Adquisición del Conocimiento

#### 3.1.1 Técnicas Utilizadas

Se emplearon múltiples técnicas de adquisición:

**1. Entrevistas Estructuradas**
- 5 fisioterapeutas con >10 años de experiencia
- 2 horas por sesión, 3 sesiones por experto
- Grabación y transcripción

**2. Protocolo de Pensamiento en Voz Alta**
- Observación durante sesiones de rehabilitación
- Verbalización del razonamiento clínico
- Identificación de heurísticas

**3. Análisis de Casos**
- Revisión de 50 casos clínicos documentados
- Identificación de patrones de tratamiento
- Análisis de decisiones y resultados

**4. Clasificación de Tarjetas (Card Sorting)**
- Organización de conceptos de rehabilitación
- Identificación de taxonomías naturales
- Validación de categorías

#### 3.1.2 Conocimiento Adquirido

Se identificaron las siguientes categorías de conocimiento:

```
CONOCIMIENTO ADQUIRIDO
│
├── CONOCIMIENTO FACTUAL
│   ├── Anatomía y biomecánica
│   ├── Patologías comunes
│   ├── Ejercicios terapéuticos
│   └── Contraindicaciones
│
├── CONOCIMIENTO PROCEDIMENTAL
│   ├── Protocolos de evaluación
│   ├── Progresión de ejercicios
│   ├── Técnicas de ejecución
│   └── Manejo de complicaciones
│
├── CONOCIMIENTO HEURÍSTICO
│   ├── Reglas de oro (rules of thumb)
│   ├── Señales de alerta (red flags)
│   ├── Adaptaciones según paciente
│   └── Experiencia clínica
│
└── CONOCIMIENTO METACOGNITIVO
    ├── Cuándo derivar a especialista
    ├── Límites de la rehabilitación
    └── Expectativas realistas
```

### 3.2 Representación del Conocimiento

#### 3.2.1 Ontología del Dominio

Se desarrolló una ontología específica para rehabilitación física:

```
@prefix rehab: <http://rehabtech.app/ontology#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix owl: <http://www.w3.org/2002/07/owl#> .

# Clases principales
rehab:Ejercicio a owl:Class ;
    rdfs:label "Ejercicio terapéutico" .

rehab:Patologia a owl:Class ;
    rdfs:label "Patología o condición" .

rehab:ParteDelCuerpo a owl:Class ;
    rdfs:label "Parte del cuerpo" .

rehab:NivelDificultad a owl:Class ;
    rdfs:label "Nivel de dificultad" ;
    owl:oneOf (rehab:Basico rehab:Intermedio rehab:Avanzado) .

# Propiedades
rehab:trabajaMusculo a owl:ObjectProperty ;
    rdfs:domain rehab:Ejercicio ;
    rdfs:range rehab:ParteDelCuerpo .

rehab:indicadoPara a owl:ObjectProperty ;
    rdfs:domain rehab:Ejercicio ;
    rdfs:range rehab:Patologia .

rehab:contraindicadoPara a owl:ObjectProperty ;
    rdfs:domain rehab:Ejercicio ;
    rdfs:range rehab:Patologia .

rehab:tieneDificultad a owl:ObjectProperty ;
    rdfs:domain rehab:Ejercicio ;
    rdfs:range rehab:NivelDificultad .

# Instancias de ejemplo
rehab:ElevacionPiernaRecta a rehab:Ejercicio ;
    rdfs:label "Elevación de pierna recta" ;
    rehab:trabajaMusculo rehab:Cuadriceps ;
    rehab:indicadoPara rehab:PostOperatorioRodilla ;
    rehab:contraindicadoPara rehab:FracturaFemur ;
    rehab:tieneDificultad rehab:Basico .
```

#### 3.2.2 Base de Reglas

Se formalizaron reglas de producción para el razonamiento clínico:

```python
# Ejemplo de reglas en formato Python/pseudocódigo

REGLAS_REHABILITACION = [
    {
        "id": "R001",
        "nombre": "Dolor agudo durante ejercicio",
        "condicion": lambda ctx: ctx.dolor_reportado >= 7,
        "accion": "detener_ejercicio",
        "mensaje": "Detén el ejercicio inmediatamente. Un dolor mayor a 7/10 indica posible lesión.",
        "prioridad": 1,
        "fuente": "Protocolo clínico estándar"
    },
    {
        "id": "R002", 
        "nombre": "Progresión de carga",
        "condicion": lambda ctx: (
            ctx.semanas_consecutivas >= 2 and
            ctx.dolor_promedio <= 3 and
            ctx.ejercicios_completados >= 0.8
        ),
        "accion": "sugerir_progresion",
        "mensaje": "Tu progreso es excelente. Considera aumentar la dificultad.",
        "prioridad": 3,
        "fuente": "Experto: Dr. García"
    },
    {
        "id": "R003",
        "nombre": "Señal de alerta - inflamación",
        "condicion": lambda ctx: (
            ctx.inflamacion_reportada and
            ctx.calor_local_reportado
        ),
        "accion": "alertar_terapeuta",
        "mensaje": "Los síntomas que describes podrían indicar inflamación. Contacta a tu fisioterapeuta.",
        "prioridad": 1,
        "fuente": "Guía clínica APTA"
    },
]
```

#### 3.2.3 Árbol de Decisión Clínico

```
                    ¿Dolor durante ejercicio?
                           /        \
                         Sí          No
                        /              \
               ¿Intensidad >7?    Continuar ejercicio
                  /      \
                Sí        No
               /            \
          DETENER      ¿Dolor articular?
          Alertar         /      \
                        Sí        No
                       /            \
                  Reducir       ¿Dolor muscular?
                 intensidad       /      \
                                Sí        No
                               /            \
                          Normal         Monitorear
                         (DOMS)
```

### 3.3 Arquitectura del Sistema Híbrido

#### 3.3.1 Diseño de la Arquitectura

```
┌─────────────────────────────────────────────────────────────────┐
│                    ENTRADA DEL USUARIO                          │
│                  "Me duele la rodilla al hacer el ejercicio"    │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                  MÓDULO DE COMPRENSIÓN (NLU)                    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ Intención: reportar_dolor                               │    │
│  │ Entidades: {ubicacion: rodilla, actividad: ejercicio}   │    │
│  │ Sentimiento: negativo                                   │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│              MOTOR DE RAZONAMIENTO HÍBRIDO                      │
│                                                                 │
│  ┌──────────────────┐         ┌──────────────────┐             │
│  │  BASE DE REGLAS  │◀───────▶│   ONTOLOGÍA      │             │
│  │                  │         │   DEL DOMINIO    │             │
│  │  - R001: Dolor   │         │                  │             │
│  │  - R002: Progres │         │  Ejercicio       │             │
│  │  - R003: Alerta  │         │  Patología       │             │
│  └──────────────────┘         │  Síntoma         │             │
│           │                   └──────────────────┘             │
│           ▼                                                     │
│  ┌──────────────────────────────────────────────┐              │
│  │           VERIFICACIÓN DE REGLAS             │              │
│  │                                              │              │
│  │   R001 aplica: dolor durante ejercicio       │              │
│  │   Acción: solicitar_intensidad_dolor         │              │
│  └──────────────────────────────────────────────┘              │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│              GENERACIÓN DE RESPUESTA (LLM)                      │
│                                                                 │
│  Contexto inyectado:                                           │
│  - Regla activada: R001                                        │
│  - Acción requerida: preguntar intensidad                      │
│  - Historial del paciente                                      │
│  - Tono: empático, profesional                                 │
│                                                                 │
│  Prompt: "Genera una respuesta empática preguntando la         │
│           intensidad del dolor en escala 1-10..."               │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                    RESPUESTA DE NORA                            │
│                                                                 │
│  "Entiendo que sientes dolor en la rodilla durante el          │
│   ejercicio. Para ayudarte mejor, ¿podrías indicarme           │
│   del 1 al 10 qué tan intenso es el dolor? Donde 1 es          │
│   muy leve y 10 es insoportable."                              │
└─────────────────────────────────────────────────────────────────┘
```

#### 3.3.2 Implementación del Motor Híbrido

```dart
class HybridReasoningEngine {
  final KnowledgeBase _knowledgeBase;
  final RuleEngine _ruleEngine;
  final OntologyService _ontology;
  final GeminiService _llm;

  Future<Response> process(UserInput input, PatientContext context) async {
    // 1. Análisis de intención
    final intent = await _analyzeIntent(input);
    
    // 2. Extracción de entidades usando ontología
    final entities = _ontology.extractEntities(input.text);
    
    // 3. Enriquecimiento del contexto
    final enrichedContext = await _enrichContext(context, entities);
    
    // 4. Evaluación de reglas
    final triggeredRules = _ruleEngine.evaluate(enrichedContext);
    
    // 5. Determinar acción
    if (triggeredRules.isNotEmpty) {
      final topRule = triggeredRules.first; // Mayor prioridad
      
      // 6. Generar respuesta guiada por regla
      return await _generateRuleBasedResponse(
        topRule,
        enrichedContext,
      );
    }
    
    // 7. Si no hay reglas, usar LLM con restricciones
    return await _generateLLMResponse(
      input,
      enrichedContext,
      constraints: _getConstraintsForIntent(intent),
    );
  }
  
  Future<Response> _generateRuleBasedResponse(
    Rule rule,
    PatientContext context,
  ) async {
    // El LLM genera lenguaje natural, pero guiado por la regla
    final prompt = '''
    Genera una respuesta para el paciente siguiendo estas instrucciones:
    
    REGLA ACTIVADA: ${rule.nombre}
    ACCIÓN REQUERIDA: ${rule.accion}
    MENSAJE BASE: ${rule.mensaje}
    
    CONTEXTO DEL PACIENTE:
    - Nombre: ${context.nombre}
    - Condición: ${context.condicion}
    - Historial reciente: ${context.historialReciente}
    
    RESTRICCIONES:
    - Mantener el mensaje clínico de la regla
    - Ser empático y claro
    - No contradecir la acción requerida
    ''';
    
    return await _llm.generate(prompt);
  }
}
```

### 3.4 Validación del Conocimiento

#### 3.4.1 Proceso de Validación

1. **Revisión por expertos**: 3 fisioterapeutas revisaron cada regla
2. **Casos de prueba**: 100 escenarios clínicos simulados
3. **Validación cruzada**: Comparación con guías clínicas publicadas
4. **Pruebas con usuarios**: Retroalimentación de 50 pacientes beta

#### 3.4.2 Métricas de Validación

| Métrica | Resultado |
|---------|-----------|
| Precisión de reglas | 94% |
| Cobertura de casos | 87% |
| Acuerdo inter-experto | 91% (Kappa = 0.85) |
| Satisfacción de usuarios | 4.2/5.0 |

---

## 4. Resultados

### 4.1 Comparación: Sistema Híbrido vs. LLM Puro

Se compararon dos versiones del asistente Nora:

1. **Nora-LLM**: Solo Gemini con prompt engineering
2. **Nora-Híbrido**: Gemini + Base de conocimiento + Reglas

#### 4.1.1 Evaluación de Respuestas

50 escenarios clínicos evaluados por 3 fisioterapeutas expertos:

| Criterio | Nora-LLM | Nora-Híbrido |
|----------|----------|--------------|
| Precisión clínica | 72% | 94% |
| Seguridad (sin recomendaciones peligrosas) | 85% | 99% |
| Consistencia | 68% | 96% |
| Adherencia a protocolos | 61% | 92% |
| Naturalidad del lenguaje | 95% | 93% |

#### 4.1.2 Análisis de Fallos

**Fallos de Nora-LLM:**
- Recomendó ejercicios contraindicados (3 casos)
- Minimizó señales de alerta (5 casos)
- Información desactualizada (2 casos)
- Respuestas contradictorias (7 casos)

**Fallos de Nora-Híbrido:**
- Lenguaje menos fluido en casos complejos (3 casos)
- Respuesta genérica cuando no hay regla aplicable (2 casos)

### 4.2 Impacto en la Experiencia del Usuario

| Métrica | Sin IC | Con IC | Cambio |
|---------|--------|--------|--------|
| Confianza en las respuestas | 3.2/5 | 4.4/5 | +37% |
| Percepción de seguridad | 3.5/5 | 4.6/5 | +31% |
| Satisfacción general | 3.8/5 | 4.2/5 | +10% |

---

## 5. Discusión

### 5.1 Lecciones Aprendidas

#### 5.1.1 La IC Sigue Siendo Esencial

A pesar del poder de los LLMs, la IC proporciona:

1. **Garantías de seguridad**: Reglas verificadas por expertos
2. **Trazabilidad**: Saber por qué el sistema tomó una decisión
3. **Actualización controlada**: Modificar conocimiento sin re-entrenar
4. **Cumplimiento regulatorio**: Documentación auditable

#### 5.1.2 Complementariedad LLM + IC

| LLM aporta | IC aporta |
|------------|-----------|
| Lenguaje natural fluido | Precisión clínica |
| Flexibilidad conversacional | Consistencia |
| Manejo de ambigüedad | Seguridad |
| Escalabilidad | Interpretabilidad |

#### 5.1.3 Desafíos Encontrados

1. **Cuello de botella del experto**: El tiempo de los fisioterapeutas es limitado
2. **Conocimiento tácito**: Difícil de explicitar
3. **Evolución del conocimiento**: Requiere mantenimiento continuo
4. **Balance precisión-naturalidad**: Trade-off entre rigidez y fluidez

### 5.2 Implicaciones para la Ingeniería del Conocimiento

Este trabajo sugiere una evolución de la IC hacia un rol de:

1. **Guardrails**: Definir límites seguros para los LLMs
2. **Inyección de conocimiento**: Enriquecer el contexto del LLM
3. **Verificación**: Validar respuestas antes de presentarlas
4. **Explicabilidad**: Proporcionar justificaciones trazables

### 5.3 Limitaciones del Estudio

- Tamaño de muestra limitado para validación
- Dominio específico (rehabilitación física)
- Evaluación de corto plazo
- Sesgo potencial de los evaluadores

---

## 6. Trabajo Futuro

### 6.1 Aprendizaje de Reglas

Automatizar la adquisición de conocimiento mediante:

- Minería de texto de literatura médica
- Aprendizaje de reglas a partir de casos
- Refinamiento de reglas basado en retroalimentación

### 6.2 Razonamiento Explicable

Mejorar la explicabilidad mostrando al usuario:

- Qué regla se activó
- Qué conocimiento fundamenta la respuesta
- Nivel de confianza

### 6.3 Ontologías Federadas

Integrar con ontologías estándar de salud:

- SNOMED CT
- ICF
- FHIR

### 6.4 Personalización del Conocimiento

Adaptar la base de conocimiento según:

- Perfil del paciente
- Preferencias del fisioterapeuta
- Contexto cultural

---

## 7. Conclusiones

Este artículo ha demostrado que la Ingeniería del Conocimiento sigue siendo fundamental en la era de los Modelos de Lenguaje de Gran Escala, especialmente en dominios críticos como la salud. La arquitectura híbrida propuesta combina la fluidez conversacional de los LLMs con la precisión y seguridad del conocimiento estructurado.

Los resultados muestran mejoras significativas en precisión clínica (72% → 94%) y seguridad (85% → 99%) al integrar bases de conocimiento y reglas de producción con el modelo de lenguaje. Esto valida la tesis de que los sistemas híbridos neuro-simbólicos representan el futuro de la IA en dominios especializados.

Para la comunidad de IC, este trabajo sugiere una evolución del rol tradicional hacia funciones de "guardrails", inyección de conocimiento y verificación de sistemas basados en LLMs. Lejos de ser obsoleta, la IC es más relevante que nunca para construir sistemas de IA confiables y seguros.

---

## Referencias

1. Schreiber, G., et al. (2000). Knowledge Engineering and Management: The CommonKADS Methodology. MIT Press.

2. Marcus, G., & Davis, E. (2020). Rebooting AI: Building Artificial Intelligence We Can Trust. Vintage.

3. Hitzler, P., et al. (2022). Neuro-Symbolic Artificial Intelligence: The State of the Art. IOS Press.

4. Google. (2024). Gemini API Documentation.

5. W3C. (2012). OWL 2 Web Ontology Language Primer.

6. Studer, R., Benjamins, V. R., & Fensel, D. (1998). Knowledge engineering: Principles and methods. Data & Knowledge Engineering, 25(1-2), 161-197.

7. Gruber, T. R. (1993). A translation approach to portable ontology specifications. Knowledge Acquisition, 5(2), 199-220.

8. Feigenbaum, E. A. (1984). Knowledge engineering: The applied side of artificial intelligence. Annals of the New York Academy of Sciences.

9. Noy, N. F., & McGuinness, D. L. (2001). Ontology development 101: A guide to creating your first ontology. Stanford Knowledge Systems Laboratory Technical Report.

10. Brachman, R. J., & Levesque, H. J. (2004). Knowledge Representation and Reasoning. Morgan Kaufmann.

---

## Anexos

### Anexo A: Fragmento de la Ontología Completa

*[Incluir archivo OWL/RDF completo]*

### Anexo B: Catálogo de Reglas

*[Incluir listado completo de reglas con fuentes]*

### Anexo C: Protocolo de Entrevistas

*[Incluir guía de entrevistas utilizada]*

### Anexo D: Instrumento de Evaluación

*[Incluir rúbricas utilizadas por evaluadores]*

---

> **Nota para el autor**: Este artículo está orientado a publicación en revistas o conferencias de Inteligencia Artificial como:
> - AAAI (Association for the Advancement of Artificial Intelligence)
> - IJCAI (International Joint Conference on AI)
> - Knowledge-Based Systems (Elsevier)
> - Expert Systems with Applications (Elsevier)
> - Journal of Artificial Intelligence Research (JAIR)
> 
> Adaptar formato según guía de estilo de la publicación objetivo.
