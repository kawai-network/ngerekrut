import '../../models/recruiter_candidate.dart';
import '../../models/recruiter_job.dart';
import 'api_client.dart';

class JobCandidatesResponse {
  final RecruiterJob job;
  final List<RecruiterCandidate> candidates;

  const JobCandidatesResponse({
    required this.job,
    required this.candidates,
  });
}

class CandidatesApi {
  final ApiClient _client;

  CandidatesApi(this._client);

  Future<JobCandidatesResponse> getCandidatesByJob(String jobId) async {
    final job = await _client.getJsonValue('job:$jobId');
    final items = await _client.list(prefix: 'job:$jobId:candidate:');
    final candidates = <RecruiterCandidate>[];
    for (final item in items) {
      if (item.name.endsWith(':resume')) {
        continue;
      }
      final json = await _client.getJsonValue(item.name);
      candidates.add(RecruiterCandidate.fromJson(json));
    }
    return JobCandidatesResponse(
      job: RecruiterJob.fromJson(job),
      candidates: candidates,
    );
  }
}
