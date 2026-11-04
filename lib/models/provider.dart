enum AuthType { oauth, apiKey, cookie, none }

enum ProviderCategory {
  apiKey,
  local,
  noAuth,
  oauth,
  gateway,
  search,
}

extension ProviderCategoryExt on ProviderCategory {
  String get label {
    switch (this) {
      case ProviderCategory.apiKey:
        return 'API Key';
      case ProviderCategory.local:
        return 'Lokal';
      case ProviderCategory.noAuth:
        return 'Tanpa Autentikasi';
      case ProviderCategory.oauth:
        return 'OAuth';
      case ProviderCategory.gateway:
        return 'Gateway';
      case ProviderCategory.search:
        return 'Pencarian';
    }
  }

  int get order {
    switch (this) {
      case ProviderCategory.apiKey:
        return 0;
      case ProviderCategory.local:
        return 1;
      case ProviderCategory.noAuth:
        return 2;
      case ProviderCategory.oauth:
        return 3;
      case ProviderCategory.gateway:
        return 4;
      case ProviderCategory.search:
        return 5;
    }
  }
}

class Provider {
  final String id;
  final String name;
  final ProviderCategory category;
  final AuthType authType;
  final String baseUrl;
  final String defaultModel;
  final List<String> models;
  final bool requiresApiKey;
  final String? apiKeyEnvVar;

  const Provider({
    required this.id,
    required this.name,
    required this.category,
    required this.authType,
    required this.baseUrl,
    required this.defaultModel,
    required this.models,
    this.requiresApiKey = false,
    this.apiKeyEnvVar,
  });

  String get authTypeLabel {
    switch (authType) {
      case AuthType.oauth:
        return 'OAuth';
      case AuthType.apiKey:
        return 'API Key';
      case AuthType.cookie:
        return 'Cookie';
      case AuthType.none:
        return 'Tanpa Auth';
    }
  }

  Provider copyWith({
    String? id,
    String? name,
    ProviderCategory? category,
    AuthType? authType,
    String? baseUrl,
    String? defaultModel,
    List<String>? models,
    bool? requiresApiKey,
    String? apiKeyEnvVar,
  }) {
    return Provider(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      authType: authType ?? this.authType,
      baseUrl: baseUrl ?? this.baseUrl,
      defaultModel: defaultModel ?? this.defaultModel,
      models: models ?? this.models,
      requiresApiKey: requiresApiKey ?? this.requiresApiKey,
      apiKeyEnvVar: apiKeyEnvVar ?? this.apiKeyEnvVar,
    );
  }
}