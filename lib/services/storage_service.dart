import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _prefixProvider = 'provider_';
  static const String _prefixModel = 'model_';
  static const String _activeProviderKey = 'active_provider';
  static const String _activeModelKey = 'active_model';
  static const String _chatFontSizeKey = 'chat_font_size';

  // Singleton
  static SharedPreferences? _prefs;
  
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get _instance {
    if (_prefs == null) {
      throw Exception('StorageService belum diinisialisasi. Panggil init() terlebih dahulu.');
    }
    return _prefs!;
  }

  // Provider API Keys
  static String _providerKey(String providerId) => '${_prefixProvider}${providerId}_apikey';
  
  static Future<void> saveApiKey(String providerId, String apiKey) async {
    await _instance.setString(_providerKey(providerId), apiKey);
  }
  
  static String? getApiKey(String providerId) {
    return _instance.getString(_providerKey(providerId));
  }
  
  static Future<void> deleteApiKey(String providerId) async {
    await _instance.remove(_providerKey(providerId));
  }
  
  static bool hasApiKey(String providerId) {
    return _instance.containsKey(_providerKey(providerId));
  }

  // Active Provider
  static Future<void> setActiveProvider(String providerId) async {
    await _instance.setString(_activeProviderKey, providerId);
  }
  
  static String getActiveProvider({String defaultId = 'nvidia_nim'}) {
    return _instance.getString(_activeProviderKey) ?? defaultId;
  }

  // Active Model
  static String _modelKey(String providerId) => '${_prefixModel}${providerId}_model';
  
  static Future<void> setActiveModel(String providerId, String model) async {
    await _instance.setString(_modelKey(providerId), model);
  }
  
  static String getActiveModel(String providerId, {required String defaultModel}) {
    return _instance.getString(_modelKey(providerId)) ?? defaultModel;
  }

  // Chat Font Size
  static Future<void> setChatFontSize(double size) async {
    await _instance.setDouble(_chatFontSizeKey, size);
  }
  
  static double getChatFontSize({double defaultSize = 11.0}) {
    return _instance.getDouble(_chatFontSizeKey) ?? defaultSize;
  }

  // Get all saved API keys (for debugging/export)
  static Map<String, String> getAllApiKeys() {
    final keys = <String, String>{};
    for (final key in _instance.getKeys()) {
      if (key.startsWith(_prefixProvider) && key.endsWith('_apikey')) {
        final value = _instance.getString(key);
        if (value != null) {
          keys[key] = value;
        }
      }
    }
    return keys;
  }

  // Clear all data
  static Future<void> clearAll() async {
    await _instance.clear();
  }
}