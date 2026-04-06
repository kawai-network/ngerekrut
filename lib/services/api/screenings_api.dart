import '../../models/recruiter_shortlist.dart';
import 'api_client.dart';

class ScreeningsApi {
  final ApiClient _client;

  ScreeningsApi(this._client);

  Future<ScreeningRun> createScreening(String jobId, {int topN = 3}) async {
    throw const ApiException(
      'Direct Cloudflare KV mode is read-only for screening runs. Load latest shortlist instead.',
    );
  }

  Future<ScreeningRun> getScreening(String jobId, String screeningId) async {
    final json = await _client.getJsonValue('job:$jobId:screening:$screeningId');
    return ScreeningRun.fromJson(json);
  }

  Future<RecruiterShortlistResult> getScreeningResults(
    String jobId,
    String screeningId,
  ) async {
    final json = await _client.getJsonValue(
      'job:$jobId:screening:$screeningId:summary',
    );
    return RecruiterShortlistResult.fromJson(json);
  }

  Future<RecruiterShortlistResult> getLatestShortlist(String jobId) async {
    final json = await _client.getJsonValue('job:$jobId:shortlist:latest');
    return RecruiterShortlistResult.fromJson(json);
  }
}
