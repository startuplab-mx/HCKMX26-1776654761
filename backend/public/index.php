<?php

require_once __DIR__ . '/../config/app.php';

/*error_reporting(E_ALL);
ini_set('display_errors', 1);*/

// CORS GLOBAL (antes de TODO)
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

// MUY IMPORTANTE: manejar preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Autoload simple
spl_autoload_register(function ($class) {
    $path = __DIR__ . '/../app/' . str_replace('\\', '/', $class) . '.php';
    if (file_exists($path)) {
        require_once $path;
    }
});

require_once __DIR__ . '/../routes/api.php';

?>