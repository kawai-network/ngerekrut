library;

import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> loadEnv() async {
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Development setup may rely on --dart-define only.
  }
}

String readConfig(String key) {
  const dartDefineValues = {
    'CLOUDFLARE_ACCOUNT_ID': String.fromEnvironment('CLOUDFLARE_ACCOUNT_ID'),
    'CLOUDFLARE_KV_NAMESPACE_ID': String.fromEnvironment(
      'CLOUDFLARE_KV_NAMESPACE_ID',
    ),
    'CLOUDFLARE_API_TOKEN': String.fromEnvironment('CLOUDFLARE_API_TOKEN'),
    'OPENAI_API_KEY': String.fromEnvironment('OPENAI_API_KEY'),
    'HUGGINGFACE_TOKEN': String.fromEnvironment('HUGGINGFACE_TOKEN'),
    'LIBSQL_URL': String.fromEnvironment('LIBSQL_URL'),
    'LIBSQL_URL_TOKEN': String.fromEnvironment('LIBSQL_URL_TOKEN'),
    'JOBSEEKER_USER_ID': String.fromEnvironment('JOBSEEKER_USER_ID'),
    'RECRUITER_USER_ID': String.fromEnvironment('RECRUITER_USER_ID'),
  };

  final envValue = dotenv.isInitialized ? dotenv.maybeGet(key) : null;
  if (envValue != null && envValue.isNotEmpty) {
    return envValue;
  }
  return dartDefineValues[key] ?? '';
}
