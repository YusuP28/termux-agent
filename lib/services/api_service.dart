import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/provider.dart';

class ApiService {
  static const Duration _timeout = Duration(seconds: 60);

  static Future<String> sendMessage({
    required Provider provider,
    required String apiKey,
    required String model,
    required List<Map<String, String>> messages,
    double temperature = 0.7,
    int maxTokens = 4096,
  }) async {
    try {
      final url = Uri.parse('${provider.baseUrl}/chat/completions');
      
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      // Add authorization based on provider
      if (provider.authType == AuthType.apiKey && provider.requiresApiKey) {
        headers['Authorization'] = 'Bearer $apiKey';
      } else if (provider.authType == AuthType.oauth && apiKey.isNotEmpty) {
        headers['Authorization'] = 'Bearer $apiKey';
      }

      // Special handling for Anthropic
      if (provider.id == 'anthropic') {
        return _sendAnthropicRequest(url, headers, model, messages, maxTokens);
      }

      // Special handling for search providers
      if (provider.category.name == 'search') {
        return _sendSearchRequest(provider, apiKey, model, messages);
      }

      // Standard OpenAI-compatible format
      final body = jsonEncode({
        'model': model,
        'messages': messages.map((m) => {'role': m['role'], 'content': m['content']}).toList(),
        'temperature': temperature,
        'max_tokens': maxTokens,
        'stream': false,
      });

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      ).timeout(_timeout);

      return _handleResponse(response, provider.id);
    } catch (e) {
      throw Exception('Gagal mengirim pesan: $e');
    }
  }

  static Future<String> _sendAnthropicRequest(
    Uri url,
    Map<String, String> headers,
    String model,
    List<Map<String, String>> messages,
    int maxTokens,
  ) async {
    // Convert messages to Anthropic format
    final systemPrompt = messages.firstWhere(
      (m) => m['role'] == 'system',
      orElse: () => {'content': ''},
    )['content'];
    
    final userMessages = messages
        .where((m) => m['role'] != 'system')
        .map((m) => {'role': m['role'], 'content': m['content']})
        .toList();

    final body = jsonEncode({
      'model': model,
      'max_tokens': maxTokens,
      'messages': userMessages,
      if (systemPrompt.isNotEmpty) 'system': systemPrompt,
    });

    headers['anthropic-version'] = '2023-06-01';
    headers['x-api-key'] = headers['Authorization']?.replaceFirst('Bearer ', '') ?? '';

    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: headers,
      body: body,
    ).timeout(_timeout);

    return _handleResponse(response, 'anthropic');
  }

  static Future<String> _sendSearchRequest(
    Provider provider,
    String apiKey,
    String model,
    List<Map<String, String>> messages,
  ) async {
    final query = messages.last['content'] ?? '';
    
    if (provider.id == 'brave_search') {
      final url = Uri.parse('${provider.baseUrl}/web/search?q=${Uri.encodeComponent(query)}');
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'X-Subscription-Token': apiKey,
        },
      ).timeout(const Duration(seconds: 30));
      
      final data = jsonDecode(response.body);
      final results = (data['web']['results'] as List?)?.take(5).map((r) => 
        '- ${r['title']}: ${r['description']} (${r['url']})'
      ).join('\n\n') ?? 'Tidak ada hasil ditemukan.';
      
      return 'Hasil pencarian Brave:\n\n$results';
    } else if (provider.id == 'tavily') {
      final url = Uri.parse('${provider.baseUrl}/search');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'api_key': apiKey,
          'query': query,
          'search_depth': 'basic',
          'max_results': 5,
        }),
      ).timeout(const Duration(seconds: 30));
      
      final data = jsonDecode(response.body);
      final results = (data['results'] as List?)?.take(5).map((r) => 
        '- ${r['title']}: ${r['content']} (${r['url']})'
      ).join('\n\n') ?? 'Tidak ada hasil ditemukan.';
      
      return 'Hasil pencarian Tavily:\n\n$results';
    }
    
    return 'Provider pencarian tidak didukung.';
  }

  static String _handleResponse(http.Response response, String providerId) {
    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        
        // Handle different response formats
        if (providerId == 'anthropic') {
          return data['content']?[0]['text'] ?? 'Tidak ada respons.';
        }
        
        // OpenAI-compatible format
        final choices = data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          return choices.first['message']?['content'] ?? 
                 choices.first['text'] ?? 
                 'Tidak ada konten respons.';
        }
        
        return 'Format respons tidak dikenali.';
      } catch (e) {
        return 'Gagal memparsing respons: $e';
      }
    } else {
      String errorMsg;
      try {
        final errorData = jsonDecode(response.body);
        errorMsg = errorData['error']?['message'] ?? 
                   errorData['error']?.toString() ?? 
                   response.body;
      } catch (_) {
        errorMsg = response.body;
      }
      
      switch (response.statusCode) {
        case 401:
          throw Exception('API Key tidak valid atau sudah kedaluwarsa.');
        case 429:
          throw Exception('Rate limit tercapai. Coba lagi nanti.');
        case 404:
          throw Exception('Model tidak ditemukan.');
        case 500:
          throw Exception('Error server penyedia. Coba lagi nanti.');
        default:
          throw Exception('Error API (${response.statusCode}): $errorMsg');
      }
    }
  }
}