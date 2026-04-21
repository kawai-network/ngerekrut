/// CV Upload Screen - Upload and extract data from CV PDF
library;

import 'package:flutter/material.dart';
import '../../models/candidate.dart';
import '../../repositories/candidate_repository.dart';
import '../../services/cv_extraction_service.dart';
import '../../services/shared_identity_service.dart';
import 'job_browse_screen.dart';

class CVUploadScreen extends StatefulWidget {
  const CVUploadScreen({super.key});

  @override
  State<CVUploadScreen> createState() => _CVUploadScreenState();
}

class _CVUploadScreenState extends State<CVUploadScreen> {
  final CVExtractionService _cvService = CVExtractionService();
  final CandidateRepository _candidateRepo = CandidateRepository();

  bool _isLoading = false;
  bool _isSaving = false;
  CVExtractionResult? _extractionResult;
  CVParsedData? _editedData;
  bool _showSuccessScreen = false;

  final _nameController = TextEditingController();
  final _summaryController = TextEditingController();
  final _skillsController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _yearsExpController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _summaryController.dispose();
    _skillsController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _yearsExpController.dispose();
    super.dispose();
  }

  Future<void> _pickAndExtractCV() async {
    setState(() => _isLoading = true);
    try {
      final result = await _cvService.pickAndExtract();
      if (result == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak ada file yang dipilih')),
          );
        }
        return;
      }

      if (mounted) {
        setState(() {
          _extractionResult = result;
          _editedData = result.parsedData;
          _populateControllers(_editedData!);
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CV "${result.fileName}" berhasil diekstrak'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengekstrak CV: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _populateControllers(CVParsedData data) {
    _nameController.text = data.name;
    _summaryController.text = data.summary;
    _skillsController.text = data.skills.join(', ');
    _emailController.text = data.email ?? '';
    _phoneController.text = data.phone ?? '';
    _yearsExpController.text = data.yearsOfExperience?.toString() ?? '';
  }

  Future<void> _saveCV() async {
    if (_editedData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan upload CV terlebih dahulu')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      // Build updated data from controllers
      final updatedData = CVParsedData(
        name: _nameController.text.trim().isEmpty
            ? _editedData!.name
            : _nameController.text.trim(),
        skills: _skillsController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        summary: _summaryController.text.trim().isEmpty
            ? _editedData!.summary
            : _summaryController.text.trim(),
        yearsOfExperience: _yearsExpController.text.trim().isEmpty
            ? _editedData!.yearsOfExperience
            : int.tryParse(_yearsExpController.text.trim()),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      );

      // Generate candidate ID
      final candidateId = SharedIdentityService.currentUid;
      final resumeId = 'cv_${DateTime.now().millisecondsSinceEpoch}';

      // Create RecruiterCandidate for storage
      final candidate = RecruiterCandidate(
        id: candidateId,
        name: updatedData.name,
        headline: 'Jobseeker',
        yearsOfExperience: updatedData.yearsOfExperience,
        stage: 'profile_created',
        resume: CandidateResume(
          id: resumeId,
          fileName: _extractionResult?.fileName ?? 'cv.pdf',
          fileUrl: _extractionResult?.filePath,
        ),
        profile: CandidateProfile(
          skills: updatedData.skills,
          summary: updatedData.summary,
        ),
      );

      // Save to database
      await _candidateRepo.save(candidate);

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSuccessScreen) {
      return _SuccessScreen(
        onBrowseJobs: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const JobBrowseScreen()),
          );
        },
        onClose: () {
          Navigator.of(context).pop();
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload CV'),
        actions: [
          if (_extractionResult != null)
            TextButton(
              onPressed: _isSaving ? null : _saveCV,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_extractionResult == null) ...[
            _EmptyState(onUpload: _pickAndExtractCV),
          ] else ...[
            _CVFileCard(
              fileName: _extractionResult!.fileName,
              onReupload: _pickAndExtractCV,
            ),
            const SizedBox(height: 24),
            _buildEditForm(),
          ],
        ],
      ),
      floatingActionButton: _extractionResult != null
          ? null
          : FloatingActionButton.extended(
              onPressed: _isLoading ? null : _pickAndExtractCV,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file),
              label: const Text('Upload CV'),
            ),
    );
  }

  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data yang Diekstrak',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nama',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'No. Telepon',
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _yearsExpController,
          decoration: const InputDecoration(
            labelText: 'Pengalaman (tahun)',
            prefixIcon: Icon(Icons.work_history),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _skillsController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Skills (pisahkan dengan koma)',
            prefixIcon: Icon(Icons.psychology),
            border: OutlineInputBorder(),
            helperText: 'Contoh: Flutter, Dart, Firebase, REST API',
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _summaryController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Summary / Deskripsi Diri',
            prefixIcon: Icon(Icons.description),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Raw Text dari CV',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            _extractionResult?.extractedText ?? '',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            maxLines: 20,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showSuccessDialog() {
    setState(() => _showSuccessScreen = true);
  }
}

/// Success screen shown after CV is saved
class _SuccessScreen extends StatelessWidget {
  const _SuccessScreen({required this.onBrowseJobs, required this.onClose});

  final VoidCallback onBrowseJobs;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 80,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'CV Berhasil Disimpan!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'AI akan merekomendasikan lowongan yang cocok dengan skill dan pengalaman kamu.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: onBrowseJobs,
                icon: const Icon(Icons.search),
                label: const Text('Cari Lowongan Cocok'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 18,
                  ),
                  textStyle: const TextStyle(fontSize: 16),
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: onClose,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Kembali ke Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onUpload});

  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.upload_file,
                size: 56,
                color: Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Upload CV Anda',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload file PDF untuk mengekstrak data profil, skills, dan pengalaman Anda secara otomatis.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onUpload,
              icon: const Icon(Icons.file_upload),
              label: const Text('Pilih File PDF'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CVFileCard extends StatelessWidget {
  const _CVFileCard({required this.fileName, required this.onReupload});

  final String fileName;
  final VoidCallback onReupload;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.picture_as_pdf, color: Color(0xFF6366F1)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'CV berhasil diekstrak',
                    style: TextStyle(color: Colors.green, fontSize: 12),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: onReupload,
              icon: const Icon(Icons.refresh),
              label: const Text('Upload Ulang'),
            ),
          ],
        ),
      ),
    );
  }
}
