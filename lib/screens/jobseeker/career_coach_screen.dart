/// Career Coach Screen - AI chat for career guidance
library;

import 'package:flutter/material.dart';
import '../../app/runtime_config.dart';
import '../../ai/assistants/assistant_context.dart';
import '../../ai/assistants/dina_career_coach_assistant.dart';
import '../../models/candidate.dart';
import '../../repositories/candidate_repository.dart';
import '../../services/hybrid_ai_service.dart';
import '../../services/shared_identity_service.dart';
import '../assistant_chat_screen.dart';

class CareerCoachScreen extends StatefulWidget {
  const CareerCoachScreen({super.key});

  @override
  State<CareerCoachScreen> createState() => _CareerCoachScreenState();
}

class _CareerCoachScreenState extends State<CareerCoachScreen> {
  final CandidateRepository _candidateRepo = CandidateRepository();
  final HybridAIService _aiService = HybridAIService(
    cloudApiKey: readConfig('OPENAI_API_KEY'),
  );

  bool _isLoading = true;
  RecruiterCandidate? _candidate;

  @override
  void initState() {
    super.initState();
    _loadCandidateData();
  }

  Future<void> _loadCandidateData() async {
    try {
      final candidate = await _candidateRepo.getById(
        SharedIdentityService.jobseekerUserId,
      );
      if (mounted) {
        setState(() {
          _candidate = candidate;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return AssistantChatScreen(
      assistant: DinaAssistant.config,
      aiService: _aiService,
      context: _buildAssistantContext(),
      sessionId: 'career_coach_${SharedIdentityService.jobseekerUserId}',
    );
  }

  /// Build assistant context with CV data
  AssistantContext _buildAssistantContext() {
    if (_candidate == null) {
      return const AssistantContext(
        extraData: {
          'hint': 'User belum upload CV. Prompt user untuk upload CV dulu.',
          'has_cv': 'false',
        },
      );
    }

    // Build candidate context from CV data
    final candidateContext = AssistantCandidateContext(
      id: _candidate!.id,
      name: _candidate!.name,
      title: 'Jobseeker',
      score: 0, // N/A for career coach
      recommendation: 'N/A',
      strengths: _candidate!.profile?.skills ?? [],
      redFlags: [],
      summary: _candidate!.profile?.summary ?? '',
    );

    return AssistantContext(
      candidates: [candidateContext],
      extraData: {
        'years_of_experience': _candidate!.yearsOfExperience?.toString() ?? '0',
        'headline': _candidate!.headline ?? '',
        'stage': _candidate!.stage,
        'has_cv': 'true',
        'hint': 'User profile dengan CV tersedia. Berikan saran yang personalized.',
        'skills': _candidate!.profile?.skills.join(', ') ?? '',
        'summary': _candidate!.profile?.summary ?? '',
      },
    );
  }
}
