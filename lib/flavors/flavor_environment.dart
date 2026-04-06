/// Environment configuration for different app flavors
class FlavorEnvironment {
  final String apiBaseUrl;
  final String? cloudflareAccountId;
  final String? cloudflareKvNamespaceId;
  final String? cloudflareApiToken;
  final String? openaiApiKey;

  const FlavorEnvironment({
    required this.apiBaseUrl,
    this.cloudflareAccountId,
    this.cloudflareKvNamespaceId,
    this.cloudflareApiToken,
    this.openaiApiKey,
  });

  static FlavorEnvironment fromConfig() {
    return FlavorEnvironment(
      apiBaseUrl: const String.fromEnvironment('API_BASE_URL', defaultValue: ''),
      cloudflareAccountId: const String.fromEnvironment('CLOUDFLARE_ACCOUNT_ID'),
      cloudflareKvNamespaceId: const String.fromEnvironment('CLOUDFLARE_KV_NAMESPACE_ID'),
      cloudflareApiToken: const String.fromEnvironment('CLOUDFLARE_API_TOKEN'),
      openaiApiKey: const String.fromEnvironment('OPENAI_API_KEY'),
    );
  }
}
