<?php

function env($key) {
    static $vars = null;

    if ($vars === null) {
        $vars = parse_ini_file(__DIR__ . '/../.env');
    }

    return $vars[$key] ?? null;
}

?>