import '../../models/recruiter_job.dart';
import 'api_client.dart';

class JobsApi {
  final ApiClient _client;

  JobsApi(this._client);

  Future<List<RecruiterJob>> getJobs() async {
    final items = await _client.list(prefix: 'job:');
    final jobs = <RecruiterJob>[];
    for (final item in items) {
      if (item.name.split(':').length != 2) {
        continue;
      }
      final json = await _client.getJsonValue(item.name);
      jobs.add(RecruiterJob.fromJson(json));
    }
    return jobs;
  }
}
