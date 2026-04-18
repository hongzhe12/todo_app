import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({this.baseUrl = 'http://127.0.0.1:8000/o/app'});

  final String baseUrl;

  String get _todosEndpoint => '$baseUrl/api/todos/';

  Future<List<Map<String, dynamic>>> fetchTodos() async {
    final uri = Uri.parse(_todosEndpoint);
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('加载失败: ${response.statusCode}');
    }

    final decodedBody = utf8.decode(response.bodyBytes); // 中文解码
    final data = jsonDecode(decodedBody) as List<dynamic>;
    return data
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> createTodo({
    required String title,
    bool completed = false,
  }) async {
    final response = await http.post(
      Uri.parse(_todosEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'title': title, 'completed': completed}),
    );

    if (response.statusCode != 201) {
      throw Exception('新增失败: ${response.statusCode}');
    }

    final decodedBody = utf8.decode(response.bodyBytes);
    return Map<String, dynamic>.from(jsonDecode(decodedBody) as Map);
  }

  Future<Map<String, dynamic>> updateTodo(
    int id, {
    String? title,
    bool? completed,
  }) async {
    final payload = <String, dynamic>{};
    if (title != null) payload['title'] = title;
    if (completed != null) payload['completed'] = completed;

    final response = await http.patch(
      Uri.parse('$_todosEndpoint$id/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception('更新失败: ${response.statusCode}');
    }

    final decodedBody = utf8.decode(response.bodyBytes);
    return Map<String, dynamic>.from(jsonDecode(decodedBody) as Map);
  }

  Future<void> deleteTodo(int id) async {
    final response = await http.delete(Uri.parse('$_todosEndpoint$id/'));

    if (response.statusCode != 204) {
      throw Exception('删除失败: ${response.statusCode}');
    }
  }
}
