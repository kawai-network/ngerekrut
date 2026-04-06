/// Hiring & Recruitment Screen - AI-powered hiring tools
library;

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/hybrid_ai_service.dart';
import '../skills/hiring_service.dart';
import '../models/hiring_models.dart';
import '../flutter_chat_core/flutter_chat_core.dart';
import '../flutter_chat_ui/flutter_chat_ui.dart';
import '../flyer_chat_text_message/flyer_chat_text_message.dart';
import '../flyer_chat_text_stream_message/flyer_chat_text_stream_message.dart';

/// Hiring & Recruitment Screen with AI Skills
class HiringScreen extends StatefulWidget {
  final HybridAIService aiService;

  const HiringScreen({
    super.key,
    required this.aiService,
  });

  @override
  State<HiringScreen> createState() => _HiringScreenState();
}

class _HiringScreenState extends State<HiringScreen> {
  late final HiringService _hiringService;
  late final InMemoryChatController _chatController;

  final _uuid = const Uuid();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _hiringService = HiringService(aiService: widget.aiService);
    _chatController = InMemoryChatController();
    _sendWelcomeMessage();
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _sendWelcomeMessage() async {
    final welcomeId = _uuid.v4();
    final welcomeMsg = Message.text(
      id: welcomeId,
      authorId: 'ai',
      text: _buildWelcomeMessage(),
      createdAt: DateTime.now(),
      status: MessageStatus.seen,
    );
    await _chatController.insertMessage(welcomeMsg);
  }

  String _buildWelcomeMessage() {
    return '''# 👔 AI Hiring Assistant

Selamat datang di **Hiring & Recruitment Skill**!

Saya membantu Anda dengan:

## 📝 Available Skills

1. **Job Description Generator** - Buat JD lengkap dan profesional
2. **Interview Scorecard** - Template evaluasi kandidat terstruktur
3. **STAR Questions** - Pertanyaan behavioral interview
4. **Hiring Metrics** - Track pipeline dan performance hiring
5. **Candidate Analysis** - Analisis kecocokan kandidat

## Cara Menggunakan

Pilih skill di bawah atau ketik permintaan Anda dalam format natural:

**Contoh:**
- "Buat JD untuk Senior Flutter Developer"
- "Buat scorecard untuk technical interview"
- "Generate STAR questions untuk Product Manager"
- "Analisis kandidat: [detail]"

---

Silakan pilih skill atau ketik permintaan Anda! 👇''';
  }

  Future<void> _handleSkillSelection(String skill) async {
    setState(() {
      _isLoading = true;
    });

    // Show skill info message
    final infoId = _uuid.v4();
    final infoMsg = Message.text(
      id: infoId,
      authorId: 'ai',
      text: _getSkillInfo(skill),
      createdAt: DateTime.now(),
      status: MessageStatus.seen,
    );
    await _chatController.insertMessage(infoMsg);

    setState(() => _isLoading = false);
  }

  String _getSkillInfo(String skill) {
    switch (skill) {
      case 'generate_job_description':
        return '''## 📝 Job Description Generator

Saya akan membuat job description lengkap dengan:
- Role title & team
- Responsibilities
- Must-have & nice-to-have qualifications
- Interview process
- Benefits & compensation

**Format input:**
"buat JD untuk [role] di [team], level [level], [deskripsi singkat]"

Atau pilih role dari tombol di bawah.''';

      case 'create_interview_scorecard':
        return '''## 📊 Interview Scorecard

Saya akan membuat scorecard terstruktur dengan:
- Kompetensi dan bobot penilaian
- Panduan scoring (1-5)
- Contoh strong signals & red flags
- Template feedback

**Format input:**
"buat scorecard untuk [role], interview type [technical/design/behavioral]"''';

      case 'generate_star_questions':
        return '''## ⭐ STAR Interview Questions

Saya akan membuat pertanyaan behavioral dengan framework STAR:
- Situation - Task - Action - Result
- Fokus pada kompetensi spesifik
- Contoh look-for indicators

**Format input:**
"buat STAR questions untuk [role], fokus [kompetensi]"\n\nKompetensi: problem_solving, leadership, collaboration, communication.''';

      case 'generate_hiring_metrics':
        return '''## 📈 Hiring Metrics

Saya akan membuat metrics untuk tracking:
- Funnel conversion rates
- Time-to-hire metrics
- Quality indicators
- Targets & red flags

**Format input:**
"buat hiring metrics untuk [role], team size [N], urgency [low/medium/high/critical]"''';

      case 'analyze_candidate_fit':
        return '''## 🔍 Candidate Analysis

Saya akan menganalisis kandidat berdasarkan:
- Pengalaman & kekuatan
- Area of concern
- Interview feedback
- Rekomendasi hiring

**Format input:**
"analisis kandidat [nama] untuk [role]\nPengalaman: [summary]\nStrengths: [list]\nConcerns: [list]"''';

      default:
        return 'Skill tidak dikenali.';
    }
  }

  Future<void> _handleMessageSend(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    // Add user message
    final userId = _uuid.v4();
    final userMsg = Message.text(
      id: userId,
      authorId: 'user',
      text: text.trim(),
      createdAt: DateTime.now(),
      status: MessageStatus.seen,
    );
    await _chatController.insertMessage(userMsg);

    setState(() => _isLoading = true);

    // Create loading message
    final streamId = _uuid.v4();
    final streamMsg = Message.textStream(
      id: streamId,
      authorId: 'ai',
      streamId: streamId,
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
    );
    await _chatController.insertMessage(streamMsg);

    try {
      // Process the request
      final result = await _processRequest(text.trim());

      // Format response
      final responseText = _formatResult(result);

      // Update with final message
      final finalMsg = Message.text(
        id: streamId,
        authorId: 'ai',
        text: responseText,
        createdAt: streamMsg.createdAt,
        status: MessageStatus.seen,
      );
      await _chatController.updateMessage(streamMsg, finalMsg);
    } catch (e) {
      final errorMsg = Message.text(
        id: streamId,
        authorId: 'ai',
        text: '❌ Maaf, terjadi kesalahan: $e\n\nCoba dengan format yang lebih jelas.',
        createdAt: streamMsg.createdAt,
        status: MessageStatus.seen,
      );
      await _chatController.updateMessage(streamMsg, errorMsg);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<HiringSkillResult> _processRequest(String text) async {
    final lower = text.toLowerCase();

    // Determine which skill to use
    if (lower.contains('jd') || lower.contains('job description') || lower.contains('lowongan')) {
      return await _handleJobDescription(text);
    } else if (lower.contains('scorecard') || lower.contains('evaluasi')) {
      return await _handleScorecard(text);
    } else if (lower.contains('star') || lower.contains('pertanyaan behavioral')) {
      return await _handleStarQuestions(text);
    } else if (lower.contains('metric') || lower.contains('pipeline')) {
      return await _handleMetrics(text);
    } else if (lower.contains('analisis') || lower.contains('kandidat')) {
      return await _handleCandidateAnalysis(text);
    } else {
      throw Exception('Tidak dapat mengenali jenis permintaan. Silakan spesifikkan skill yang Anda butuhkan.');
    }
  }

  Future<HiringSkillResult> _handleJobDescription(String text) async {
    // Simple parsing - in production, use NLP
    return await _hiringService.generateJobDescription(
      roleTitle: 'Senior Software Engineer',
      team: 'Engineering',
      roleLevel: RoleLevel.senior,
      aboutRole: 'Lead development of mobile applications',
    );
  }

  Future<HiringSkillResult> _handleScorecard(String text) async {
    return await _hiringService.createScorecard(
      role: 'Software Engineer',
      interviewType: InterviewType.technical,
    );
  }

  Future<HiringSkillResult> _handleStarQuestions(String text) async {
    return await _hiringService.generateStarQuestions(
      role: 'Software Engineer',
      competencyFocus: ['problem_solving', 'collaboration'],
      questionCount: 5,
    );
  }

  Future<HiringSkillResult> _handleMetrics(String text) async {
    return await _hiringService.generateMetrics(
      role: 'Software Engineer',
      teamSize: 10,
      urgency: Urgency.medium,
    );
  }

  Future<HiringSkillResult> _handleCandidateAnalysis(String text) async {
    return await _hiringService.analyzeCandidate(
      candidateName: 'Budi Santoso',
      role: 'Software Engineer',
      experienceSummary: '5 years experience in mobile development',
      keyStrengths: ['Flutter', 'Dart', 'Firebase'],
      concerns: ['No leadership experience'],
    );
  }

  String _formatResult(HiringSkillResult result) {
    final buffer = StringBuffer();
    buffer.writeln('🧠 **Local AI** - ${result.skill}');
    buffer.writeln('');
    buffer.writeln('---');
    buffer.writeln('');

    switch (result.skill) {
      case 'generate_job_description':
        final jd = result.asJobDescription;
        if (jd != null) {
          buffer.writeln('# ${jd.roleTitle} - ${jd.team}');
          buffer.writeln('');
          buffer.writeln('## About Role');
          buffer.writeln(jd.aboutRole);
          buffer.writeln('');
          buffer.writeln('## Responsibilities');
          for (final r in jd.responsibilities) {
            buffer.writeln('- $r');
          }
          buffer.writeln('');
          buffer.writeln('## Must Have');
          for (final req in jd.mustHave) {
            buffer.writeln('- $req');
          }
          buffer.writeln('');
          if (jd.compensationRange != null) {
            buffer.writeln('## Compensation');
            buffer.writeln(jd.compensationRange);
          }
        }
        break;

      case 'create_interview_scorecard':
        final scorecard = result.asScorecard;
        if (scorecard != null) {
          buffer.writeln('# Interview Scorecard');
          buffer.writeln('');
          buffer.writeln('**Candidate:** ${scorecard.candidate}');
          buffer.writeln('**Role:** ${scorecard.role}');
          buffer.writeln('**Type:** ${scorecard.interviewType.name}');
          buffer.writeln('');
          buffer.writeln('## Competencies');
          for (final comp in scorecard.competencies) {
            buffer.writeln('- ${comp.competency.name}: ${comp.weight}%');
          }
        }
        break;

      case 'generate_star_questions':
        final guide = result.asStarGuide;
        if (guide != null) {
          buffer.writeln('# STAR Interview Questions');
          buffer.writeln('');
          buffer.writeln('**Role:** ${guide.role}');
          buffer.writeln('');
          buffer.writeln('## Questions');
          for (var i = 0; i < guide.questions.length && i < 5; i++) {
            final q = guide.questions[i];
            buffer.writeln('${i + 1}. **${q.competency}**');
            buffer.writeln('   ${q.question}');
          }
        }
        break;

      default:
        buffer.writeln('Result generated successfully!');
        if (result.textResponse != null) {
          buffer.writeln('');
          buffer.writeln(result.textResponse);
        }
    }

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.work_outline),
            SizedBox(width: 8),
            Text('AI Hiring Assistant'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset',
            onPressed: _resetChat,
          ),
        ],
      ),
      body: Column(
        children: [
          // Skill selection buttons
          if (!_isLoading)
            Container(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSkillChip('📝', 'Job Description', 'generate_job_description'),
                  _buildSkillChip('📊', 'Scorecard', 'create_interview_scorecard'),
                  _buildSkillChip('⭐', 'STAR Questions', 'generate_star_questions'),
                  _buildSkillChip('📈', 'Metrics', 'generate_hiring_metrics'),
                  _buildSkillChip('🔍', 'Analysis', 'analyze_candidate_fit'),
                ],
              ),
            ),
          // Chat area
          Expanded(
            child: Chat(
              currentUserId: 'user',
              resolveUser: _resolveUser,
              chatController: _chatController,
              builders: _buildBuilders(),
              onMessageSend: _handleMessageSend,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillChip(String emoji, String label, String skill) {
    return ActionChip(
      avatar: Text(emoji, style: const TextStyle(fontSize: 16)),
      label: Text(label),
      onPressed: () => _handleSkillSelection(skill),
    );
  }

  void _resetChat() {
    _chatController.dispose();
    _chatController = InMemoryChatController();
    _sendWelcomeMessage();
  }

  Future<User?> _resolveUser(UserID userId) async {
    return User(
      id: userId,
      name: userId == 'ai' ? 'AI Assistant' : 'You',
    );
  }

  Builders _buildBuilders() {
    return Builders(
      textMessageBuilder: (context, message, index, {isSentByMe = false, groupStatus}) {
        return FlyerChatTextMessage(
          message: message,
          index: index,
          onLinkTap: (url, title) {},
        );
      },
      textStreamMessageBuilder: (context, message, index, {isSentByMe = false, groupStatus}) {
        return FlyerChatTextStreamMessage(
          message: message,
          index: index,
          streamState: const StreamStateStreaming(''),
        );
      },
    );
  }
}
