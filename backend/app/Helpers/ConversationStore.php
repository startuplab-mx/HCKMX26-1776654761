<?php

namespace Helpers;

class ConversationStore {

    public static function addMessage($conversationId, $message) {

        $file = __DIR__ . "/../../storage/conversations/conversation_$conversationId.json";

        if (!file_exists(dirname($file))) {
            mkdir(dirname($file), 0777, true);
        }

        $messages = [];

        if (file_exists($file)) {
            $messages = json_decode(file_get_contents($file), true);
        }

        $messages[] = $message;

        //Limitar a últimos 10 mensajes 
        $messages = array_slice($messages, -10);

        file_put_contents($file, json_encode($messages));
    }

    public static function getLastMessages($conversationId, $limit = 5) {

        $file = __DIR__ . "/../../storage/conversations/conversation_$conversationId.json";

        if (!file_exists($file)) return "";

        $messages = json_decode(file_get_contents($file), true);

        $last = array_slice($messages, -$limit);

        return implode("\n", $last);
    }
}

?>