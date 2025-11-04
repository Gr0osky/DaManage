import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class ApiClient {
  ApiClient._internal();
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  final _storage = const FlutterSecureStorage();
  String get baseUrl {
    const env = String.fromEnvironment('API_BASE_URL');
    if (env.isNotEmpty) return env;
    if (kIsWeb) return 'http://localhost:3000';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:3000';
      // iOS simulator and desktop
      return 'http://localhost:3000';
    } catch (_) {
      return 'http://localhost:3000';
    }
  }

  String? _token;

  Future<void> loadToken() async {
    _token = await _storage.read(key: 'jwt');
  }

  Future<void> setToken(String token) async {
    _token = token;
    await _storage.write(key: 'jwt', value: token);
  }

  Future<void> clearToken() async {
    _token = null;
    await _storage.delete(key: 'jwt');
  }

  Map<String, String> _headers({bool auth = false}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<String> login(String username, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: _headers(),
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final token = data['token'] as String?;
      if (token == null) {
        throw Exception('No token in response');
      }
      await setToken(token);
      return token;
    }
    final msg = _safeError(res.body);
    throw Exception(msg);
  }

  Future<void> signup(String username, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/signup'),
      headers: _headers(),
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (res.statusCode != 201) {
      final msg = _safeError(res.body);
      throw Exception(msg);
    }
  }

  Future<List<Map<String, dynamic>>> listVault() async {
    final res = await http.get(
      Uri.parse('$baseUrl/vault'),
      headers: _headers(auth: true),
    );
    if (res.statusCode == 200) {
      final arr = jsonDecode(res.body) as List<dynamic>;
      return arr.cast<Map<String, dynamic>>();
    }
    final msg = _safeError(res.body);
    throw Exception(msg);
  }

  Future<void> addVaultItem({
    required String title,
    String? username,
    String? url,
    required String password,
    String? notes,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/vault'),
      headers: _headers(auth: true),
      body: jsonEncode({
        'title': title,
        'username': username,
        'url': url,
        'password': password,
        'notes': notes,
      }),
    );
    if (res.statusCode != 201) {
      final msg = _safeError(res.body);
      throw Exception(msg);
    }
  }

  Future<void> deleteVaultItem(int id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/vault/$id'),
      headers: _headers(auth: true),
    );
    if (res.statusCode != 200) {
      final msg = _safeError(res.body);
      throw Exception(msg);
    }
  }

  String _safeError(String body) {
    try {
      final m = jsonDecode(body) as Map<String, dynamic>;
      final e = m['error'];
      if (e is String) return e;
      return 'Request failed';
    } catch (_) {
      return 'Request failed';
    }
  }
}
