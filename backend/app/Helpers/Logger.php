<?php

namespace Helpers;

class Logger {

    public static function log($data) {

        $file = __DIR__ . '/../../storage/logs/app.log';

        file_put_contents(
            $file,
            json_encode($data) . PHP_EOL,
            FILE_APPEND
        );
    }
}

?>