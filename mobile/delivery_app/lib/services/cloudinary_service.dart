import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class CloudinaryService {
  static Future<String?> uploadImage(String filePath) async {
    final cloudName = AppConfig.cloudinaryCloudName;
    final uploadPreset = AppConfig.cloudinaryUploadPreset;

    if (cloudName.isEmpty || uploadPreset.isEmpty) {
      throw CloudinaryNotConfiguredException();
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamedResponse =
        await request.send().timeout(const Duration(seconds: 60));
    final responseBody = await streamedResponse.stream.bytesToString();
    final data = jsonDecode(responseBody) as Map<String, dynamic>;

    if (streamedResponse.statusCode == 200) {
      return data['secure_url'] as String?;
    }

    throw Exception(
      'Cloudinary error (${streamedResponse.statusCode}): ${data['error']?['message'] ?? responseBody}',
    );
  }
}

class CloudinaryNotConfiguredException implements Exception {
  @override
  String toString() =>
      'Cloudinary non configuré. Contactez l\'administrateur.';
}
