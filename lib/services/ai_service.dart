import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'settings_service.dart';

class AIService {
  // 保持旧的非流式方法以备不时之需（可选）
  Future<String> solveProblem(File imageFile, SettingsService settings) async {
    // ... (existing implementation)
    // 为了简单起见，我们主要关注流式实现。如果需要，可以保留此方法的原始内容。
    // 但鉴于我们正在转向流式，我将在此使用流式方法并等待其完成。
    final stream = streamSolveProblem(imageFile, settings);
    return stream.join();
  }

  Stream<String> streamChat(List<Map<String, dynamic>> messages, SettingsService settings) async* {
    if (settings.apiKey.isEmpty) {
      throw Exception('API Key is missing. Please set it in Settings.');
    }

    final url = Uri.parse('${settings.baseUrl}/chat/completions');

    final body = jsonEncode({
      'model': settings.model,
      'messages': messages,
      'max_tokens': 4096,
      'stream': true,
    });

    final request = http.Request('POST', url);
    request.headers.addAll({
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${settings.apiKey}',
    });
    request.body = body;

    try {
      final client = http.Client();
      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode != 200) {
        final responseBody = await streamedResponse.stream.bytesToString();
        throw Exception('API Error: ${streamedResponse.statusCode} - $responseBody');
      }

      final stream = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in stream) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6).trim();
          if (data == '[DONE]') break;
          
          try {
            final json = jsonDecode(data);
            if (json['choices'] != null && json['choices'].isNotEmpty) {
              final delta = json['choices'][0]['delta'];
              if (delta != null && delta['content'] != null) {
                yield delta['content'] as String;
              }
            }
          } catch (e) {
            // Ignore JSON parse errors for incomplete chunks
            debugPrint('Error parsing chunk: $e');
          }
        }
      }
      client.close();
    } catch (e) {
      throw Exception('Failed to connect to AI service: $e');
    }
  }

  Stream<String> streamSolveProblem(File imageFile, SettingsService settings) async* {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final String mimeType = 'image/jpeg';

    final messages = [
      {
        'role': 'system',
        'content': settings.systemPrompt,
      },
      {
        'role': 'user',
        'content': [
          {
            'type': 'text',
            'text': 'Please solve the problem in this image. Use standard LaTeX for math formulas (e.g., \$E=mc^2\$ for inline, \$\$E=mc^2\$\$ for block).',
          },
          {
            'type': 'image_url',
            'image_url': {
              'url': 'data:$mimeType;base64,$base64Image',
            },
          },
        ],
      },
    ];

    yield* streamChat(messages, settings);
  }
}
