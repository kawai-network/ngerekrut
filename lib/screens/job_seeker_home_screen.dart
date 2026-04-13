import 'package:flutter/material.dart';
import '../flavors/flavor_manager.dart';

/// Home screen for Job Seeker app
class JobSeekerHomeScreen extends StatefulWidget {
  const JobSeekerHomeScreen({super.key});

  @override
  State<JobSeekerHomeScreen> createState() => _JobSeekerHomeScreenState();
}

class _JobSeekerHomeScreenState extends State<JobSeekerHomeScreen> {
  int _currentIndex = 0;

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
                  // TODO: Navigate to job search screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Job Search coming soon!')),
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
                  // TODO: Navigate to applications screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('My Applications coming soon!')),
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
                  // TODO: Navigate to interview prep
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Interview Prep coming soon!')),
                  );
                },
                icon: const Icon(Icons.school),
                label: const Text('Persiapan Wawancara'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                  backgroundColor: const Color(0xFFFF9800),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: Navigate to resume builder
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Resume Builder coming soon!')),
                  );
                },
                icon: const Icon(Icons.edit_document),
                label: const Text('Buat CV'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Navigate to AI career coach
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('AI Career Coach coming soon!')),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Cari Kerja',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Lamaran',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
