/// Custom exception types for better error handling
library;

/// Base exception class for the app
class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

/// Network-related exceptions
class NetworkException extends AppException {
  const NetworkException(super.message, {super.cause});

  factory NetworkException.connectionFailed() {
    return const NetworkException(
      'Koneksi internet terputus. Periksa WiFi/data Anda.',
    );
  }

  factory NetworkException.timeout() {
    return const NetworkException(
      'Waktu habis. Server terlalu lama merespons.',
    );
  }

  factory NetworkException.serverError() {
    return const NetworkException(
      'Server sedang bermasalah. Coba lagi nanti.',
    );
  }
}

/// Authentication exceptions
class AuthException extends AppException {
  const AuthException(super.message, {super.cause});

  factory AuthException.unauthorized() {
    return const AuthException(
      'Sesi Anda telah berakhir. Silakan login kembali.',
    );
  }

  factory AuthException.forbidden() {
    return const AuthException(
      'Anda tidak memiliki izin untuk aksi ini.',
    );
  }
}

/// Data-related exceptions
class DataException extends AppException {
  const DataException(super.message, {super.cause});

  factory DataException.notFound() {
    return const DataException(
      'Data tidak ditemukan. Mungkin sudah dihapus.',
    );
  }

  factory DataException.invalidData() {
    return const DataException(
      'Data tidak valid. Silakan periksa kembali.',
    );
  }

  factory DataException.conflict() {
    return const DataException(
      'Konflik data. Mungkin data sudah ada.',
    );
  }
}

/// Validation exceptions
class ValidationException extends AppException {
  const ValidationException(super.message, {super.cause});

  factory ValidationException.requiredField(String fieldName) {
    return ValidationException('$fieldName tidak boleh kosong.');
  }

  factory ValidationException.invalidFormat(String fieldName) {
    return ValidationException('Format $fieldName tidak valid.');
  }
}
