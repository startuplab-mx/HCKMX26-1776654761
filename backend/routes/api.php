<?php

use Controllers\AnalyzeController;

$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$method = $_SERVER['REQUEST_METHOD'];

if (strpos($uri, '/analyze') !== false && $method === 'POST') {
    $controller = new AnalyzeController();
    $controller->analyze();
    exit;
}

echo json_encode([
    "error" => "Not Found",
    "uri" => $uri
]);
?>