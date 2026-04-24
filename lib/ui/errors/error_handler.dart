/// Centralized error handling for the app
library;

import 'package:flutter/foundation.dart';
import 'app_exceptions.dart';

/// Error handler utility for converting exceptions to user-friendly messages
class ErrorHandler {
  ErrorHandler._();

  /// Convert any exception to a user-friendly message
  static String getUserMessage(dynamic error) {
    if (error is AppException) {
      return error.message;
    }

    if (error == null) {
      return 'Terjadi kesalahan tidak diketahui.';
    }

    final errorString = error.toString().toLowerCase();

    // Network errors
    if (errorString.contains('network') ||
        errorString.contains('socket') ||
        errorString.contains('connection') ||
        errorString.contains('fetch')) {
      return 'Koneksi internet terputus. Periksa WiFi/data Anda.';
    }
    if (errorString.contains('timeout')) {
      return 'Waktu habis. Server terlalu lama merespons.';
    }

    // HTTP errors
    if (errorString.contains('401') || errorString.contains('unauthorized')) {
      return 'Sesi Anda telah berakhir. Silakan login kembali.';
    }
    if (errorString.contains('403') || errorString.contains('forbidden')) {
      return 'Anda tidak memiliki izin untuk aksi ini.';
    }
    if (errorString.contains('404') || errorString.contains('not found')) {
      return 'Data tidak ditemukan. Mungkin sudah dihapus.';
    }
    if (errorString.contains('409') || errorString.contains('conflict')) {
      return 'Konflik data. Data mungkin sudah ada atau diubah oleh pengguna lain.';
    }
    if (errorString.contains('500') || errorString.contains('server error')) {
      return 'Server sedang bermasalah. Coba lagi nanti.';
    }
    if (errorString.contains('503')) {
      return 'Layanan sedang tidak tersedia. Coba lagi nanti.';
    }

    // File-related errors
    if (errorString.contains('file') && errorString.contains('not found')) {
      return 'File tidak ditemukan.';
    }
    if (errorString.contains('permission') && errorString.contains('file')) {
      return 'Tidak memiliki izin untuk mengakses file.';
    }

    // Generic fallback
    if (kDebugMode) {
      return 'Error: ${error.toString()}';
    }

    return 'Terjadi kesalahan. Silakan coba lagi.';
  }

  /// Determine if an error is retryable
  static bool isRetryable(dynamic error) {
    if (error is NetworkException) {
      return true;
    }

    final errorString = error?.toString().toLowerCase() ?? '';

    return errorString.contains('network') ||
        errorString.contains('timeout') ||
        errorString.contains('connection') ||
        errorString.contains('503') ||
        errorString.contains('502') ||
        errorString.contains('500');
  }

  /// Get error title for display
  static String getErrorTitle(dynamic error) {
    if (error is NetworkException) {
      return 'Masalah Koneksi';
    }
    if (error is AuthException) {
      return 'Masalah Autentikasi';
    }
    if (error is DataException) {
      return 'Data Error';
    }
    if (error is ValidationException) {
      return 'Validasi Error';
    }

    final errorString = error?.toString().toLowerCase() ?? '';

    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout')) {
      return 'Masalah Koneksi';
    }
    if (errorString.contains('401') || errorString.contains('unauthorized')) {
      return 'Sesi Berakhir';
    }
    if (errorString.contains('403') || errorString.contains('forbidden')) {
      return 'Akses Ditolak';
    }
    if (errorString.contains('404')) {
      return 'Data Tidak Ditemukan';
    }

    return 'Terjadi Kesalahan';
  }

  /// Log error for debugging
  static void logError(dynamic error, {String? context, StackTrace? stackTrace}) {
    if (kDebugMode) {
      debugPrint('Error${context != null ? " in $context" : ""}: $error');
      if (stackTrace != null) {
        debugPrint(stackTrace.toString());
      }
    }
  }
}
