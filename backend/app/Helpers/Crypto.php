<?php
namespace Helpers;

class Crypto {
    // Cambiamos al modo GCM
    private const CIPHER = 'aes-256-gcm';

    public static function encrypt(?string $texto): ?string {
        if (empty($texto)) return null;

        $key = env('APP_KEY');
        if (empty($key)) {
            throw new \Exception("APP_KEY no está configurada en el .env");
        }

        // El IV para GCM suele ser de 12 bytes
        $ivlen = openssl_cipher_iv_length(self::CIPHER);
        $iv = openssl_random_pseudo_bytes($ivlen);
        $tag = ""; // OpenSSL llenará esta variable con la firma de autenticación

        // Encriptamos pasando la variable $tag por referencia
        $ciphertext_raw = openssl_encrypt($texto, self::CIPHER, $key, OPENSSL_RAW_DATA, $iv, $tag);

        // Concatenamos: IV (12 bytes) + Tag (16 bytes) + Texto Cifrado, y codificamos
        return base64_encode($iv . $tag . $ciphertext_raw);
    }

    public static function decrypt(?string $textoCifrado): ?string {
        if (empty($textoCifrado)) return null;

        $key = env('APP_KEY');
        $c = base64_decode($textoCifrado);
        $ivlen = openssl_cipher_iv_length(self::CIPHER);
        
        // GCM usa un tag de autenticación de 16 bytes estándar
        $taglen = 16; 

        // Extraemos las partes exactamente en el orden en que las unimos
        $iv = substr($c, 0, $ivlen);
        $tag = substr($c, $ivlen, $taglen);
        $ciphertext_raw = substr($c, $ivlen + $taglen);

        // Desencriptamos. Si el tag no coincide (alguien modificó la BD), esto devuelve false
        $decrypted = openssl_decrypt($ciphertext_raw, self::CIPHER, $key, OPENSSL_RAW_DATA, $iv, $tag);

        return $decrypted !== false ? $decrypted : null;
    }
}
?>