import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/paper_config.dart';

class PaperConfigService {
  final String baseUrl;

  PaperConfigService(this.baseUrl);

  Future<List<PaperConfig>> fetchConfigs(String sessionId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/evaluation/sessions/$sessionId/paper-config'),
    );

    final data = jsonDecode(res.body) as List;
    return data.map((e) => PaperConfig.fromJson(e)).toList();
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
