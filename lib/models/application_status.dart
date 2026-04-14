/// Job application status enum
library;

enum ApplicationStatus {
  /// Applied but not yet reviewed
  applied,

  /// Initial screening by recruiter
  screening,

  /// Selected for interview
  interview,

  /// Interview completed, awaiting decision
  underReview,

  /// Job offer received
  offered,

  /// Rejected by recruiter
  rejected,

  /// Withdrawn by candidate
  withdrawn,

  /// Application archived/expired
  archived;
}

extension ApplicationStatusExtension on ApplicationStatus {
  String get displayName {
    switch (this) {
      case ApplicationStatus.applied:
        return 'Applied';
      case ApplicationStatus.screening:
        return 'Screening';
      case ApplicationStatus.interview:
        return 'Interview';
      case ApplicationStatus.underReview:
        return 'Under Review';
      case ApplicationStatus.offered:
        return 'Offered';
      case ApplicationStatus.rejected:
        return 'Rejected';
      case ApplicationStatus.withdrawn:
        return 'Withdrawn';
      case ApplicationStatus.archived:
        return 'Archived';
    }
  }

  bool get isActive {
    switch (this) {
      case ApplicationStatus.applied:
      case ApplicationStatus.screening:
      case ApplicationStatus.interview:
      case ApplicationStatus.underReview:
      case ApplicationStatus.offered:
        return true;
      case ApplicationStatus.rejected:
      case ApplicationStatus.withdrawn:
      case ApplicationStatus.archived:
        return false;
    }
  }
}
