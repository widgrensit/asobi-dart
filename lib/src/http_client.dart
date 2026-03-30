import 'dart:convert';
import 'package:http/http.dart' as http;

class AsobiHttpClient {
  final String baseUrl;
  String? sessionToken;

  AsobiHttpClient(this.baseUrl);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (sessionToken != null) 'Authorization': 'Bearer $sessionToken',
      };

  Future<Map<String, dynamic>> get(String path,
      {Map<String, String>? query}) async {
    final uri = _buildUri(path, query);
    final response = await http.get(uri, headers: _headers);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(String path,
      {Map<String, dynamic>? body}) async {
    final uri = _buildUri(path);
    final response = await http.post(uri,
        headers: _headers, body: body != null ? jsonEncode(body) : null);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> put(String path,
      {Map<String, dynamic>? body}) async {
    final uri = _buildUri(path);
    final response = await http.put(uri,
        headers: _headers, body: body != null ? jsonEncode(body) : null);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> delete(String path,
      {Map<String, dynamic>? body}) async {
    final uri = _buildUri(path);
    final response = await http.delete(uri,
        headers: _headers, body: body != null ? jsonEncode(body) : null);
    return _handleResponse(response);
  }

  Uri _buildUri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('$baseUrl$path');
    if (query != null && query.isNotEmpty) {
      return uri.replace(queryParameters: query);
    }
    return uri;
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};

    if (response.statusCode >= 400) {
      throw AsobiException(
        response.statusCode,
        body['error'] as String? ?? 'HTTP ${response.statusCode}',
      );
    }

    return body;
  }
}

class AsobiException implements Exception {
  final int statusCode;
  final String message;

  AsobiException(this.statusCode, this.message);

  @override
  String toString() => 'AsobiException($statusCode): $message';
}
