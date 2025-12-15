import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'settings_service.dart';

class AIService {
  // 保持旧的非流式方法以备不时之需（可选）
  Future<String> solveProblem(Uint8List imageBytes, SettingsService settings) async {
    // ... (existing implementation)
    // 为了简单起见，我们主要关注流式实现。如果需要，可以保留此方法的原始内容。
    // 但鉴于我们正在转向流式，我将在此使用流式方法并等待其完成。
    final stream = streamSolveProblem(imageBytes, settings);
    return stream.join();
  }

  Stream<String> streamChat(List<Map<String, dynamic>> messages, SettingsService settings) async* {
    Uri url;
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    String body;

    // Determine if we are using BYOK (Bring Your Own Key) or Managed Service
    if (settings.apiKey.isNotEmpty) {
      // Use Custom API Key (Direct Call)
      url = Uri.parse('${settings.baseUrl}/chat/completions');
      headers['Authorization'] = 'Bearer ${settings.apiKey}';
      
      body = jsonEncode({
        'model': settings.model,
        'messages': messages,
        'max_tokens': 16384, // Increased limit for thinking models
        'stream': true,
      });
    } else {
      // Use Managed Service (Supabase Edge Function)
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        throw Exception('Please login to use the AI service or provide your own API Key in Settings.');
      }
      
      // Construct Edge Function URL
      // Note: Typically <project_url>/functions/v1/<function_name>
      // We can get projectUrl from the client instance if needed, or hardcode/config it.
      // But Supabase.instance.client doesn't expose projectUrl publicly in all versions.
      // We will assume it's derived from the current instance's configuration or settings.
      // For now, let's try to deduce it or rely on a setting.
      // A safe bet is to use the functions invoke URL pattern if we knew the project ID.
      // Let's assume we can get it from Supabase.instance.client.functionsUrl (if available) or config.
      // Actually, let's use the standard pattern.
      // We can inspect Supabase.instance.client.
      
      // HACK: We can try to use the 'functions' client to get the URL, but it's private.
      // Let's assume the user has configured the URL correctly in main.dart and we can access it.
      // Or we can just use the Supabase.instance.client.supabaseUrl (which is the project URL).
      // Note: supabaseUrl is not directly exposed as a property on SupabaseClient in older versions, 
      // but in v2 it might be.
      // Let's try to access it via internal getter or just assume it is configured in a global constant if needed.
      // Wait, in v2 `Supabase.instance.client` does not have `supabaseUrl` public property easily?
      // It has `auth`, `functions`, etc.
      // Let's try to use `functions.invoke` just to get the URL? No.
      
      // Simplest way: The Supabase URL is usually passed in main.dart.
      // I will assume we can access it or I will hardcode it for this implementation based on the `supabase_get_project` result I got earlier.
      // Project URL: https://srfdbrsxytouwkysdyzs.supabase.co
      
      const projectUrl = 'https://srfdbrsxytouwkysdyzs.supabase.co';
      url = Uri.parse('$projectUrl/functions/v1/gemini-chat');
      
      headers['Authorization'] = 'Bearer ${session.accessToken}';
      
      // The Edge Function expects 'messages' and 'model'
      body = jsonEncode({
        'messages': messages,
        'model': settings.model,
      });
    }

    final request = http.Request('POST', url);
    request.headers.addAll(headers);
    request.body = body;

    try {
      final client = http.Client();
      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode != 200) {
        final responseBody = await streamedResponse.stream.bytesToString();
        // Check for specific error messages from our Edge Function
        try {
            final jsonError = jsonDecode(responseBody);
            if (jsonError['error'] != null) {
                 throw Exception(jsonError['error']);
            }
        } catch (_) {}
        throw Exception('Service Error: ${streamedResponse.statusCode} - $responseBody');
      }

      final stream = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in stream) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6).trim();
          if (data == '[DONE]') break;
          
          try {
            debugPrint('Raw Chunk Data: $data'); // DEBUG LOG
            final json = jsonDecode(data);
            if (json['choices'] != null && json['choices'].isNotEmpty) {
              final choice = json['choices'][0];
              final delta = choice['delta'];
              
              if (delta != null) {
                 // Handle standard content
                 if (delta['content'] != null) {
                   yield delta['content'] as String;
                 }
                 // Handle potential reasoning_content for thinking models
                 else if (delta['reasoning_content'] != null) {
                   yield delta['reasoning_content'] as String;
                 }
                 // Handle standard Gemini format leak (parts -> text)
                 else if (delta['parts'] != null && (delta['parts'] as List).isNotEmpty) {
                    final part = delta['parts'][0];
                    if (part['text'] != null) {
                      yield part['text'] as String;
                    }
                 }
                 // Handle direct text field (some proxies)
                 else if (delta['text'] != null) {
                   yield delta['text'] as String;
                 }
               }
              
              // Check for finish_reason
              if (choice['finish_reason'] != null) {
                debugPrint('Finish Reason: ${choice['finish_reason']}');
              }
            } else if (json['error'] != null) {
                throw Exception(json['error']);
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

  Stream<String> streamSolveProblem(Uint8List imageBytes, SettingsService settings) async* {
    final base64Image = base64Encode(imageBytes);
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
