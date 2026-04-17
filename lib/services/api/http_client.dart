import 'package:http/http.dart' as http;

class HttpClientWithSSL {
  static http.Client create() {
    // For web, just use regular client
    return http.Client();
  }
}