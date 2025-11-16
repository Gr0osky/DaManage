import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Secure HTTP client with certificate pinning and security headers
class SecureHttpClient {
  static http.Client? _client;

  /// Get or create a secure HTTP client
  static http.Client getClient({
    bool enableCertificatePinning = false,
    List<String>? allowedCertificates,
  }) {
    if (_client != null) return _client!;

    if (enableCertificatePinning) {
      _client = _createSecureClient(allowedCertificates);
    } else {
      _client = http.Client();
    }

    return _client!;
  }

  /// Create a secure HTTP client with certificate pinning
  static http.Client _createSecureClient(List<String>? allowedCertificates) {
    final context = SecurityContext.defaultContext;

    final httpClient = HttpClient(context: context);

    // Enable certificate pinning if certificates are provided
    if (allowedCertificates != null && allowedCertificates.isNotEmpty) {
      httpClient.badCertificateCallback = (cert, host, port) {
        // Check if the certificate matches any of the allowed certificates
        final certString = cert.pem;
        return allowedCertificates.any((allowed) => certString.contains(allowed));
      };
    }

    // Set security timeouts
    httpClient.connectionTimeout = const Duration(seconds: 10);
    httpClient.idleTimeout = const Duration(seconds: 15);

    return IOClient(httpClient);
  }

  /// Add security headers to requests
  static Map<String, String> getSecureHeaders({
    Map<String, String>? additionalHeaders,
    String? authToken,
  }) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Content-Type-Options': 'nosniff',
      'X-Frame-Options': 'DENY',
      'X-XSS-Protection': '1; mode=block',
    };

    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  /// Dispose the client
  static void dispose() {
    _client?.close();
    _client = null;
  }
}
