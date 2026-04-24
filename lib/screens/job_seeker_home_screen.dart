import 'package:flutter/material.dart';
import '../flavors/flavor_manager.dart';
import '../services/shared_identity_service.dart';
import '../services/onesignal_service.dart';
import 'jobseeker/job_browse_screen.dart';
import 'jobseeker/my_applications_screen.dart';
import 'jobseeker/saved_jobs_screen.dart';
import 'jobseeker/cv_upload_screen.dart';
import 'jobseeker/interview_prep_screen.dart';
import 'jobseeker/career_coach_screen.dart';

/// Home screen for Job Seeker app
class JobSeekerHomeScreen extends StatefulWidget {
  const JobSeekerHomeScreen({super.key});

  @override
  State<JobSeekerHomeScreen> createState() => _JobSeekerHomeScreenState();
}

class _JobSeekerHomeScreenState extends State<JobSeekerHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.work_outline, size: 24),
            const SizedBox(width: 8),
            Text(FlavorManager.flavor.appName),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () async {
              // Clear OneSignal subscription before signing out
              await OneSignalService.instance.clearSubscription();
              await SharedIdentityService.signOut();
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              // Hero card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.search, color: Colors.white, size: 32),
                    const SizedBox(height: 12),
                    const Text(
                      'Temukan Pekerjaan Impianmu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'AI akan membantumu menemukan dan melamar pekerjaan yang sesuai.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Feature buttons
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const JobBrowseScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.search),
                label: const Text('Cari Pekerjaan'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyApplicationsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.description),
                label: const Text('Lamaran Saya'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SavedJobsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.bookmark),
                label: const Text('Pekerjaan Disimpan'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InterviewPrepScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.school),
                label: const Text('Persiapan Wawancara'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CVUploadScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.edit_document),
                label: const Text('Upload CV'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CareerCoachScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('AI Career Coach'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                'AI-powered job matching dan persiapan karier.\n\n'
                'API: ${FlavorManager.environment.apiBaseUrl.isEmpty ? 'belum dikonfigurasi' : FlavorManager.environment.apiBaseUrl}'
                '\n\nTambahkan OPENAI_API_KEY dan FIREBASE_JOBSEEKER_* via --dart-define saat build.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
