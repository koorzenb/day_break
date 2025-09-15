import 'package:http/http.dart' as http;

/// Wrapper around http.Client for testability
class HttpClientWrapper {
  final http.Client _client;

  HttpClientWrapper([http.Client? client]) : _client = client ?? http.Client();

  Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
    return _client.get(url, headers: headers);
  }

  void close() {
    _client.close();
  }
}
