<?php

namespace Services;

class AlertService {
    public function generarAccion($nivel_alerta) {
        switch (strtoupper($nivel_alerta)) {
            case "CRITICO":
            case "ALTO":
                return "BLOCK_AND_REPORT"; // Bloquear usuario y alertar
            case "MEDIO":
                return "WARN_AND_MONITOR"; // Advertencia y seguimiento silencioso
            case "BAJO":
                return "MONITOR";
            default:
                return "NONE";
        }
    }
}

?>