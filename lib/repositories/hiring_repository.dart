import '../models/recruiter_job.dart';
import '../models/recruiter_shortlist.dart';
import '../services/api/candidates_api.dart';
import '../services/api/jobs_api.dart';
import '../services/api/screenings_api.dart';

class HiringRepository {
  final JobsApi _jobsApi;
  final CandidatesApi _candidatesApi;
  final ScreeningsApi _screeningsApi;

  HiringRepository({
    required JobsApi jobsApi,
    required CandidatesApi candidatesApi,
    required ScreeningsApi screeningsApi,
  }) : _jobsApi = jobsApi,
       _candidatesApi = candidatesApi,
       _screeningsApi = screeningsApi;

  Future<List<RecruiterJob>> fetchJobs() => _jobsApi.getJobs();

  Future<JobCandidatesResponse> fetchCandidates(String jobId) =>
      _candidatesApi.getCandidatesByJob(jobId);

  Future<ScreeningRun> runScreening(String jobId, {int topN = 3}) =>
      _screeningsApi.createScreening(jobId, topN: topN);

  Future<ScreeningRun> getScreening(String jobId, String screeningId) =>
      _screeningsApi.getScreening(jobId, screeningId);

  Future<RecruiterShortlistResult> fetchShortlist(
    String jobId,
    String screeningId,
  ) => _screeningsApi.getScreeningResults(jobId, screeningId);

  Future<RecruiterShortlistResult> fetchLatestShortlist(String jobId) =>
      _screeningsApi.getLatestShortlist(jobId);
}
