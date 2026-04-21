/// Interview Prep Screen - Generate and practice interview questions
library;

import 'package:flutter/material.dart';
import '../../app/runtime_config.dart';
import '../../models/hiring_models.dart';
import '../../models/job_application.dart';
import '../../models/recruiter_job.dart';
import '../../repositories/job_application_repository.dart';
import '../../repositories/job_posting_repository.dart';
import '../../repositories/saved_job_repository.dart';
import '../../services/hybrid_ai_service.dart';
import '../../services/interview_prep_service.dart';

class InterviewPrepScreen extends StatefulWidget {
  const InterviewPrepScreen({super.key, this.job});

  final RecruiterJob? job;

  @override
  State<InterviewPrepScreen> createState() => _InterviewPrepScreenState();
}

class _InterviewPrepScreenState extends State<InterviewPrepScreen> {
  final InterviewPrepService _prepService = InterviewPrepService(
    aiService: HybridAIService(cloudApiKey: readConfig('OPENAI_API_KEY')),
  );

  final JobPostingRepository _jobRepo = JobPostingRepository();
  final SavedJobRepository _savedRepo = SavedJobRepository();
  final JobApplicationRepository _applicationRepo = JobApplicationRepository();

  bool _isLoading = false;
  bool _isGenerating = false;

  InterviewPrepResult? _prepResult;
  int _currentQuestionIndex = 0;
  String? _selectedJobId;
  final _customTitleController = TextEditingController();

  List<RecruiterJob> _availableJobs = [];
  List<SavedJob> _savedJobs = [];
  List<JobApplication> _appliedJobs = [];

  @override
  void initState() {
    super.initState();
    if (widget.job != null) {
      // If job is passed directly, generate questions immediately
      _generateForJob(widget.job!);
    } else {
      _loadJobs();
    }
  }

  @override
  void dispose() {
    _customTitleController.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    setState(() => _isLoading = true);
    try {
      final jobs = await _jobRepo.getActive();
      final saved = await _savedRepo.getAll();
      final applied = await _applicationRepo.getByCandidateId(
        _applicationRepo.candidateId,
      );

      if (mounted) {
        setState(() {
          _availableJobs = jobs;
          _savedJobs = saved;
          _appliedJobs = applied;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading jobs: $e')));
      }
    }
  }

  Future<void> _generateForJob(RecruiterJob job) async {
    setState(() => _isGenerating = true);
    try {
      final result = await _prepService.generateWithDefaultCompetencies(
        jobTitle: job.title,
        requirements: job.requirements,
        description: job.description,
      );

      if (mounted) {
        setState(() {
          _prepResult = result;
          _selectedJobId = job.id;
          _currentQuestionIndex = 0;
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal generate pertanyaan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateForCustomTitle() async {
    final title = _customTitleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Masukkan judul posisi')));
      return;
    }

    setState(() => _isGenerating = true);
    try {
      final result = await _prepService.generateWithDefaultCompetencies(
        jobTitle: title,
      );

      if (mounted) {
        setState(() {
          _prepResult = result;
          _selectedJobId = null;
          _currentQuestionIndex = 0;
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal generate pertanyaan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _nextQuestion() {
    if (_prepResult == null) return;
    if (_currentQuestionIndex < _prepResult!.guide.questions.length - 1) {
      setState(() => _currentQuestionIndex++);
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() => _currentQuestionIndex--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Persiapan Wawancara'),
        actions: [
          if (_prepResult != null)
            TextButton(
              onPressed: () => _showSaveDialog(),
              child: const Text('Simpan'),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_prepResult == null) {
      return _JobSelectionView(
        availableJobs: _availableJobs,
        savedJobs: _savedJobs,
        appliedJobs: _appliedJobs,
        selectedJobId: _selectedJobId,
        customTitleController: _customTitleController,
        isGenerating: _isGenerating,
        onJobSelected: (job) => _generateForJob(job),
        onCustomSubmit: _generateForCustomTitle,
        onJobIdChanged: (id) => setState(() => _selectedJobId = id),
      );
    }

    return _QuestionsView(
      result: _prepResult!,
      currentIndex: _currentQuestionIndex,
      onNext: _nextQuestion,
      onPrevious: _previousQuestion,
      onRegenerate: () {
        if (_selectedJobId != null) {
          final job = _availableJobs.cast<RecruiterJob?>().firstWhere(
            (j) => j?.id == _selectedJobId,
            orElse: () => null,
          );
          if (job != null) _generateForJob(job);
        } else {
          _generateForCustomTitle();
        }
      },
    );
  }

  void _showSaveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Simpan Panduan'),
        content: const Text(
          'Panduan wawancara akan disimpan untuk review nanti.\n\n'
          'Fitur ini akan tersedia segera setelah update berikutnya.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _JobSelectionView extends StatelessWidget {
  const _JobSelectionView({
    required this.availableJobs,
    required this.savedJobs,
    required this.appliedJobs,
    required this.selectedJobId,
    required this.customTitleController,
    required this.isGenerating,
    required this.onJobSelected,
    required this.onCustomSubmit,
    required this.onJobIdChanged,
  });

  final List<RecruiterJob> availableJobs;
  final List<SavedJob> savedJobs;
  final List<JobApplication> appliedJobs;
  final String? selectedJobId;
  final TextEditingController customTitleController;
  final bool isGenerating;
  final Function(RecruiterJob) onJobSelected;
  final Function() onCustomSubmit;
  final Function(String?) onJobIdChanged;

  List<RecruiterJob> get _uniqueJobs {
    final ids = <String>{};
    final unique = <RecruiterJob>[];
    for (final job in [
      ..._savedJobsFromSaved(),
      ..._savedJobsFromApplications(),
      ...availableJobs,
    ]) {
      if (ids.add(job.id)) {
        unique.add(job);
      }
    }
    return unique;
  }

  List<RecruiterJob> _savedJobsFromSaved() {
    return savedJobs
        .map(
          (s) => RecruiterJob(
            id: s.jobId,
            title: s.title,
            department: s.unitLabel,
            location: s.location,
            requirements: [],
            status: 'active',
          ),
        )
        .toList();
  }

  List<RecruiterJob> _savedJobsFromApplications() {
    return appliedJobs
        .map(
          (a) => RecruiterJob(
            id: a.jobId,
            title: a.jobTitle,
            department: a.unitLabel,
            location: a.location,
            requirements: [],
            status: 'applied',
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Hero section
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
              const Icon(
                Icons.psychology_outlined,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                'Persiapan Wawancara',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'AI akan generate pertanyaan behavioral interview (STAR) '
                'berdasarkan posisi yang Anda incar.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Job selection
        Text(
          'Pilih Lowongan',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_uniqueJobs.isEmpty)
          _EmptyJobsHint()
        else
          DropdownButtonFormField<String>(
            initialValue: selectedJobId,
            decoration: const InputDecoration(
              labelText: 'Pilih lowongan',
              prefixIcon: Icon(Icons.work_outline),
              border: OutlineInputBorder(),
            ),
            items: _uniqueJobs.map((job) {
              return DropdownMenuItem(
                value: job.id,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(job.title, style: const TextStyle(fontSize: 14)),
                    if (job.department != null)
                      Text(
                        job.department!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
            onChanged: onJobIdChanged,
          ),
        const SizedBox(height: 16),

        // OR divider
        const Row(
          children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('ATAU'),
            ),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),

        // Custom job title
        TextField(
          controller: customTitleController,
          decoration: const InputDecoration(
            labelText: 'Masukkan judul posisi',
            prefixIcon: Icon(Icons.edit),
            border: OutlineInputBorder(),
            hintText: 'Contoh: Senior Flutter Developer',
          ),
        ),
        const SizedBox(height: 24),

        // Generate button
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed:
                (isGenerating ||
                    (selectedJobId == null &&
                        customTitleController.text.trim().isEmpty))
                ? null
                : () {
                    if (selectedJobId != null) {
                      final job = _uniqueJobs.firstWhere(
                        (j) => j.id == selectedJobId,
                      );
                      onJobSelected(job);
                    } else {
                      onCustomSubmit();
                    }
                  },
            icon: isGenerating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(isGenerating ? 'Generating...' : 'Generate Pertanyaan'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),

        // Info section
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tentang STAR',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'STAR adalah framework untuk menjawab pertanyaan behavioral:\n'
                '• **S**ituation - Konteks situasi\n'
                '• **T**ask - Tugas/tanggung jawab\n'
                '• **A**ction - Tindakan yang Anda lakukan\n'
                '• **R**esult - Hasil yang dicapai',
                style: TextStyle(
                  color: Colors.blue.shade900,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyJobsHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Belum ada lowongan tersimpan',
                  style: TextStyle(
                    color: Colors.grey.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cari lowongan dulu, atau masukkan judul posisi secara manual.',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionsView extends StatelessWidget {
  const _QuestionsView({
    required this.result,
    required this.currentIndex,
    required this.onNext,
    required this.onPrevious,
    required this.onRegenerate,
  });

  final InterviewPrepResult result;
  final int currentIndex;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onRegenerate;

  STARQuestion get _currentQuestion => result.guide.questions[currentIndex];
  int get _totalQuestions => result.guide.questions.length;
  int get _currentNumber => currentIndex + 1;

  @override
  Widget build(BuildContext context) {
    final question = _currentQuestion;

    return Column(
      children: [
        // Header with job title
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.jobTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$_currentNumber dari $_totalQuestions pertanyaan',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRegenerate,
                icon: const Icon(Icons.refresh),
                tooltip: 'Generate ulang',
              ),
            ],
          ),
        ),

        // Progress bar
        LinearProgressIndicator(
          value: (_currentNumber) / _totalQuestions,
          backgroundColor: Colors.grey.shade300,
        ),

        // Question content
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Competency chip
              Wrap(
                spacing: 8,
                children: [
                  Chip(
                    label: Text(_formatCompetency(question.competency)),
                    backgroundColor: Colors.blue.shade100,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Question
              Text(
                question.question,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // What to look for
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Yang dinilai interviewer:',
                          style: TextStyle(
                            color: Colors.green.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...question.lookFor.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '• ',
                              style: TextStyle(color: Colors.green),
                            ),
                            Expanded(
                              child: Text(
                                item,
                                style: TextStyle(color: Colors.green.shade900),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // STAR reminder
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.amber.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Gunakan framework STAR: Situation → Task → Action → Result',
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Navigation buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: currentIndex > 0 ? onPrevious : null,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Sebelumnya'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: currentIndex < _totalQuestions - 1
                        ? onNext
                        : null,
                    label: const Text('Selanjutnya'),
                    icon: const Icon(Icons.arrow_forward),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatCompetency(String competency) {
    switch (competency) {
      case 'technicalSkills':
        return 'Technical Skills';
      case 'problemSolving':
        return 'Problem Solving';
      case 'communication':
        return 'Komunikasi';
      case 'collaboration':
        return 'Kolaborasi';
      case 'growthMindset':
        return 'Growth Mindset';
      case 'leadership':
        return 'Leadership';
      default:
        return competency;
    }
  }
}
