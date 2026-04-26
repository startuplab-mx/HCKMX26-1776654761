# 🛡️ SENTINELA — Risk Analysis API

> **Motor de Detección Temprana de Riesgos para la Protección Digital de Menores de Edad.**
> Producto SaaS · Desarrollado por **UTECH**

SENTINELA es una **API REST de análisis de riesgo conversacional** diseñada para ser integrada en cualquier plataforma de mensajería, red social o aplicación de comunicación que requiera detectar patrones de reclutamiento, manipulación o explotación dirigidos a menores de edad. Su arquitectura en dos capas (filtro local + IA de análisis profundo) garantiza máxima precisión minimizando costos operativos.

> 📱 **Nota sobre el repositorio:** La carpeta `mobile/` contiene una aplicación Flutter de mensajería que sirve únicamente como **entorno de simulación y prueba del sistema**. El producto real es el backend descrito en este documento.

---

## 📋 Tabla de Contenido

1. [Problema que resuelve](#1-problema-que-resuelve)
2. [Tecnologías y herramientas utilizadas](#2-tecnologías-y-herramientas-utilizadas)
3. [Herramientas de IA utilizadas](#3-herramientas-de-ia-utilizadas)
4. [Demo del prototipo](#4-demo-del-prototipo)
5. [Instrucciones para ejecutar el prototipo](#5-instrucciones-para-ejecutar-el-prototipo)
6. [Referencia de la API](#6-referencia-de-la-api)
7. [Marco legal y cumplimiento](#7-marco-legal-y-cumplimiento)
8. [Integrantes del equipo](#8-integrantes-del-equipo)

---

## 1. Problema que resuelve

El crimen organizado en México recluta activamente a menores de 6 a 17 años a través de plataformas digitales, utilizando un vocabulario codificado, jerga regional y técnicas de manipulación emocional que los filtros genéricos de contenido **no son capaces de identificar**.

SENTINELA resuelve esto con un motor especializado que:

- ✅ Comprende **jerga mexicana del crimen organizado** (`jale`, `plaza`, `halcón`, `billete`).
- ✅ Detecta **técnicas de manipulación emocional** (love bombing, aislamiento, culpabilización).
- ✅ Clasifica el mensaje dentro de las **4 fases de reclutamiento** (Capacitación → Inducción → Incubación → Utilización).
- ✅ Discrimina contexto: sabe que "dispara" en un videojuego ≠ "dispara" en una conversación de reclutamiento.
- ✅ Protege la privacidad: **jamás almacena el mensaje original**; solo guarda evidencia cifrada y anonimizada.

---

## 2. Tecnologías y herramientas utilizadas

### Backend (producto principal)

| Tecnología | Versión | Uso |
|---|---|---|
| **PHP** | ≥ 8.1 | Lenguaje principal del servidor; procesamiento del pipeline de análisis |
| **Apache / Nginx** | — | Servidor web con rewrite de rutas hacia `public/index.php` |
| **OpenSSL** | (ext. PHP) | Cifrado AES-256-GCM de la evidencia crítica (`Crypto.php`) |
| **cURL** | (ext. PHP) | Comunicación HTTP con la API de OpenAI (`AIService.php`) |
| **JSON** | (ext. PHP) | Serialización de historial de conversaciones y respuestas |
| **Almacenamiento en archivo** | — | Historial de conversaciones (JSON) y logs de eventos |

### App de simulación / prueba (carpeta `mobile/`)

| Tecnología | Uso |
|---|---|
| **Flutter / Dart** | Framework de la aplicación móvil de simulación |
| **Firebase Auth** | Autenticación de usuarios de prueba |
| **Cloud Firestore** | Almacenamiento de mensajes, usuarios y alertas en tiempo real |
| **SharedPreferences** | Persistencia local de preferencia de tema |

### Infraestructura

| Servicio | Uso |
|---|---|
| **Servidor VPS** (`team-uni-apps.com`) | Hospedaje del backend PHP en producción |
| **OpenAI API** | Motor de análisis profundo de lenguaje natural (Capa 2) |

---

## 3. Herramientas de IA utilizadas

### `OpenAI GPT-4o-mini` — Motor de análisis profundo (Capa 2)

| Atributo | Detalle |
|---|---|
| **¿Cuál?** | `gpt-4o-mini` vía API REST de OpenAI |
| **¿Para qué?** | Analizar el historial de conversación y determinar si hay un patrón de reclutamiento activo |
| **¿En qué medida?** | Se invoca **únicamente** cuando el filtro local (Capa 1) ya ha marcado la conversación como sospechosa (score ≥ 60). Esto significa que el 90%+ de los mensajes inofensivos son descartados antes de llegar a la IA, minimizando costos (~$0.002 por llamada) |

#### System prompt especializado

El modelo opera con un **system prompt de ingeniería forense** diseñado específicamente para el contexto mexicano, con las siguientes instrucciones:

- Discriminar entre lenguaje de videojuegos y situaciones reales.
- Reconocer jerga de narcocultura mexicana (`jale`, `plaza`, `halcón`, etc.).
- Aplicar **reglas de escalación automática**: si el mensaje combina promesa económica + petición de secreto → nivel `ALTO` o `CRITICO`.
- **Nunca reproducir fragmentos textuales exactos** del usuario (protección de privacidad).
- Devolver **únicamente JSON estructurado** (`response_format: json_object`).
- Operar con temperatura `0.1` para máxima consistencia y determinismo.

#### Campos que devuelve el modelo

| Campo | Tipo | Descripción |
|---|---|---|
| `riesgo_detectado` | `bool` | Indica si existe riesgo real |
| `fase_reclutamiento` | `int` (0–4) | Fase del proceso de captación detectada |
| `nivel_alerta` | `string` | `NINGUNO`, `BAJO`, `MEDIO`, `ALTO`, `CRITICO` |
| `tecnicas_identificadas` | `array` | Técnicas de manipulación detectadas |
| `flags` | `array` | Señales de alerta activadas |
| `evidencia_critica` | `string` | Resumen anónimo y descriptivo de la conducta (nunca texto original) |
| `justificacion_preventiva` | `string` | Explicación del riesgo detectado |

#### Fases de reclutamiento detectadas

| Fase | Nombre | Descripción |
|---|---|---|
| `0` | Neutral | Sin riesgo detectado |
| `1` | Capacitación | Primeros contactos, oferta de trabajo |
| `2` | Inducción | Profundización del vínculo, secrecía |
| `3` | Incubación | Aislamiento del entorno familiar |
| `4` | Utilización | Participación activa en actividades ilícitas |

### Filtro Local (Capa 1) — Reglas regex artesanales (sin IA, costo $0)

Antes de llegar al modelo de IA, cada mensaje pasa por `Filtro.php`: un motor de análisis léxico-semántico con más de **60 reglas regex**, organizadas en **9 categorías de riesgo** con puntaje empírico, y **8 combinaciones de contexto** compuestas.

| Categoría | Señal de ejemplo | Score típico |
|---|---|---|
| `dinero_facil` | "paga chida", "hacer billete" | 15–65 pts |
| `manipulacion_emocional` | "borra el chat", "nadie tiene que saber" | 35–100 pts |
| `enganche_lenguaje` | "¿jalas?", "nomas una vez" | 15–60 pts |
| `reclutamiento` | "te presento al jefe" | 35–80 pts |
| `canales_cifrados` | "háblame por Signal" | 35–80 pts |
| `eufemismos_ilicitos` | "mover mercancía" | 30–90 pts |
| `jerga_criminal` | "halcón", "hay consecuencias" | 40–100 pts |
| `logistica_desplazamiento` | "paso por ti", "te compro el boleto" | 70–100 pts |
| `vigilancia_roles` | "estar de campaña" | 80–100 pts |

> Un `score ≥ 60` escala el mensaje a la IA. Si no alcanza el umbral, se responde `NINGUNO` al instante, sin costo de API.

---

## 4. Demo del prototipo

El backend está desplegado y disponible en producción en la siguiente URL pública:

**🔗 Endpoint de producción:**
```
https://team-uni-apps.com/apiReclutamiento/public/index.php/analyze
```

Puedes probarlo directamente desde tu terminal con el comando `curl` de la [sección 6](#6-referencia-de-la-api).

---

## 5. Instrucciones para ejecutar el prototipo

### Requisitos del servidor

- PHP `≥ 8.1` con extensiones: `openssl`, `curl`, `json`
- Servidor web con soporte de `mod_rewrite` (Apache) o equivalente (Nginx)
- Cuenta de OpenAI con acceso a la API

### Paso 1 — Clonar el repositorio

```bash
git clone https://github.com/startuplab-mx/HCKMX26-1776654761.git
cd HCKMX26-1776654761/backend
```

### Paso 2 — Crear el archivo `.env`

Crea el archivo `.env` en la raíz de `backend/` con el siguiente contenido:

```ini
# Clave de OpenAI para el motor de IA (Capa 2)
API_KEY=sk-...tu-clave-de-openai...

# Clave de cifrado AES-256 para evidencia crítica
# Debe ser exactamente 32 bytes (256 bits)
APP_KEY=una-clave-de-exactamente-32-bytes!!
```

> ⚠️ El archivo `.env` está en `.gitignore`. **Nunca lo incluyas en el repositorio.**

### Paso 3 — Verificar permisos de escritura

```bash
chmod -R 775 storage/
```

### Paso 4 — Configurar el servidor web

**Apache** — agrega en `public/.htaccess`:

```apache
RewriteEngine On
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^ index.php [L]
```

**Nginx:**

```nginx
location / {
    try_files $uri $uri/ /index.php?$query_string;
}
```

### Paso 5 — Verificar la instalación

```bash
curl -X POST http://localhost/backend/public/index.php/analyze \
  -H "Content-Type: application/json" \
  -d '{"message":"hola que tal","user_id":1,"conversation_id":1}'
```

Respuesta esperada:

```json
{"status":"ok","action_required":"NONE","processed_by":"local_filter",...}
```

---

## 6. Referencia de la API

### `POST /analyze`

**URL de producción:** `https://team-uni-apps.com/apiReclutamiento/public/index.php/analyze`

#### Headers requeridos

```http
Content-Type: application/json
Accept: application/json
```

#### Body (JSON)

| Campo | Tipo | Requerido | Descripción |
|---|---|---|---|
| `message` | `string` | ✅ | Texto del mensaje a analizar |
| `user_id` | `int` | ✅ | Identificador único del usuario en tu plataforma |
| `conversation_id` | `int` | ✅ | ID de la conversación (mantiene el historial de contexto) |
| `age` | `int` | ⬜ | Edad del usuario (mejora el análisis contextual) |
| `platform` | `string` | ⬜ | Nombre de tu plataforma integradora |
| `region` | `string` | ⬜ | Estado o región del usuario (mejora detección de jerga local) |

#### Ejemplo de request

```bash
curl -X POST https://team-uni-apps.com/apiReclutamiento/public/index.php/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "message": "oye te interesa una chamba fácil, paga chida, solo necesitas tu cel",
    "user_id": 54,
    "conversation_id": 23
  }'
```

#### Respuesta — mensaje inofensivo (filtro local, costo $0)

```json
{
  "status": "ok",
  "action_required": "NONE",
  "processed_by": "local_filter",
  "analysis": {
    "riesgo_detectado": false,
    "fase_reclutamiento": 0,
    "nivel_alerta": "NINGUNO",
    "tecnicas_identificadas": [],
    "flags": [],
    "evidencia_critica": null,
    "justificacion_preventiva": "Mensaje inofensivo. No superó el umbral del filtro local."
  }
}
```

#### Respuesta — mensaje sospechoso (procesado por IA)

```json
{
  "status": "ok",
  "action_required": "WARN_AND_MONITOR",
  "processed_by": "openai_engine",
  "analysis": {
    "riesgo_detectado": true,
    "fase_reclutamiento": 2,
    "nivel_alerta": "MEDIO",
    "tecnicas_identificadas": ["Oferta de empleo ilícito", "Minimización de riesgo"],
    "flags": ["trabajo_cel", "paga_chida", "trabajo_sencillo"],
    "evidencia_critica": "Se detectó una oferta de empleo informal condicionada al uso del teléfono personal, con promesa de ingresos rápidos y sin requisitos formales.",
    "justificacion_preventiva": "El mensaje combina una propuesta económica atractiva con ausencia de condiciones laborales legítimas, patrón consistente con captación en fase de inducción."
  }
}
```

#### Valores de `action_required`

| Valor | Nivel que lo dispara | Significado |
|---|---|---|
| `NONE` | NINGUNO | Sin acción requerida |
| `MONITOR` | BAJO | Monitoreo silencioso |
| `WARN_AND_MONITOR` | MEDIO | Notificar al tutor/moderador + seguimiento |
| `BLOCK_AND_REPORT` | ALTO / CRITICO | Bloquear al remitente y escalar inmediatamente |

#### ¿Por qué dos capas?

| | Filtro Local (Capa 1) | Motor IA (Capa 2) |
|---|---|---|
| **Costo** | $0 | ~$0.002/req |
| **Latencia** | < 5ms | 1–3 segundos |
| **Precisión** | Alta en patrones conocidos | Muy alta (contexto, ironía, jerga nueva) |
| **Uso** | Filtra el 90%+ de mensajes inofensivos | Solo mensajes ya marcados como sospechosos |

#### Cifrado de evidencia crítica

La `evidencia_critica` se cifra con **AES-256-GCM** antes de escribirse en los logs, usando la clave `APP_KEY` del `.env`:

```
Evidencia (texto plano)
        │
        ▼
openssl_encrypt(AES-256-GCM)
  → IV aleatorio 12 bytes + Tag GCM 16 bytes + Texto cifrado
        │
        ▼
base64_encode( IV + Tag + CipherText )  →  almacenado en app.log
```

> Si el tag de autenticación no coincide al descifrar, `Crypto::decrypt()` retorna `null`, protegiendo contra manipulación de la base de datos.

---

## 7. Marco legal y cumplimiento

SENTINELA opera dentro del marco jurídico mexicano aplicable a la protección de menores en entornos digitales.

| Ley / Marco | Aplicación en SENTINELA |
|---|---|
| **Art. 4º Constitucional** | Interés Superior de la Niñez como fundamento del análisis |
| **LGDNNA** | Permite intervención ante riesgo a la integridad del menor |
| **LFPDPPP** | El mensaje original jamás se almacena; solo evidencia cifrada y anonimizada |
| **CNPP** | Facilita que tutores cumplan su obligación de denuncia con alertas fundamentadas |
| **Ley Federal de Delitos Informáticos** | Uso restringido a protección de menores bajo tutela legal |

### Principios de Privacidad por Diseño implementados

1. **Zero-Storage del mensaje original:** El texto del usuario nunca se persiste tal cual (ventana temporal de 10 mensajes para contexto).
2. **Anonimización de evidencia:** El modelo IA tiene instrucción explícita de no reproducir fragmentos textuales exactos.
3. **Cifrado antes de persistencia:** La `evidencia_critica` se cifra con AES-256-GCM antes de escribirse en cualquier log.
4. **Intervención mínima y proporcional:** La IA (Capa 2) solo se activa cuando el filtro local ya confirmó sospecha.

---

## 8. Integrantes del equipo

> ℹ️ Completa esta sección con los nombres y roles de los integrantes del equipo.

| Nombre |
|Castillo Sánchez José Eduardo|
|Flores Espinosa José Maria|
|Miruelo Gonzáles Arturo|
|Rosado Juarez Brandon|

**Empresa:** UTECH  
**Contacto:** soporte@utech.com

---

> *SENTINELA no es una herramienta de espionaje. Es un sistema preventivo diseñado exclusivamente para proteger la integridad física, psicológica y digital de menores de edad, operando bajo los principios de Privacidad por Diseño y el Interés Superior de la Niñez.*
