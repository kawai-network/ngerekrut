/// App flavor configuration
enum AppFlavorType {
  recruiter,
  jobSeeker,
}

class AppFlavorConfig {
  final AppFlavorType type;
  final String appName;
  final String appTitle;
  final String appDescription;
  final String primaryColor;
  final String accentColor;
  final List<String> enabledFeatures;

  const AppFlavorConfig({
    required this.type,
    required this.appName,
    required this.appTitle,
    required this.appDescription,
    required this.primaryColor,
    required this.accentColor,
    required this.enabledFeatures,
  });

  static const recruiter = AppFlavorConfig(
    type: AppFlavorType.recruiter,
    appName: 'NgeRekrut',
    appTitle: 'NgeRekrut - Recruiter',
    appDescription: 'AI-Powered Recruiting Platform',
    primaryColor: '0xFF18CD5B',
    accentColor: '0xFF0F766E',
    enabledFeatures: [
      'job_posting',
      'candidate_screening',
      'interview_guides',
      'scorecards',
      'hiring_assistant',
    ],
  );

  static const jobSeeker = AppFlavorConfig(
    type: AppFlavorType.jobSeeker,
    appName: 'NgeKerja',
    appTitle: 'NgeKerja - Job Seeker',
    appDescription: 'Find Your Dream Job with AI',
    primaryColor: '0xFF6366F1',
    accentColor: '0xFF8B5CF6',
    enabledFeatures: [
      'job_search',
      'application_tracking',
      'interview_prep',
      'resume_builder',
      'ai_coach',
    ],
  );
}
