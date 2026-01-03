import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../models/voice_models.dart';

class VoiceService {
  static Future<VoiceQAResponse> postVoiceQA({
    required MultipartFile audio,
    required String sessionId,
    List<String> resourceIds = const [],
    int topK = 3,
  }) async {
    final formData = FormData.fromMap({
      "audio": audio,
      "session_id": sessionId,
      if (resourceIds.isNotEmpty)
        "resource_ids": resourceIds.join(","),
    });

    final res = await ApiClient.dio.post(
      "/voice/qa",
      queryParameters: {"top_k": topK},
      data: formData,
    );

    return VoiceQAResponse.fromJson(res.data);
  }
}
