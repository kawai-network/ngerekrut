library;

import 'package:flutter/material.dart';
import 'package:ngerekrut/flutter_chat_core/flutter_chat_core.dart';
import 'package:ngerekrut/flutter_chat_ui/flutter_chat_ui.dart';
import 'package:uuid/uuid.dart';
import 'package:ngerekrut/objectbox_store_provider.dart';

import '../flyer_chat_file_message/flyer_chat_file_message.dart';
import '../flyer_chat_system_message/flyer_chat_system_message.dart';
import '../flyer_chat_text_message/flyer_chat_text_message.dart';
import '../flyer_chat_text_stream_message/flyer_chat_text_stream_message.dart';
import '../models/hiring_models.dart';
import '../models/chat_session_record.dart';
import '../repositories/chat_session_repository.dart';
import '../services/hybrid_ai_service.dart';
import '../skills/hiring_service.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({
    super.key,
    required this.session,
    required this.aiService,
    this.currentUserId = 'recruiter_user',
  });

  final ChatSessionRecord session;
  final HybridAIService aiService;
  final String currentUserId;

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _JobDescriptionRequest {
  const _JobDescriptionRequest({
    required this.roleTitle,
    required this.team,
    required this.roleLevel,
    required this.aboutRole,
  });

  final String roleTitle;
  final String team;
  final RoleLevel roleLevel;
  final String aboutRole;
}

class _ScorecardRequest {
  const _ScorecardRequest({
    required this.role,
    required this.interviewType,
    required this.candidateName,
  });

  final String role;
  final InterviewType interviewType;
  final String candidateName;
}

class _StarRequest {
  const _StarRequest({
    required this.role,
    required this.competencyFocus,
    required this.questionCount,
  });

  final String role;
  final List<String> competencyFocus;
  final int questionCount;
}

class _MetricsRequest {
  const _MetricsRequest({
    required this.role,
    required this.teamSize,
    required this.urgency,
  });

  final String role;
  final int? teamSize;
  final Urgency urgency;
}

class _CandidateAnalysisRequest {
  const _CandidateAnalysisRequest({
    required this.candidateName,
    required this.role,
    required this.experienceSummary,
    required this.keyStrengths,
    required this.concerns,
  });

  final String candidateName;
  final String role;
  final String experienceSummary;
  final List<String> keyStrengths;
  final List<String> concerns;
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  static const _streamTextMetadataKey = 'streamText';

  final ChatSessionRepository _sessionRepository = ChatSessionRepository();
  final Uuid _uuid = const Uuid();
  ObjectBoxChatController? _chatController;
  late final HiringService _hiringService;
  ChatSessionRecord? _session;
  bool _isInitializing = true;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _hiringService = HiringService(aiService: widget.aiService);
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    ObjectBoxChatController? controller;
    try {
      await _sessionRepository.initialize();
      if (!ObjectBoxStoreProvider.isInitialized) {
        await ObjectBoxStoreProvider.initialize();
      }

      controller = ObjectBoxChatController(sessionId: widget.session.sessionId);
      await controller.loadMessages(limit: 100);

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _chatController = controller;
        _session = _sessionRepository.ensureSession(widget.session.sessionId);
        _isInitializing = false;
      });
      await _ensureWelcomeMessage();
    } catch (e) {
      controller?.dispose();
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isInitializing = false;
      });
    }
  }

  @override
  void dispose() {
    _chatController?.dispose();
    super.dispose();
  }

  Future<void> _ensureWelcomeMessage() async {
    if (_chatController == null || _chatController!.messages.isNotEmpty) return;

    const welcomeText = '''Asisten recruiter siap membantu.

Anda bisa minta:
- job description
- interview scorecard
- STAR questions
- hiring metrics
- analisis kandidat

Contoh:
"buat jd untuk senior flutter developer"
"buat scorecard untuk technical interview backend engineer"
"buat STAR questions untuk product manager"''';

    final message = Message.text(
      id: _uuid.v4(),
      authorId: 'ai',
      text: welcomeText,
      createdAt: DateTime.now(),
      status: MessageStatus.sent,
    );

    await _chatController!.insertMessage(message);
    final session = _sessionRepository.recordMessage(
      widget.session.sessionId,
      welcomeText,
    );
    if (!mounted) return;
    setState(() => _session = session);
  }

  Future<void> _handleSend(String text) async {
    final content = text.trim();
    if (content.isEmpty || _chatController == null || _isLoading) return;

    final userMessage = Message.text(
      id: _uuid.v4(),
      authorId: widget.currentUserId,
      text: content,
      createdAt: DateTime.now(),
      status: MessageStatus.sent,
    );

    await _chatController!.insertMessage(userMessage);
    var session = _sessionRepository.recordMessage(
      widget.session.sessionId,
      content,
    );
    if (mounted) {
      setState(() {
        _session = session;
        _isLoading = true;
      });
    }

    try {
      final result = await _processRequest(content);
      final responseText = _formatResult(result);
      session = _updateSessionTitleFromResult(result, session);
      final aiMessage = Message.text(
        id: _uuid.v4(),
        authorId: 'ai',
        text: responseText,
        createdAt: DateTime.now(),
        status: MessageStatus.sent,
      );
      await _chatController!.insertMessage(aiMessage);
      session = _sessionRepository.recordMessage(
        widget.session.sessionId,
        responseText,
      );
      if (!mounted) return;
      setState(() => _session = session);
    } catch (e) {
      final errorText =
          'Maaf, permintaan ini belum bisa diproses.\n\n$e\n\nCoba tulis permintaan lebih spesifik.';
      final errorMessage = Message.text(
        id: _uuid.v4(),
        authorId: 'ai',
        text: errorText,
        createdAt: DateTime.now(),
        status: MessageStatus.sent,
      );
      await _chatController!.insertMessage(errorMessage);
      session = _sessionRepository.recordMessage(
        widget.session.sessionId,
        errorText,
      );
      if (!mounted) return;
      setState(() => _session = session);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  ChatSessionRecord _updateSessionTitleFromResult(
    HiringSkillResult result,
    ChatSessionRecord currentSession,
  ) {
    switch (result.skill) {
      case 'generate_job_description':
        final jd = result.asJobDescription;
        if (jd == null || jd.roleTitle.trim().isEmpty) {
          return currentSession;
        }
        final team = jd.team.trim();
        final title =
            team.isNotEmpty ? '${jd.roleTitle} - $team' : jd.roleTitle;
        return _sessionRepository.setTitle(widget.session.sessionId, title);
      case 'create_interview_scorecard':
        final scorecard = result.asScorecard;
        if (scorecard == null || scorecard.role.trim().isEmpty) {
          return currentSession;
        }
        return _sessionRepository.setTitle(
          widget.session.sessionId,
          'Scorecard - ${scorecard.role}',
        );
      case 'generate_star_questions':
        final guide = result.asStarGuide;
        if (guide == null || guide.role.trim().isEmpty) {
          return currentSession;
        }
        return _sessionRepository.setTitle(
          widget.session.sessionId,
          'STAR - ${guide.role}',
        );
      case 'generate_hiring_metrics':
        final metricsRole = result.data['role']?.toString().trim();
        if (metricsRole == null) {
          return currentSession;
        }
        return _sessionRepository.setTitle(
          widget.session.sessionId,
          'Metrics - $metricsRole',
        );
      case 'analyze_candidate_fit':
        final candidateName =
            result.data['candidate_name']?.toString().trim() ??
            result.data['candidateName']?.toString().trim();
        final role = result.data['role']?.toString().trim();
        if (candidateName != null && candidateName.isNotEmpty) {
          final title = role != null && role.isNotEmpty
              ? 'Analisis - $candidateName ($role)'
              : 'Analisis - $candidateName';
          return _sessionRepository.setTitle(
            widget.session.sessionId,
            title,
          );
        }
        final text = result.textResponse?.trim();
        if (text != null && text.isNotEmpty) {
          return _sessionRepository.setTitle(
            widget.session.sessionId,
            'Analisis Kandidat',
          );
        }
        return currentSession;
      default:
        return currentSession;
    }
  }

  Future<HiringSkillResult> _processRequest(String text) async {
    final lower = text.toLowerCase();
    if (lower.contains('jd') ||
        lower.contains('job description') ||
        lower.contains('lowongan')) {
      final request = _parseJobDescriptionRequest(text);
      return _hiringService.generateJobDescription(
        roleTitle: request.roleTitle,
        team: request.team,
        roleLevel: request.roleLevel,
        aboutRole: request.aboutRole,
      );
    }
    if (lower.contains('scorecard') || lower.contains('evaluasi')) {
      final request = _parseScorecardRequest(text);
      return _hiringService.createScorecard(
        role: request.role,
        interviewType: request.interviewType,
        candidate: request.candidateName,
      );
    }
    if (lower.contains('star') || lower.contains('behavioral')) {
      final request = _parseStarRequest(text);
      return _hiringService.generateStarQuestions(
        role: request.role,
        competencyFocus: request.competencyFocus,
        questionCount: request.questionCount,
      );
    }
    if (lower.contains('metric') || lower.contains('pipeline')) {
      final request = _parseMetricsRequest(text);
      return _hiringService.generateMetrics(
        role: request.role,
        teamSize: request.teamSize,
        urgency: request.urgency,
      );
    }
    if (lower.contains('analisis') || lower.contains('kandidat')) {
      final request = _parseCandidateAnalysisRequest(text);
      return _hiringService.analyzeCandidate(
        candidateName: request.candidateName,
        role: request.role,
        experienceSummary: request.experienceSummary,
        keyStrengths: request.keyStrengths,
        concerns: request.concerns,
      );
    }

    final freeform = await widget.aiService.generateLocalResponse(
      prompt: text,
      systemPrompt: '''Anda adalah asisten recruiter berbahasa Indonesia.

Jawab singkat, praktis, dan relevan untuk kebutuhan recruiter. Jika user meminta job description, scorecard, STAR questions, hiring metrics, atau analisis kandidat, berikan output yang langsung bisa dipakai.''',
    );

    return HiringSkillResult(
      skill: 'general_recruiter_assistant',
      data: const {},
      textResponse: freeform,
      usedMode: widget.aiService.lastUsedMode,
    );
  }

  _JobDescriptionRequest _parseJobDescriptionRequest(String text) {
    final roleTitle = _extractRole(
      text,
      fallback: 'Senior Software Engineer',
    );
    return _JobDescriptionRequest(
      roleTitle: roleTitle,
      team: _inferTeam(text, roleTitle),
      roleLevel: _inferRoleLevel(text),
      aboutRole: _buildAboutRole(text, roleTitle),
    );
  }

  _ScorecardRequest _parseScorecardRequest(String text) {
    return _ScorecardRequest(
      role: _extractRole(text, fallback: 'Software Engineer'),
      interviewType: _inferInterviewType(text),
      candidateName: _extractCandidateName(text) ?? 'Candidate Name',
    );
  }

  _StarRequest _parseStarRequest(String text) {
    return _StarRequest(
      role: _extractRole(text, fallback: 'Software Engineer'),
      competencyFocus: _inferCompetencyFocus(text),
      questionCount: _inferQuestionCount(text),
    );
  }

  _MetricsRequest _parseMetricsRequest(String text) {
    return _MetricsRequest(
      role: _extractRole(text, fallback: 'Software Engineer'),
      teamSize: _inferTeamSize(text),
      urgency: _inferUrgency(text),
    );
  }

  _CandidateAnalysisRequest _parseCandidateAnalysisRequest(String text) {
    return _CandidateAnalysisRequest(
      candidateName: _extractCandidateName(text) ?? 'Kandidat',
      role: _extractRole(text, fallback: 'Software Engineer'),
      experienceSummary: _extractExperienceSummary(text),
      keyStrengths: _extractTaggedList(text, ['strength', 'strengths', 'kekuatan']),
      concerns: _extractTaggedList(text, ['concern', 'concerns', 'kekhawatiran']),
    );
  }

  String _extractRole(String text, {required String fallback}) {
    final cleaned = text
        .replaceAll(RegExp(r'\bbuat\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bjd\b', caseSensitive: false), '')
        .replaceAll(
          RegExp(r'\bjob description\b', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'\bscorecard\b', caseSensitive: false), '')
        .replaceAll(
          RegExp(r'\bstar questions?\b', caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(r'\bhiring metrics?\b', caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(r'\banalisis kandidat\b', caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(r'\btechnical interview\b', caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(r'\bbehavioral interview\b', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'\bmetrics\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bpipeline\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\buntuk role\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\buntuk\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bremote\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bhybrid\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.isEmpty ? fallback : cleaned;
  }

  RoleLevel _inferRoleLevel(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('principal')) return RoleLevel.principal;
    if (lower.contains('director')) return RoleLevel.director;
    if (lower.contains('manager')) return RoleLevel.manager;
    if (lower.contains('staff')) return RoleLevel.staff;
    if (lower.contains('senior') || lower.contains('sr ')) return RoleLevel.senior;
    if (lower.contains('junior') || lower.contains('jr ')) return RoleLevel.junior;
    return RoleLevel.mid;
  }

  InterviewType _inferInterviewType(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('behavioral')) return InterviewType.behavioral;
    if (lower.contains('design')) return InterviewType.design;
    if (lower.contains('final')) return InterviewType.finalRound;
    if (lower.contains('recruiter')) return InterviewType.recruiter;
    return InterviewType.technical;
  }

  Urgency _inferUrgency(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('critical') || lower.contains('kritikal')) {
      return Urgency.critical;
    }
    if (lower.contains('high') || lower.contains('tinggi')) return Urgency.high;
    if (lower.contains('low') || lower.contains('rendah')) return Urgency.low;
    return Urgency.medium;
  }

  String _inferTeam(String text, String roleTitle) {
    final lower = text.toLowerCase();
    if (lower.contains('product')) return 'Product';
    if (lower.contains('design')) return 'Design';
    if (lower.contains('marketing')) return 'Marketing';
    if (lower.contains('sales')) return 'Sales';
    if (lower.contains('hr') || lower.contains('people')) return 'People';
    if (lower.contains('data')) return 'Data';
    if (lower.contains('finance')) return 'Finance';
    if (lower.contains('ops') || lower.contains('operational')) return 'Operations';
    if (lower.contains('backend') ||
        lower.contains('frontend') ||
        lower.contains('flutter') ||
        lower.contains('android') ||
        lower.contains('ios') ||
        lower.contains('engineer') ||
        lower.contains('developer')) {
      return 'Engineering';
    }
    if (roleTitle.toLowerCase().contains('manager')) return 'Business';
    return 'Engineering';
  }

  String _buildAboutRole(String text, String roleTitle) {
    final lower = text.toLowerCase();
    final workMode = lower.contains('remote')
        ? 'remote'
        : lower.contains('hybrid')
            ? 'hybrid'
            : 'onsite';
    return '$roleTitle bertanggung jawab mendorong delivery tim, berkolaborasi lintas fungsi, dan menjaga kualitas eksekusi dalam pola kerja $workMode.';
  }

  List<String> _inferCompetencyFocus(String text) {
    final lower = text.toLowerCase();
    final focus = <String>[];
    if (lower.contains('leadership')) focus.add('leadership');
    if (lower.contains('communication') || lower.contains('komunikasi')) {
      focus.add('communication');
    }
    if (lower.contains('collaboration') || lower.contains('kolaborasi')) {
      focus.add('collaboration');
    }
    if (lower.contains('problem solving') || lower.contains('problem_solving')) {
      focus.add('problem_solving');
    }
    if (focus.isEmpty) {
      focus.addAll(const ['problem_solving', 'collaboration']);
    }
    return focus;
  }

  int _inferQuestionCount(String text) {
    final match = RegExp(r'\b(\d{1,2})\b').firstMatch(text);
    final count = int.tryParse(match?.group(1) ?? '');
    if (count == null || count < 1) return 5;
    return count > 10 ? 10 : count;
  }

  int? _inferTeamSize(String text) {
    final match = RegExp(
      r'(?:team size|tim size|team|tim)\s*(?:=|:)?\s*(\d{1,3})',
      caseSensitive: false,
    ).firstMatch(text);
    return int.tryParse(match?.group(1) ?? '');
  }

  String? _extractCandidateName(String text) {
    final patterns = [
      RegExp(r'kandidat\s+([A-Z][A-Za-z]+(?:\s+[A-Z][A-Za-z]+)*)'),
      RegExp(r'candidate\s+([A-Z][A-Za-z]+(?:\s+[A-Z][A-Za-z]+)*)'),
      RegExp(r'nama\s*:\s*([^\n,]+)', caseSensitive: false),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      final value = match?.group(1)?.trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  String _extractExperienceSummary(String text) {
    final match = RegExp(
      r'(?:pengalaman|experience)\s*:\s*([^\n]+)',
      caseSensitive: false,
    ).firstMatch(text);
    final value = match?.group(1)?.trim();
    if (value != null && value.isNotEmpty) return value;
    return 'Pengalaman kandidat belum dijelaskan detail oleh user.';
  }

  List<String> _extractTaggedList(String text, List<String> labels) {
    for (final label in labels) {
      final match = RegExp(
        '$label\\s*:\\s*([^\\n]+)',
        caseSensitive: false,
      ).firstMatch(text);
      final raw = match?.group(1)?.trim();
      if (raw != null && raw.isNotEmpty) {
        return raw
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }
    }
    return const ['Detail belum lengkap'];
  }

  String _formatResult(HiringSkillResult result) {
    final buffer = StringBuffer();
    buffer.writeln('Mode: ${result.usedMode.name}');
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
          for (final item in jd.responsibilities) {
            buffer.writeln('- $item');
          }
          buffer.writeln('');
          buffer.writeln('## Must Have');
          for (final item in jd.mustHave) {
            buffer.writeln('- $item');
          }
          if (jd.niceToHave.isNotEmpty) {
            buffer.writeln('');
            buffer.writeln('## Nice To Have');
            for (final item in jd.niceToHave) {
              buffer.writeln('- $item');
            }
          }
          if (jd.compensationRange?.isNotEmpty == true) {
            buffer.writeln('');
            buffer.writeln('## Compensation');
            buffer.writeln(jd.compensationRange);
          }
          return buffer.toString().trim();
        }
      case 'create_interview_scorecard':
        final scorecard = result.asScorecard;
        if (scorecard != null) {
          buffer.writeln('# Interview Scorecard');
          buffer.writeln('');
          buffer.writeln('Kandidat: ${scorecard.candidate}');
          buffer.writeln('Role: ${scorecard.role}');
          buffer.writeln('Interviewer: ${scorecard.interviewer}');
          buffer.writeln('');
          for (final comp in scorecard.competencies) {
            buffer.writeln('- ${comp.competency.name}: ${comp.weight}%');
          }
          return buffer.toString().trim();
        }
      case 'generate_star_questions':
        final guide = result.asStarGuide;
        if (guide != null) {
          buffer.writeln('# STAR Questions');
          buffer.writeln('');
          for (var i = 0; i < guide.questions.length; i++) {
            final q = guide.questions[i];
            buffer.writeln('${i + 1}. ${q.question}');
            if (q.lookFor.isNotEmpty) {
              buffer.writeln('Look for: ${q.lookFor.join(', ')}');
            }
            buffer.writeln('');
          }
          return buffer.toString().trim();
        }
      case 'generate_hiring_metrics':
        final metrics = result.asMetrics;
        if (metrics != null) {
          buffer.writeln('# Hiring Metrics');
          buffer.writeln('');
          metrics.funnelMetrics.forEach((key, value) {
            buffer.writeln('- $key: $value');
          });
          if (metrics.redFlags.isNotEmpty) {
            buffer.writeln('');
            buffer.writeln('## Red Flags');
            for (final item in metrics.redFlags) {
              buffer.writeln('- $item');
            }
          }
          return buffer.toString().trim();
        }
      default:
        if ((result.textResponse ?? '').trim().isNotEmpty) {
          buffer.writeln(result.textResponse!.trim());
          return buffer.toString().trim();
        }
    }

    return result.textResponse?.trim().isNotEmpty == true
        ? result.textResponse!.trim()
        : 'Permintaan selesai diproses.';
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat Recruiter')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat Recruiter')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 44, color: Colors.red),
                const SizedBox(height: 12),
                Text(
                  'Gagal membuka sesi chat.\n$_error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _error = null;
                      _isInitializing = true;
                    });
                    _initializeChat();
                  },
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_session?.title ?? 'Chat Recruiter'),
            if (_session?.lastMessagePreview.isNotEmpty == true)
              Text(
                _session!.lastMessagePreview,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSkillChip('JD', 'Job Description'),
                  _buildSkillChip('SC', 'Scorecard'),
                  _buildSkillChip('STAR', 'STAR Questions'),
                  _buildSkillChip('MET', 'Metrics'),
                  _buildSkillChip('FIT', 'Analisis Kandidat'),
                ],
              ),
            ),
          Expanded(
            child: Chat(
              currentUserId: widget.currentUserId,
              resolveUser: _resolveUser,
              chatController: _chatController!,
              builders: _buildBuilders(),
              onMessageSend: _handleSend,
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text('AI recruiter sedang menyiapkan jawaban...'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSkillChip(String short, String label) {
    return ActionChip(
      avatar: Text(short, style: const TextStyle(fontSize: 11)),
      label: Text(label),
      onPressed: () => _handleSend(label.toLowerCase()),
    );
  }

  Builders _buildBuilders() {
    return Builders(
      textMessageBuilder: (
        context,
        message,
        index, {
        isSentByMe = false,
        groupStatus,
      }) {
        return FlyerChatTextMessage(
          message: message,
          index: index,
          onLinkTap: (url, title) {},
        );
      },
      systemMessageBuilder: (
        context,
        message,
        index, {
        isSentByMe = false,
        groupStatus,
      }) {
        return FlyerChatSystemMessage(message: message, index: index);
      },
      textStreamMessageBuilder: (
        context,
        message,
        index, {
        isSentByMe = false,
        groupStatus,
      }) {
        final streamText =
            message.metadata?[_streamTextMetadataKey] as String? ?? '';
        return FlyerChatTextStreamMessage(
          message: message,
          index: index,
          streamState: StreamStateStreaming(streamText),
        );
      },
      fileMessageBuilder: (
        context,
        message,
        index, {
        isSentByMe = false,
        groupStatus,
      }) {
        return FlyerChatFileMessage(message: message, index: index);
      },
    );
  }

  Future<User?> _resolveUser(UserID userId) async {
    return User(
      id: userId,
      name: userId == widget.currentUserId ? 'Anda' : 'Assistant',
    );
  }
}
