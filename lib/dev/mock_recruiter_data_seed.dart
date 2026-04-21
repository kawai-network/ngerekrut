library;

import 'package:ngerekrut/langchain/langchain.dart';

import '../models/hiring_models.dart';
import '../models/candidate.dart';
import '../models/interview_guide_record.dart';
import '../models/candidate_scorecard_record.dart';
import '../models/recruiter_shortlist.dart';
import '../models/recruiter_shortlist_record.dart';
import '../models/chat_session_record.dart';
import '../models/recruiter_job.dart';
import '../objectbox_store_provider.dart';
import '../repositories/chat_session_repository.dart';
import '../repositories/candidate_repository.dart';
import '../repositories/interview_guide_artifact_repository.dart';
import '../repositories/job_posting_repository.dart';
import '../repositories/scorecard_artifact_repository.dart';
import '../repositories/shortlist_artifact_repository.dart';

class MockRecruiterDataSeed {
  MockRecruiterDataSeed._();

  static Future<void> seed({bool resetExisting = true}) async {
    if (!ObjectBoxStoreProvider.isInitialized) {
      await ObjectBoxStoreProvider.initialize();
    }

    if (resetExisting) {
      _clearLocalArtifacts();
    }

    await _seedChatSessions();
    await _seedScreeningData();
    await _seedInterviewData();
  }

  static void _clearLocalArtifacts() {
    ObjectBoxStoreProvider.box<ChatSessionRecord>().removeAll();
    ObjectBoxStoreProvider.box<ChatMessageRecord>().removeAll();
    ObjectBoxStoreProvider.box<RecruiterShortlistRecord>().removeAll();
    ObjectBoxStoreProvider.box<CandidateScorecardRecord>().removeAll();
    ObjectBoxStoreProvider.box<InterviewGuideRecord>().removeAll();
  }

  static Future<void> _seedChatSessions() async {
    final repository = ChatSessionRepository();
    await repository.initialize();

    final lisa = repository.createSession(title: 'Senior Flutter Developer');
    ChatMessage.ai(
      'Siap bantu bikin lowongan. Posisi yang akan kita buka: Senior Flutter Developer untuk tim Engineering.',
    ).save(lisa.sessionId);
    repository.recordMessage(
      lisa.sessionId,
      'Siap bantu bikin lowongan. Posisi yang akan kita buka: Senior Flutter Developer untuk tim Engineering.',
    );
    ChatMessage.humanText(
      'Tolong buat JD senior flutter developer remote.',
    ).save(lisa.sessionId);
    repository.recordMessage(
      lisa.sessionId,
      'Tolong buat JD senior flutter developer remote.',
    );
    ChatMessage.ai(
      'Draft lowongan sudah siap dengan requirement Flutter, state management, testing, dan kolaborasi lintas fungsi.',
    ).save(lisa.sessionId);
    repository.recordMessage(
      lisa.sessionId,
      'Draft lowongan sudah siap dengan requirement Flutter, state management, testing, dan kolaborasi lintas fungsi.',
    );
    repository.setTitle(
      lisa.sessionId,
      'Senior Flutter Developer - Engineering',
    );

    final raka = repository.createSession(title: 'Screening Backend Engineer');
    ChatMessage.ai(
      'Saya sudah ranking 5 kandidat untuk Backend Engineer. Dua kandidat teratas layak lanjut ke tahap tes.',
    ).save(raka.sessionId);
    repository.recordMessage(
      raka.sessionId,
      'Saya sudah ranking 5 kandidat untuk Backend Engineer. Dua kandidat teratas layak lanjut ke tahap tes.',
    );
    repository.setTitle(raka.sessionId, 'Screening - Backend Engineer');

    final maya = repository.createSession(title: 'Interview Budi Santoso');
    ChatMessage.ai(
      'Interview guide untuk Budi Santoso siap. Fokus utama: problem solving, komunikasi, dan ownership.',
    ).save(maya.sessionId);
    repository.recordMessage(
      maya.sessionId,
      'Interview guide untuk Budi Santoso siap. Fokus utama: problem solving, komunikasi, dan ownership.',
    );
    repository.setTitle(maya.sessionId, 'Interview - Budi Santoso');
  }

  static Future<void> _seedScreeningData() async {
    final candidateRepository = CandidateRepository();
    final shortlistRepository = ShortlistArtifactRepository();
    final jobRepository = JobPostingRepository();

    await candidateRepository.save(
      const RecruiterCandidate(
        id: 'cand_budi',
        name: 'Budi Santoso',
        headline: 'Senior Flutter Engineer',
        yearsOfExperience: 6,
        stage: 'interview',
        profile: CandidateProfile(
          skills: ['Flutter', 'Dart', 'Testing', 'Architecture'],
          summary:
              'Memimpin mobile squad dan terbiasa mengawal delivery aplikasi Flutter skala produk.',
        ),
      ),
    );
    await candidateRepository.save(
      const RecruiterCandidate(
        id: 'cand_sinta',
        name: 'Sinta Maharani',
        headline: 'Mobile Engineer',
        yearsOfExperience: 4,
        stage: 'screening',
        profile: CandidateProfile(
          skills: ['Flutter', 'Firebase', 'Product Collaboration'],
          summary:
              'Berpengalaman membangun fitur mobile lintas fungsi dan cepat beradaptasi di domain baru.',
        ),
      ),
    );
    await candidateRepository.save(
      const RecruiterCandidate(
        id: 'cand_andi',
        name: 'Andi Prakoso',
        headline: 'Android Engineer',
        yearsOfExperience: 5,
        stage: 'review',
        profile: CandidateProfile(
          skills: ['Android', 'Kotlin', 'Flutter'],
          summary:
              'Kuat di Android native dan mulai aktif menangani delivery Flutter di beberapa proyek terakhir.',
        ),
      ),
    );
    await candidateRepository.save(
      const RecruiterCandidate(
        id: 'cand_fitri',
        name: 'Fitri Aulia',
        headline: 'Admin Gudang Senior',
        yearsOfExperience: 5,
        stage: 'interview',
        profile: CandidateProfile(
          skills: ['WMS', 'Inventory', 'Administrasi'],
          summary:
              'Pengalaman operasional gudang kuat dengan rekam jejak administrasi dan kontrol stok yang rapi.',
        ),
      ),
    );
    await candidateRepository.save(
      const RecruiterCandidate(
        id: 'cand_deni',
        name: 'Deni Ramadhan',
        headline: 'Warehouse Operations Staff',
        yearsOfExperience: 3,
        stage: 'screening',
        profile: CandidateProfile(
          skills: ['Operasional Gudang', 'Problem Solving', 'Stock Checking'],
          summary:
              'Berpengalaman di operasional gudang dan cukup kuat di troubleshooting proses lapangan.',
        ),
      ),
    );

    await jobRepository.create(
      const RecruiterJob(
        id: 'job_flutter_001',
        title: 'Senior Flutter Developer',
        department: 'Engineering',
        location: 'Jakarta / Remote',
        description:
            'Memimpin pengembangan aplikasi Flutter, menjaga code quality, dan berkolaborasi dengan product dan design.',
        requirements: [
          '4+ tahun pengalaman Flutter',
          'Paham state management dan testing',
          'Mampu memimpin delivery fitur',
        ],
        status: 'active',
      ),
    );

    await jobRepository.create(
      const RecruiterJob(
        id: 'job_warehouse_001',
        title: 'Admin Gudang',
        department: 'Operations',
        location: 'Depok',
        description:
            'Menangani administrasi gudang, stok masuk/keluar, dan koordinasi operasional harian.',
        requirements: [
          'Teliti dan rapi',
          'Pengalaman administrasi gudang',
          'Terbiasa dengan WMS menjadi nilai tambah',
        ],
        status: 'active',
      ),
    );

    await jobRepository.create(
      const RecruiterJob(
        id: 'job_backend_001',
        title: 'Backend Engineer',
        department: 'Engineering',
        location: 'Bandung / Hybrid',
        description:
            'Mengembangkan service backend yang scalable untuk produk inti perusahaan.',
        requirements: [
          'Pengalaman Golang atau Node.js',
          'Paham database dan distributed systems',
          'Terbiasa code review dan observability',
        ],
        status: 'draft',
      ),
    );

    await shortlistRepository.save(
      RecruiterShortlistResult(
        screeningId: 'screen_flutter_001',
        jobId: 'job_flutter_001',
        status: 'completed',
        summary:
            'Dari 5 kandidat Senior Flutter Developer, dua kandidat teratas sangat kuat di Flutter architecture dan mobile delivery.',
        createdAt: DateTime.now().millisecondsSinceEpoch - 86400000,
        usedMode: 'local',
        rankedCandidates: const [
          RecruiterShortlistEntry(
            candidateId: 'cand_budi',
            candidateName: 'Budi Santoso',
            rank: 1,
            totalScore: 91,
            scoreBreakdown: RecruiterScoreBreakdown(
              skillMatch: 95,
              relevantExperience: 90,
              domainFit: 88,
              communicationClarity: 92,
              growthPotential: 89,
              penalty: 0,
            ),
            strengths: [
              'Flutter architecture kuat',
              'Pernah memimpin mobile squad',
              'Testing discipline baik',
            ],
            gaps: ['Belum banyak exposure ke iOS native'],
            recommendation: 'strong_shortlist',
            rationale:
                'Sangat cocok untuk memimpin pengembangan Flutter dan menjaga kualitas delivery.',
          ),
          RecruiterShortlistEntry(
            candidateId: 'cand_sinta',
            candidateName: 'Sinta Maharani',
            rank: 2,
            totalScore: 86,
            scoreBreakdown: RecruiterScoreBreakdown(
              skillMatch: 90,
              relevantExperience: 84,
              domainFit: 82,
              communicationClarity: 88,
              growthPotential: 90,
              penalty: 0,
            ),
            strengths: [
              'Cepat belajar domain baru',
              'Komunikasi lintas fungsi baik',
            ],
            gaps: ['Belum pernah handle scale-up besar'],
            recommendation: 'shortlist',
            rationale:
                'Layak lanjut ke tes dan interview untuk validasi kedalaman teknis.',
          ),
          RecruiterShortlistEntry(
            candidateId: 'cand_andi',
            candidateName: 'Andi Prakoso',
            rank: 3,
            totalScore: 74,
            scoreBreakdown: RecruiterScoreBreakdown(
              skillMatch: 76,
              relevantExperience: 72,
              domainFit: 74,
              communicationClarity: 73,
              growthPotential: 78,
              penalty: 0,
            ),
            strengths: ['Pengalaman Android native kuat'],
            gaps: ['Flutter belum cukup dalam'],
            recommendation: 'review',
            rationale:
                'Masih mungkin dipertimbangkan jika fokus peran lebih ke mobile umum.',
          ),
        ],
        topCandidates: const [
          RecruiterShortlistEntry(
            candidateId: 'cand_budi',
            candidateName: 'Budi Santoso',
            rank: 1,
            totalScore: 91,
            scoreBreakdown: RecruiterScoreBreakdown(
              skillMatch: 95,
              relevantExperience: 90,
              domainFit: 88,
              communicationClarity: 92,
              growthPotential: 89,
              penalty: 0,
            ),
            strengths: [
              'Flutter architecture kuat',
              'Pernah memimpin mobile squad',
              'Testing discipline baik',
            ],
            gaps: ['Belum banyak exposure ke iOS native'],
            recommendation: 'strong_shortlist',
            rationale:
                'Sangat cocok untuk memimpin pengembangan Flutter dan menjaga kualitas delivery.',
          ),
          RecruiterShortlistEntry(
            candidateId: 'cand_sinta',
            candidateName: 'Sinta Maharani',
            rank: 2,
            totalScore: 86,
            scoreBreakdown: RecruiterScoreBreakdown(
              skillMatch: 90,
              relevantExperience: 84,
              domainFit: 82,
              communicationClarity: 88,
              growthPotential: 90,
              penalty: 0,
            ),
            strengths: [
              'Cepat belajar domain baru',
              'Komunikasi lintas fungsi baik',
            ],
            gaps: ['Belum pernah handle scale-up besar'],
            recommendation: 'shortlist',
            rationale:
                'Layak lanjut ke tes dan interview untuk validasi kedalaman teknis.',
          ),
        ],
      ),
    );

    await shortlistRepository.save(
      RecruiterShortlistResult(
        screeningId: 'screen_warehouse_001',
        jobId: 'job_warehouse_001',
        status: 'completed',
        summary:
            'Untuk Admin Gudang, satu kandidat langsung layak lanjut interview dan satu kandidat perlu tes tambahan.',
        createdAt: DateTime.now().millisecondsSinceEpoch - 5400000,
        usedMode: 'local',
        rankedCandidates: const [
          RecruiterShortlistEntry(
            candidateId: 'cand_fitri',
            candidateName: 'Fitri Aulia',
            rank: 1,
            totalScore: 88,
            scoreBreakdown: RecruiterScoreBreakdown(
              skillMatch: 87,
              relevantExperience: 90,
              domainFit: 88,
              communicationClarity: 84,
              growthPotential: 86,
              penalty: 0,
            ),
            strengths: ['Pengalaman WMS', 'Administrasi rapi'],
            gaps: ['Perlu peningkatan komunikasi eskalasi'],
            recommendation: 'shortlist',
            rationale:
                'Paling siap untuk peran operasional gudang dengan masa adaptasi minim.',
          ),
          RecruiterShortlistEntry(
            candidateId: 'cand_deni',
            candidateName: 'Deni Ramadhan',
            rank: 2,
            totalScore: 77,
            scoreBreakdown: RecruiterScoreBreakdown(
              skillMatch: 75,
              relevantExperience: 78,
              domainFit: 76,
              communicationClarity: 79,
              growthPotential: 80,
              penalty: 0,
            ),
            strengths: ['Problem solving bagus'],
            gaps: ['Belum pernah pakai WMS'],
            recommendation: 'test_first',
            rationale:
                'Masih menarik, tetapi perlu divalidasi dengan tes operasional sederhana.',
          ),
        ],
        topCandidates: const [
          RecruiterShortlistEntry(
            candidateId: 'cand_fitri',
            candidateName: 'Fitri Aulia',
            rank: 1,
            totalScore: 88,
            scoreBreakdown: RecruiterScoreBreakdown(
              skillMatch: 87,
              relevantExperience: 90,
              domainFit: 88,
              communicationClarity: 84,
              growthPotential: 86,
              penalty: 0,
            ),
            strengths: ['Pengalaman WMS', 'Administrasi rapi'],
            gaps: ['Perlu peningkatan komunikasi eskalasi'],
            recommendation: 'shortlist',
            rationale:
                'Paling siap untuk peran operasional gudang dengan masa adaptasi minim.',
          ),
        ],
      ),
    );
  }

  static Future<void> _seedInterviewData() async {
    final guideRepository = InterviewGuideArtifactRepository();
    final scorecardRepository = ScorecardArtifactRepository();

    await guideRepository.save(
      jobId: 'job_flutter_001',
      candidateId: 'cand_budi',
      candidateName: 'Budi Santoso',
      guide: const STARInterviewGuide(
        role: 'Senior Flutter Developer',
        questions: [
          STARQuestion(
            competency: 'problem_solving',
            question:
                'Ceritakan saat Anda harus memperbaiki arsitektur Flutter yang sudah sulit di-maintain.',
            lookFor: ['Analisis akar masalah', 'Keputusan teknis', 'Outcome'],
          ),
          STARQuestion(
            competency: 'collaboration',
            question:
                'Bagaimana Anda menyelaraskan ekspektasi tim produk dan engineering ketika timeline mepet?',
            lookFor: ['Komunikasi', 'Prioritization', 'Stakeholder management'],
          ),
        ],
        scoringGuide:
            'Nilai tinggi jika kandidat memberi contoh konkret, ownership jelas, dan menunjukkan dampak bisnis.',
      ),
      usedMode: 'local',
    );

    await scorecardRepository.save(
      jobId: 'job_flutter_001',
      candidateId: 'cand_budi',
      candidateName: 'Budi Santoso',
      scorecard: InterviewScorecard(
        candidate: 'Budi Santoso',
        role: 'Senior Flutter Developer',
        interviewer: 'Maya',
        date: DateTime.now().subtract(const Duration(hours: 6)),
        interviewType: InterviewType.technical,
        competencies: const [
          ScorecardEntry(
            competency: Competency.technicalSkills,
            weight: 35,
            score: 5,
            evidence:
                'Menjelaskan state management dan testing strategy dengan rinci.',
            strongSignals: ['Architecture kuat', 'Testing mindset'],
            concerns: [],
          ),
          ScorecardEntry(
            competency: Competency.communication,
            weight: 25,
            score: 4,
            evidence: 'Komunikasi jelas dan terstruktur.',
            strongSignals: ['Jelas', 'Terukur'],
            concerns: ['Masih terlalu teknis untuk audience non-tech'],
          ),
        ],
        weightedScore: 4.5,
        recommendation: HiringRecommendation.hire,
        summary:
            'Kandidat kuat untuk memimpin pengembangan Flutter dan cukup matang dalam pengambilan keputusan teknis.',
        nextSteps: 'Lanjut final interview dengan product lead.',
      ),
      usedMode: 'local',
    );

    await scorecardRepository.save(
      jobId: 'job_warehouse_001',
      candidateId: 'cand_fitri',
      candidateName: 'Fitri Aulia',
      scorecard: InterviewScorecard(
        candidate: 'Fitri Aulia',
        role: 'Admin Gudang',
        interviewer: 'Raka',
        date: DateTime.now().subtract(const Duration(hours: 3)),
        interviewType: InterviewType.behavioral,
        competencies: const [
          ScorecardEntry(
            competency: Competency.problemSolving,
            weight: 30,
            score: 4,
            evidence: 'Punya contoh konkret menangani mismatch stok.',
            strongSignals: ['Praktis', 'Tenang saat eskalasi'],
            concerns: [],
          ),
          ScorecardEntry(
            competency: Competency.growthMindset,
            weight: 20,
            score: 4,
            evidence: 'Cepat belajar software baru.',
            strongSignals: ['Adaptif'],
            concerns: [],
          ),
        ],
        weightedScore: 4.1,
        recommendation: HiringRecommendation.hire,
        summary:
            'Cocok untuk peran admin gudang dengan kebutuhan adaptasi rendah.',
        nextSteps: 'Siapkan offering draft.',
      ),
      usedMode: 'local',
    );
  }
}
