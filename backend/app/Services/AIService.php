<?php
namespace Services;

class AIService {
    private $apiKey;
    private $systemPrompt;

    public function __construct() {
        $this->apiKey = env("API_KEY");
       $this->systemPrompt = <<<EOT
Eres un "Analizador de Inteligencia Artificial para la Protección de la Niñez" operando en México. Tu objetivo es detectar y prevenir el reclutamiento de menores (6-17 años) por el crimen organizado.

INSTRUCCIONES Y REGLAS CRÍTICAS:
1. Contexto de Plataforma: Discrimina entre juego (ej. "dispara") y vida real.
2. Jerga Mexicana (Narcocultura): Detecta "jale", "plaza", "halcón", "billete fácil".
3. Fases: 0 (Neutral), 1 (Capacitación), 2 (Inducción), 3 (Incubación - Aislamiento/Secrecía), 4 (Utilización).
4. Privacidad Estricta: Por motivos de protección de datos, NUNCA devuelvas fragmentos textuales exactos de la conversación del usuario.

REGLAS DE ESCALACIÓN AUTOMÁTICA (¡ESTRICTO!):
- Si un mensaje combina promesa económica o jerga ("jale", "pagado") CON petición de secrecía ("no le digas a nadie", "borra el chat"), el nivel_alerta DEBE ser ALTO o CRITICO, y la fase_reclutamiento DEBE ser 3.
- Si detectas intención de reclutamiento real, riesgo_detectado DEBE ser true.

SALIDA ESTRICTA EN JSON:
{
"riesgo_detectado": boolean,
"fase_reclutamiento": integer,
"nivel_alerta": "NINGUNO" | "BAJO" | "MEDIO" | "ALTO" | "CRITICO",
"tecnicas_identificadas": [array de strings],
"flags": [array de strings],
"evidencia_critica": string (Si hay riesgo, redacta un resumen descriptivo, general y anónimo de la conducta detectada. PROHIBIDO copiar el mensaje original. Ej: "Se detectó una oferta de trabajo ilícito condicionada a ocultar la información a la familia". Si no hay riesgo, null),
"justificacion_preventiva": string
}
EOT;
    }

    public function analizar($texto, $contexto = "") {
        $data = [
            "model" => "gpt-4o-mini",
            "messages" => [
                ["role" => "system", "content" => $this->systemPrompt],
                ["role" => "user", "content" => "Contexto: $contexto\n\nHistorial a analizar:\n$texto"]
            ],
            "response_format" => ["type" => "json_object"],
            "temperature" => 0.1
        ];

        $ch = curl_init("https://api.openai.com/v1/chat/completions");
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST => true,
            CURLOPT_HTTPHEADER => [
                "Content-Type: application/json",
                "Authorization: Bearer " . $this->apiKey
            ],
            CURLOPT_POSTFIELDS => json_encode($data)
        ]);

        $response = curl_exec($ch);
        curl_close($ch);

        $decodedResponse = json_decode($response, true);
        $content = $decodedResponse['choices'][0]['message']['content'] ?? "{}";

        return json_decode($content, true);
    }
}
?>