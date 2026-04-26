import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiConexion {
  static const String URL_PRINCIPAL =
      'https://team-uni-apps.com/apiReclutamiento/public/index.php/analyze';

  static Future<Map<String, dynamic>> consulta(
      String userId, String conversationId, String message, String metadata) async {
    final response = await http.post(
      Uri.parse(URL_PRINCIPAL),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'user_id': userId,
        'conversation_id': conversationId,
        'message': message,
        'metadata': metadata,
      }),
    );

    print('[API] Status: ${response.statusCode}');
    print('[API] Body: ${response.body}');

    if (response.body.isEmpty) {
      throw Exception('El API devolvió una respuesta vacía (status: ${response.statusCode})');
    }

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      // Intentar parsear el error como JSON para obtener más detalle
      try {
        final errorBody = jsonDecode(response.body);
        throw Exception('Error API ${response.statusCode}: ${errorBody['message'] ?? response.body}');
      } catch (_) {
        throw Exception('Error API ${response.statusCode}: ${response.body}');
      }
    }
  }
}
