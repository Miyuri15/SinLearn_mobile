import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/paper_config.dart';

class PaperConfigService {
  final String baseUrl;

  PaperConfigService(this.baseUrl);

  Future<List<PaperConfig>> fetchConfigs(String sessionId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/evaluation/sessions/$sessionId/paper-config'),
      );

      if (res.statusCode == 200) {
        // Check if body is empty
        if (res.body.isEmpty) return [];

        try {
          final decoded = jsonDecode(res.body);
          if (decoded is List) {
            return decoded.map((e) => PaperConfig.fromJson(e)).toList();
          }
        } catch (e) {
          // If JSON decode fails (e.g. HTML response), return empty list
          print('Error decoding paper config: $e');
          return [];
        }
      }
      return [];
    } catch (e) {
      print('Error fetching paper config: $e');
      return [];
    }
  }

  Future<void> confirmConfigs(
      String sessionId, List<PaperConfig> configs) async {
    await http.post(
      Uri.parse(
          '$baseUrl/evaluation/sessions/$sessionId/paper-config/confirm'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'paper_configs': configs.map((e) => e.toJson()).toList(),
      }),
    );
  }
}
