<?php

namespace Services;

class RiskEngine {
    public function evaluar($mensaje, $contexto) {
        $ai = new AIService();
        // Pasamos el historial completo al AI, no solo el último mensaje
        $resultadoIA = $ai->analizar($mensaje, $contexto);

        // Si la API falla, devolvemos un objeto por defecto
        if (!isset($resultadoIA['nivel_alerta'])) {
            return [
                "riesgo_detectado" => false,
                "fase_reclutamiento" => 0,
                "nivel_alerta" => "NINGUNO",
                "tecnicas_identificadas" => [],
                "flags" => ["error_api"],
                "evidencia_critica" => null,
                "justificacion_preventiva" => "Error de conexión con OpenAI"
            ];
        }

        return $resultadoIA;
    }
}

?>