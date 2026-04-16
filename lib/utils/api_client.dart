import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({this.baseUrl = 'http://127.0.0.1:8000'});

  final String baseUrl;

  Future<List<Map<String, dynamic>>> fetchTodos() async {
    final uri = Uri.parse('$baseUrl/api/todos');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('请求失败: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final data =
        (json['data'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    return data;
  }
}
