import 'provider.dart';

final List<Provider> allProviders = [
  // KATEGORI: API Key
  Provider(
    id: 'nvidia_nim',
    name: 'NVIDIA NIM',
    category: ProviderCategory.apiKey,
    authType: AuthType.apiKey,
    baseUrl: 'https://integrate.api.nvidia.com/v1',
    defaultModel: 'nvidia/nemotron-3-ultra-550b-a55b',
    models: [
      'nvidia/nemotron-3-ultra-550b-a55b',
      'meta/llama-3.1-70b-instruct',
      'meta/llama-3.1-405b-instruct',
      'mistralai/mixtral-8x22b-instruct',
      'google/gemma-2-27b-it',
    ],
    requiresApiKey: true,
    apiKeyEnvVar: 'NVIDIA_API_KEY',
  ),
  Provider(
    id: 'groq',
    name: 'Groq',
    category: ProviderCategory.apiKey,
    authType: AuthType.apiKey,
    baseUrl: 'https://api.groq.com/openai/v1',
    defaultModel: 'llama-3.3-70b-versatile',
    models: [
      'llama-3.3-70b-versatile',
      'llama-3.1-70b-versatile',
      'llama-3.1-8b-instant',
      'mixtral-8x7b-32768',
      'gemma2-9b-it',
    ],
    requiresApiKey: true,
    apiKeyEnvVar: 'GROQ_API_KEY',
  ),
  Provider(
    id: 'openai',
    name: 'OpenAI',
    category: ProviderCategory.apiKey,
    authType: AuthType.apiKey,
    baseUrl: 'https://api.openai.com/v1',
    defaultModel: 'gpt-4o',
    models: [
      'gpt-4o',
      'gpt-4o-mini',
      'gpt-4-turbo',
      'gpt-3.5-turbo',
      'o1-preview',
      'o1-mini',
    ],
    requiresApiKey: true,
    apiKeyEnvVar: 'OPENAI_API_KEY',
  ),
  Provider(
    id: 'anthropic',
    name: 'Anthropic',
    category: ProviderCategory.apiKey,
    authType: AuthType.apiKey,
    baseUrl: 'https://api.anthropic.com/v1',
    defaultModel: 'claude-3-5-sonnet-20241022',
    models: [
      'claude-3-5-sonnet-20241022',
      'claude-3-5-haiku-20241022',
      'claude-3-opus-20240229',
      'claude-3-sonnet-20240229',
    ],
    requiresApiKey: true,
    apiKeyEnvVar: 'ANTHROPIC_API_KEY',
  ),
  Provider(
    id: 'deepseek',
    name: 'DeepSeek',
    category: ProviderCategory.apiKey,
    authType: AuthType.apiKey,
    baseUrl: 'https://api.deepseek.com/v1',
    defaultModel: 'deepseek-chat',
    models: [
      'deepseek-chat',
      'deepseek-coder',
    ],
    requiresApiKey: true,
    apiKeyEnvVar: 'DEEPSEEK_API_KEY',
  ),
  Provider(
    id: 'openrouter',
    name: 'OpenRouter',
    category: ProviderCategory.gateway,
    authType: AuthType.apiKey,
    baseUrl: 'https://openrouter.ai/api/v1',
    defaultModel: 'openai/gpt-4o',
    models: [
      'openai/gpt-4o',
      'anthropic/claude-3.5-sonnet',
      'meta-llama/llama-3.1-405b-instruct',
      'google/gemini-pro-1.5',
      'mistralai/mixtral-8x22b',
    ],
    requiresApiKey: true,
    apiKeyEnvVar: 'OPENROUTER_API_KEY',
  ),
  Provider(
    id: 'mistral',
    name: 'Mistral AI',
    category: ProviderCategory.apiKey,
    authType: AuthType.apiKey,
    baseUrl: 'https://api.mistral.ai/v1',
    defaultModel: 'mistral-large-latest',
    models: [
      'mistral-large-latest',
      'mistral-medium-latest',
      'mistral-small-latest',
      'codestral-latest',
    ],
    requiresApiKey: true,
    apiKeyEnvVar: 'MISTRAL_API_KEY',
  ),
  Provider(
    id: 'together',
    name: 'Together AI',
    category: ProviderCategory.apiKey,
    authType: AuthType.apiKey,
    baseUrl: 'https://api.together.xyz/v1',
    defaultModel: 'meta-llama/Meta-Llama-3.1-405B-Instruct-Turbo',
    models: [
      'meta-llama/Meta-Llama-3.1-405B-Instruct-Turbo',
      'meta-llama/Llama-3.3-70B-Instruct-Turbo',
      'Qwen/Qwen2.5-72B-Instruct-Turbo',
      'mistralai/Mixtral-8x22B-Instruct-v0.1',
    ],
    requiresApiKey: true,
    apiKeyEnvVar: 'TOGETHER_API_KEY',
  ),

  // KATEGORI: Lokal
  Provider(
    id: 'ollama',
    name: 'Ollama',
    category: ProviderCategory.local,
    authType: AuthType.none,
    baseUrl: 'http://localhost:11434/v1',
    defaultModel: 'llama3.1',
    models: [
      'llama3.1',
      'llama3.2',
      'mistral',
      'codellama',
      'phi3',
      'qwen2.5',
    ],
    requiresApiKey: false,
  ),
  Provider(
    id: 'lm_studio',
    name: 'LM Studio',
    category: ProviderCategory.local,
    authType: AuthType.none,
    baseUrl: 'http://localhost:1234/v1',
    defaultModel: 'local-model',
    models: [
      'local-model',
    ],
    requiresApiKey: false,
  ),

  // KATEGORI: Tanpa Autentikasi
  Provider(
    id: 'duckduckgo',
    name: 'DuckDuckGo AI',
    category: ProviderCategory.noAuth,
    authType: AuthType.none,
    baseUrl: 'https://duckduckgo.com/duckchat/v1',
    defaultModel: 'gpt-4o-mini',
    models: [
      'gpt-4o-mini',
      'claude-3-haiku',
      'llama-3.1-70b',
      'mixtral-8x7b',
    ],
    requiresApiKey: false,
  ),
  Provider(
    id: 'ai_horde',
    name: 'AI Horde',
    category: ProviderCategory.noAuth,
    authType: AuthType.none,
    baseUrl: 'https://aihorde.net/api/v1',
    defaultModel: 'koboldcpp',
    models: [
      'koboldcpp',
      'llama3',
      'mistral',
    ],
    requiresApiKey: false,
  ),

  // KATEGORI: OAuth
  Provider(
    id: 'claude_code',
    name: 'Claude Code',
    category: ProviderCategory.oauth,
    authType: AuthType.oauth,
    baseUrl: 'https://api.anthropic.com/v1',
    defaultModel: 'claude-3-5-sonnet-20241022',
    models: [
      'claude-3-5-sonnet-20241022',
      'claude-3-5-haiku-20241022',
    ],
    requiresApiKey: false,
  ),
  Provider(
    id: 'github_copilot',
    name: 'GitHub Copilot',
    category: ProviderCategory.oauth,
    authType: AuthType.oauth,
    baseUrl: 'https://api.githubcopilot.com',
    defaultModel: 'gpt-4o',
    models: [
      'gpt-4o',
      'gpt-4o-mini',
    ],
    requiresApiKey: false,
  ),

  // KATEGORI: Pencarian
  Provider(
    id: 'brave_search',
    name: 'Brave Search',
    category: ProviderCategory.search,
    authType: AuthType.apiKey,
    baseUrl: 'https://api.search.brave.com/res/v1',
    defaultModel: 'search',
    models: ['search'],
    requiresApiKey: true,
    apiKeyEnvVar: 'BRAVE_API_KEY',
  ),
  Provider(
    id: 'tavily',
    name: 'Tavily',
    category: ProviderCategory.search,
    authType: AuthType.apiKey,
    baseUrl: 'https://api.tavily.com',
    defaultModel: 'search',
    models: ['search'],
    requiresApiKey: true,
    apiKeyEnvVar: 'TAVILY_API_KEY',
  ),
];

// Helper functions
List<Provider> getProvidersByCategory(ProviderCategory category) {
  return allProviders.where((p) => p.category == category).toList();
}

List<ProviderCategory> get sortedCategories => ProviderCategory.values
  ..sort((a, b) => a.order.compareTo(b.order));

Provider? getProviderById(String id) {
  try {
    return allProviders.firstWhere((p) => p.id == id);
  } catch (_) {
    return null;
  }
}