/// Push Notification Service using OneSignal
///
/// Sends push notifications via OneSignal
library;

import 'package:flutter/foundation.dart' show debugPrint;
import 'hybrid_database_service.dart';
import 'onesignal_service.dart';

class PushNotificationService {
  PushNotificationService._internal();

  static final PushNotificationService instance = PushNotificationService._internal();

  /// Notify recruiter about new job application
  ///
  /// Call this when a jobseeker submits an application
  Future<NotificationResult> notifyNewApplication({
    required String jobId,
    required String jobTitle,
    required String candidateId,
    String? unitLabel,
    String? applicationId,
  }) async {
    // Get recruiter's external user ID (Firebase UID)
    final recruiterUserIds = await _getRecruiterUserIds(jobId);

    if (recruiterUserIds.isEmpty) {
      debugPrint('No recruiters found for job $jobId');
      return NotificationResult.success(notified: 0);
    }

    // Send notification via OneSignal (using external user IDs)
    try {
      for (final recruiterId in recruiterUserIds) {
        await OneSignalDirectApi.instance.sendNotificationToUser(
          externalUserId: recruiterId,
          title: 'Lamaran Baru!',
          body: '${candidateId.substring(0, 8)}... melamar posisi $jobTitle',
          data: {
            'type': 'new_application',
            'application_id': applicationId ?? '',
            'job_id': jobId,
            'candidate_id': candidateId,
            'job_title': jobTitle,
            'unit_label': unitLabel ?? '',
          },
        );
      }

      return NotificationResult.success(notified: recruiterUserIds.length);
    } catch (e) {
      debugPrint('Error sending OneSignal notification: $e');
      return NotificationResult.failure(e.toString());
    }
  }

  /// Notify candidate about application status change
  ///
  /// Call this when a recruiter updates application status
  Future<NotificationResult> notifyStatusChange({
    required String applicationId,
    required String status,
    required String jobTitle,
    required String candidateId,
  }) async {
    if (candidateId.isEmpty) {
      return NotificationResult.failure('Candidate ID is empty');
    }

    // Get status display name
    const statusNames = {
      'applied': 'Lamaran Diterima',
      'screening': 'Tahap Screening',
      'interview': 'Interview Dijadwalkan',
      'offer': 'Penawaran Diterima',
      'hired': 'Selamat! Anda Diterima',
      'rejected': 'Lamaran Ditolak',
      'withdrawn': 'Lamaran Ditarik',
    };

    final statusTitle = statusNames[status] ?? 'Status Lamaran Diupdate';

    try {
      await OneSignalDirectApi.instance.sendNotificationToUser(
        externalUserId: candidateId,
        title: statusTitle,
        body: 'Status lamaran Anda untuk $jobTitle telah diperbarui.',
        data: {
          'type': 'application_status_changed',
          'application_id': applicationId,
          'status': status,
          'job_title': jobTitle,
        },
      );

      return NotificationResult.success(notified: 1);
    } catch (e) {
      debugPrint('Error sending OneSignal notification: $e');
      return NotificationResult.failure(e.toString());
    }
  }

  /// Get recruiter's external user IDs (Firebase UIDs) for a specific job
  Future<List<String>> _getRecruiterUserIds(String jobId) async {
    try {
      final rows = await hybridDatabase.rawQuery('''
        SELECT DISTINCT j.recruiter_user_id
        FROM job_postings j
        WHERE j.job_id = ?
      ''', positional: [jobId]);
      return rows.map((row) => row['recruiter_user_id'] as String).toList();
    } catch (e) {
      debugPrint('Error fetching recruiter IDs: $e');
      return [];
    }
  }
}

/// Result of a notification operation
class NotificationResult {
  const NotificationResult._({
    required this.success,
    this.notified,
    this.error,
  });

  /// Create a success result
  factory NotificationResult.success({int? notified}) {
    return NotificationResult._(
      success: true,
      notified: notified,
    );
  }

  /// Create a failure result
  factory NotificationResult.failure(String error) {
    return NotificationResult._(
      success: false,
      error: error,
    );
  }

  /// Whether the notification was sent successfully
  final bool success;

  /// Number of devices notified (only on success)
  final int? notified;

  /// Error message (only on failure)
  final String? error;
}
