<?php
namespace Controllers;

use Services\RiskEngine;
use Services\AlertService;
use Helpers\Logger;
use Helpers\ConversationStore;
use Helpers\Filtro;
use Helpers\Crypto; // 1. ¡AQUÍ ESTÁ LA SOLUCIÓN AL ERROR! Importamos la clase Crypto.

class AnalyzeController {
    public function analyze() {
        $input = json_decode(file_get_contents("php://input"), true);

        $mensaje = $input["message"] ?? "";
        $user_id = $input["user_id"] ?? null;
        $conversation_id = $input["conversation_id"] ?? 1;

        $edad = $input["age"] ?? "Desconocida";
        $plataforma = $input["platform"] ?? "Desconocida";
        $region = $input["region"] ?? null;

        $contexto = "Edad del usuario: $edad. Plataforma: $plataforma.";
        if (!empty($region)) {
            $contexto .= " Ubicación/Región: $region.";
        }

        ConversationStore::addMessage($conversation_id, "Usuario $user_id: " . $mensaje);
        $historial_completo = ConversationStore::getLastMessages($conversation_id);

        // 1. PASO PREVENTIVO: Filtro Local (Costo $0)
        $filtro = new Filtro(60); // Umbral de 60 puntos
        $analisisLocal = $filtro->run($historial_completo);

        if (!$analisisLocal['suspicious']) {
            echo json_encode([
                "status" => "ok",
                "action_required" => "NONE",
                "processed_by" => "local_filter",
                "analysis" => [
                    "riesgo_detectado" => false,
                    "fase_reclutamiento" => 0,
                    "nivel_alerta" => "NINGUNO",
                    "tecnicas_identificadas" => [],
                    "flags" => $analisisLocal['flags'],
                    "evidencia_critica" => null,
                    "justificacion_preventiva" => "Mensaje inofensivo. No superó el umbral del filtro local."
                ]
            ]);
            return; 
        }

        // 2. IA DE ANÁLISIS PROFUNDO
        $riskEngine = new RiskEngine();
        $resultado = $riskEngine->evaluar($historial_completo, $contexto);

        $evidencia_plana = $resultado['evidencia_critica'] ?? null;
        
        // 2. CORRECCIÓN: Quitamos las comillas simples a la variable
        $evidencia_encriptada = Crypto::encrypt($evidencia_plana);

        // Reemplazamos el valor plano por el encriptado para guardarlo en BD/Logs
        $datosParaGuardar = $resultado;
        $datosParaGuardar["evidencia_critica"] = $evidencia_encriptada;

        $alertService = new AlertService();
        $accion = $alertService->generarAccion($resultado["nivel_alerta"]);

        Logger::log([
            "user_id" => $user_id,
            "conversation_id" => $conversation_id,
            "message" => $mensaje,
            "contexto_usado" => $contexto,
            "local_score" => $analisisLocal['score'],
            "resultado" => $datosParaGuardar, // 3. CORRECCIÓN: Guardamos la versión que tiene la evidencia encriptada
            "action" => $accion
        ]);

        echo json_encode([
            "status" => "ok",
            "action_required" => $accion,
            "processed_by" => "openai_engine",
            "analysis" => $resultado // Al frontend le seguimos mandando la plana (o cámbialo a $datosParaGuardar si no quieres que el frontend la vea plana)
        ]);
    }
}
?>