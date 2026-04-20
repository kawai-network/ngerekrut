/// Hiring & Recruitment Screen - structured AI helper
library;

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../flutter_chat_core/flutter_chat_core.dart';
import '../flutter_chat_ui/flutter_chat_ui.dart';
import '../flyer_chat_text_message/flyer_chat_text_message.dart';
import '../flyer_chat_text_stream_message/flyer_chat_text_stream_message.dart';
import '../models/hiring_models.dart';
import '../services/hybrid_ai_service.dart';
import '../skills/hiring_service.dart';

class HiringScreen extends StatefulWidget {
  final HybridAIService aiService;

  const HiringScreen({super.key, required this.aiService});

  @override
  State<HiringScreen> createState() => _HiringScreenState();
}

class _HiringScreenState extends State<HiringScreen> {
  late final HiringService _hiringService;
  late InMemoryChatController _chatController;

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
    final welcomeMsg = Message.text(
      id: _uuid.v4(),
      authorId: 'ai',
      text: _buildWelcomeMessage(),
      createdAt: DateTime.now(),
      status: MessageStatus.seen,
    );
    await _chatController.insertMessage(welcomeMsg);
  }

  String _buildWelcomeMessage() {
    return '''# Template Hiring Cepat

Layar ini membantu Anda membuat **draft cepat** untuk kebutuhan hiring yang umum.

Gunakan saat Anda butuh:
- draft deskripsi lowongan
- draft penilaian interview
- daftar pertanyaan STAR
- ringkasan metrik hiring
- analisis awal kandidat

Ketik kebutuhan Anda dengan singkat. Contoh:
- "Buat JD untuk kasir toko roti di operasional, level junior"
- "Buat penilaian interview untuk sales, interview recruiter"
- "Pertanyaan STAR untuk admin gudang fokus ketelitian"
- "Metrik hiring untuk customer service, urgency tinggi"
- "Analisis kandidat Rina untuk sales, pengalaman 3 tahun, strengths komunikasi, concerns target belum stabil"''';
  }

  Future<void> _handleSkillSelection(_HiringTemplate template) async {
    final prompt = switch (template) {
      _HiringTemplate.jobDescription =>
        'Buat JD untuk Sales Supervisor di tim operasional, level manager',
      _HiringTemplate.scorecard =>
        'Buat penilaian interview untuk Product Designer, interview technical',
      _HiringTemplate.starQuestions =>
        'Buat pertanyaan STAR untuk Customer Service, fokus communication dan problem solving',
      _HiringTemplate.metrics =>
        'Buat metrik hiring untuk Admin Gudang, urgency tinggi, team size 6',
      _HiringTemplate.candidateAnalysis =>
        'Analisis kandidat Rina untuk Sales Executive, pengalaman 3 tahun, strengths komunikasi dan closing, concerns target belum stabil',
    };

    await _handleMessageSend(prompt, fromQuickAction: true);
  }

  Future<void> _handleMessageSend(
    String text, {
    bool fromQuickAction = false,
  }) async {
    if (text.trim().isEmpty || _isLoading) return;

    final userMsg = Message.text(
      id: _uuid.v4(),
      authorId: 'user',
      text: text.trim(),
      createdAt: DateTime.now(),
      status: MessageStatus.seen,
    );
    await _chatController.insertMessage(userMsg);

    if (fromQuickAction) {
      final helperMsg = Message.text(
        id: _uuid.v4(),
        authorId: 'ai',
        text:
            'Template awal sudah dipilih. Anda bisa kirim prompt lanjutan setelah hasil keluar bila ingin revisi detail.',
        createdAt: DateTime.now(),
        status: MessageStatus.seen,
      );
      await _chatController.insertMessage(helperMsg);
    }

    setState(() => _isLoading = true);

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
      final result = await _processRequest(text.trim());
      final finalMsg = Message.text(
        id: streamId,
        authorId: 'ai',
        text: _formatResult(result),
        createdAt: streamMsg.createdAt,
        status: MessageStatus.seen,
      );
      await _chatController.updateMessage(streamMsg, finalMsg);
    } catch (e) {
      final errorMsg = Message.text(
        id: streamId,
        authorId: 'ai',
        text:
            'Tidak bisa membaca kebutuhan Anda dengan cukup jelas. Coba tulis format yang lebih spesifik, misalnya "Buat JD untuk kasir level junior".\n\nDetail: $e',
        createdAt: streamMsg.createdAt,
        status: MessageStatus.seen,
      );
      await _chatController.updateMessage(streamMsg, errorMsg);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<HiringSkillResult> _processRequest(String text) async {
    final lower = text.toLowerCase();

    if (lower.contains('jd') ||
        lower.contains('job description') ||
        lower.contains('lowongan')) {
      return _handleJobDescription(text);
    }
    if (lower.contains('scorecard') || lower.contains('evaluasi')) {
      return _handleScorecard(text);
    }
    if (lower.contains('star') || lower.contains('behavioral')) {
      return _handleStarQuestions(text);
    }
    if (lower.contains('metric') || lower.contains('pipeline')) {
      return _handleMetrics(text);
    }
    if (lower.contains('analisis') || lower.contains('kandidat')) {
      return _handleCandidateAnalysis(text);
    }

    throw Exception('Skill tidak dikenali.');
  }

  Future<HiringSkillResult> _handleJobDescription(String text) async {
    final role = _extractRole(text, fallback: 'Staff Operasional');
    final team = _extractTeam(text, fallback: 'Operasional');
    final level = _extractRoleLevel(text);
    return _hiringService.generateJobDescription(
      roleTitle: role,
      team: team,
      roleLevel: level,
      aboutRole: 'Membantu tim $team untuk mencapai target peran $role.',
    );
  }

  Future<HiringSkillResult> _handleScorecard(String text) async {
    final role = _extractRole(text, fallback: 'Staff Operasional');
    final candidate = _extractCandidateName(text) ?? 'Kandidat';
    final interviewType = _extractInterviewType(text);
    return _hiringService.createScorecard(
      role: role,
      candidate: candidate,
      interviewer: 'Tim Recruiter',
      interviewType: interviewType,
    );
  }

  Future<HiringSkillResult> _handleStarQuestions(String text) async {
    final role = _extractRole(text, fallback: 'Customer Service');
    return _hiringService.generateStarQuestions(
      role: role,
      competencyFocus: _extractCompetencies(text),
      questionCount: 5,
    );
  }

  Future<HiringSkillResult> _handleMetrics(String text) async {
    final role = _extractRole(text, fallback: 'Customer Service');
    return _hiringService.generateMetrics(
      role: role,
      teamSize: _extractTeamSize(text),
      urgency: _extractUrgency(text),
    );
  }

  Future<HiringSkillResult> _handleCandidateAnalysis(String text) async {
    final candidateName = _extractCandidateName(text) ?? 'Kandidat';
    final role = _extractRole(text, fallback: 'Sales Executive');
    final strengths = _extractListAfterKeyword(text, ['strength', 'strengths']);
    final concerns = _extractListAfterKeyword(text, ['concern', 'concerns']);
    return _hiringService.analyzeCandidate(
      candidateName: candidateName,
      role: role,
      experienceSummary: _extractExperienceSummary(text),
      keyStrengths: strengths.isEmpty ? ['Komunikasi', 'Adaptif'] : strengths,
      concerns: concerns.isEmpty ? ['Perlu validasi lebih lanjut'] : concerns,
    );
  }

  String _extractRole(String text, {required String fallback}) {
    final patterns = [
      RegExp(
        r'untuk\s+([a-zA-Z ]+?)(?:\s+di|\s*,|\s+level|\s+fokus|$)',
        caseSensitive: false,
      ),
      RegExp(
        r'role\s+([a-zA-Z ]+?)(?:\s+di|\s*,|\s+level|$)',
        caseSensitive: false,
      ),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final value = match.group(1)?.trim();
        if (value != null && value.isNotEmpty) return _titleCase(value);
      }
    }

    for (final knownRole in _knownRoles) {
      if (text.toLowerCase().contains(knownRole.toLowerCase())) {
        return _titleCase(knownRole);
      }
    }
    return fallback;
  }

  String _extractTeam(String text, {required String fallback}) {
    final match = RegExp(
      r'(?:di|team)\s+([a-zA-Z ]+?)(?:\s*,|\s+level|$)',
      caseSensitive: false,
    ).firstMatch(text);
    final value = match?.group(1)?.trim();
    if (value == null || value.isEmpty) return fallback;
    return _titleCase(value);
  }

  RoleLevel _extractRoleLevel(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('junior')) return RoleLevel.junior;
    if (lower.contains('mid')) return RoleLevel.mid;
    if (lower.contains('senior')) return RoleLevel.senior;
    if (lower.contains('staff')) return RoleLevel.staff;
    if (lower.contains('manager')) return RoleLevel.manager;
    if (lower.contains('director')) return RoleLevel.director;
    return RoleLevel.mid;
  }

  InterviewType _extractInterviewType(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('technical')) return InterviewType.technical;
    if (lower.contains('design')) return InterviewType.design;
    if (lower.contains('behavioral')) return InterviewType.behavioral;
    if (lower.contains('final')) return InterviewType.finalRound;
    return InterviewType.recruiter;
  }

  Urgency _extractUrgency(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('critical')) return Urgency.critical;
    if (lower.contains('high')) return Urgency.high;
    if (lower.contains('low')) return Urgency.low;
    return Urgency.medium;
  }

  int? _extractTeamSize(String text) {
    final match = RegExp(
      r'team size\s+(\d+)|tim\s+(\d+)',
      caseSensitive: false,
    ).firstMatch(text);
    final value = match?.group(1) ?? match?.group(2);
    return value == null ? null : int.tryParse(value);
  }

  String? _extractCandidateName(String text) {
    final patterns = [
      RegExp(
        r'kandidat\s+([a-zA-Z ]+?)(?:\s+untuk|\s*,|$)',
        caseSensitive: false,
      ),
      RegExp(
        r'candidate\s+([a-zA-Z ]+?)(?:\s+for|\s*,|$)',
        caseSensitive: false,
      ),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      final value = match?.group(1)?.trim();
      if (value != null && value.isNotEmpty) return _titleCase(value);
    }
    return null;
  }

  List<String> _extractCompetencies(String text) {
    final values = _extractListAfterKeyword(text, ['fokus', 'kompetensi']);
    if (values.isNotEmpty) return values;

    final found = <String>[];
    for (final competency in _knownCompetencies) {
      if (text.toLowerCase().contains(competency.toLowerCase())) {
        found.add(competency);
      }
    }
    return found.isEmpty ? ['communication', 'problem solving'] : found;
  }

  String _extractExperienceSummary(String text) {
    final match = RegExp(
      r'pengalaman\s+(.+?)(?:\s+strength|\s+concern|$)',
      caseSensitive: false,
    ).firstMatch(text);
    final value = match?.group(1)?.trim();
    return value == null || value.isEmpty
        ? 'Perlu review pengalaman kandidat lebih lanjut.'
        : value;
  }

  List<String> _extractListAfterKeyword(String text, List<String> keywords) {
    for (final keyword in keywords) {
      final match = RegExp(
        RegExp.escape(keyword) + r'[\s:]+(.+?)(?:\.|$)',
        caseSensitive: false,
      ).firstMatch(text);
      final value = match?.group(1);
      if (value != null && value.trim().isNotEmpty) {
        return value
            .split(RegExp(r',| dan '))
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }
    }
    return const [];
  }

  String _titleCase(String value) {
    return value
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String _formatResult(HiringSkillResult result) {
    final buffer = StringBuffer();
    buffer.writeln('Template siap dipakai: ${_skillLabel(result.skill)}');
    buffer.writeln('');

    switch (result.skill) {
      case 'generate_job_description':
        final jd = result.asJobDescription;
        if (jd != null) {
          buffer.writeln('# ${jd.roleTitle}');
          buffer.writeln('Tim: ${jd.team}');
          buffer.writeln('');
          buffer.writeln('## Ringkasan peran');
          buffer.writeln(jd.aboutRole);
          buffer.writeln('');
          buffer.writeln('## Tanggung jawab');
          for (final responsibility in jd.responsibilities) {
            buffer.writeln('- $responsibility');
          }
          buffer.writeln('');
          buffer.writeln('## Kualifikasi utama');
          for (final requirement in jd.mustHave) {
            buffer.writeln('- $requirement');
          }
          if ((jd.compensationRange ?? '').isNotEmpty) {
            buffer.writeln('');
            buffer.writeln('## Kompensasi');
            buffer.writeln(jd.compensationRange);
          }
        }
        break;
      case 'create_interview_scorecard':
        final scorecard = result.asScorecard;
        if (scorecard != null) {
          buffer.writeln('# Penilaian Interview');
          buffer.writeln('');
          buffer.writeln('Posisi: ${scorecard.role}');
          buffer.writeln('Jenis interview: ${scorecard.interviewType.name}');
          buffer.writeln('');
          buffer.writeln('## Kompetensi');
          for (final competency in scorecard.competencies) {
            buffer.writeln(
              '- ${competency.competency.name}: ${competency.weight}%',
            );
          }
        }
        break;
      case 'generate_star_questions':
        final guide = result.asStarGuide;
        if (guide != null) {
          buffer.writeln('# Pertanyaan STAR');
          buffer.writeln('');
          buffer.writeln('Posisi: ${guide.role}');
          buffer.writeln('');
          for (var i = 0; i < guide.questions.length && i < 5; i++) {
            final question = guide.questions[i];
            buffer.writeln('${i + 1}. ${question.competency}');
            buffer.writeln(question.question);
            buffer.writeln('');
          }
        }
        break;
      case 'generate_hiring_metrics':
        final metrics = result.asMetrics;
        if (metrics != null) {
          buffer.writeln('# Metrik Hiring');
          buffer.writeln('');
          buffer.writeln('## Funnel');
          metrics.funnelMetrics.forEach((key, value) {
            buffer.writeln('- $key: ${value.toStringAsFixed(1)}');
          });
          buffer.writeln('');
          buffer.writeln('## Risiko');
          for (final redFlag in metrics.redFlags) {
            buffer.writeln('- $redFlag');
          }
        }
        break;
      default:
        if ((result.textResponse ?? '').isNotEmpty) {
          buffer.writeln(result.textResponse);
        } else {
          buffer.writeln('Draft analisis kandidat berhasil dibuat.');
        }
    }

    buffer.writeln('');
    buffer.writeln(
      'Ketik ulang dengan detail baru bila Anda ingin revisi draft ini.',
    );
    return buffer.toString();
  }

  String _skillLabel(String skill) {
    switch (skill) {
      case 'generate_job_description':
        return 'Deskripsi Lowongan';
      case 'create_interview_scorecard':
        return 'Penilaian Interview';
      case 'generate_star_questions':
        return 'Pertanyaan STAR';
      case 'generate_hiring_metrics':
        return 'Metrik Hiring';
      case 'analyze_candidate_fit':
        return 'Analisis Kandidat';
      default:
        return skill;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.work_outline),
            SizedBox(width: 8),
            Text('Template Hiring'),
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
          Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Draft cepat untuk kebutuhan hiring umum.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hasil di layar ini adalah draft awal. Gunakan untuk mempercepat kerja recruiter, lalu sesuaikan sebelum dipakai operasional.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          if (!_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTemplateChip(
                    icon: Icons.description_outlined,
                    label: 'Draft JD',
                    template: _HiringTemplate.jobDescription,
                  ),
                  _buildTemplateChip(
                    icon: Icons.fact_check_outlined,
                    label: 'Penilaian',
                    template: _HiringTemplate.scorecard,
                  ),
                  _buildTemplateChip(
                    icon: Icons.quiz_outlined,
                    label: 'STAR',
                    template: _HiringTemplate.starQuestions,
                  ),
                  _buildTemplateChip(
                    icon: Icons.bar_chart_outlined,
                    label: 'Metrik',
                    template: _HiringTemplate.metrics,
                  ),
                  _buildTemplateChip(
                    icon: Icons.person_search_outlined,
                    label: 'Analisis Kandidat',
                    template: _HiringTemplate.candidateAnalysis,
                  ),
                ],
              ),
            ),
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

  Widget _buildTemplateChip({
    required IconData icon,
    required String label,
    required _HiringTemplate template,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onPressed: () => _handleSkillSelection(template),
    );
  }

  void _resetChat() {
    _chatController.dispose();
    _chatController = InMemoryChatController();
    _sendWelcomeMessage();
  }

  Future<User?> _resolveUser(UserID userId) async {
    return User(id: userId, name: userId == 'ai' ? 'Template Hiring' : 'Anda');
  }

  Builders _buildBuilders() {
    return Builders(
      textMessageBuilder:
          (context, message, index, {isSentByMe = false, groupStatus}) {
            return FlyerChatTextMessage(
              message: message,
              index: index,
              onLinkTap: (url, title) {},
            );
          },
      textStreamMessageBuilder:
          (context, message, index, {isSentByMe = false, groupStatus}) {
            return FlyerChatTextStreamMessage(
              message: message,
              index: index,
              streamState: const StreamStateStreaming(''),
            );
          },
    );
  }
}

enum _HiringTemplate {
  jobDescription,
  scorecard,
  starQuestions,
  metrics,
  candidateAnalysis,
}

const _knownRoles = [
  'kasir',
  'admin gudang',
  'sales',
  'customer service',
  'product designer',
  'software engineer',
  'flutter developer',
  'staff operasional',
];

const _knownCompetencies = [
  'communication',
  'problem solving',
  'leadership',
  'collaboration',
  'ketelitian',
  'adaptability',
];
