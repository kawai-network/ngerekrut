library;

import '../app/runtime_config.dart';

class SharedIdentityService {
  const SharedIdentityService._();

  static String get jobseekerUserId {
    final configured = readConfig('JOBSEEKER_USER_ID');
    return configured.isNotEmpty ? configured : 'demo_jobseeker';
  }

  static String get recruiterUserId {
    final configured = readConfig('RECRUITER_USER_ID');
    return configured.isNotEmpty ? configured : 'demo_recruiter';
  }
}
