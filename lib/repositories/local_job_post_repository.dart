import 'dart:convert';

import '../models/job_post_record.dart';
import '../models/recruiter_job.dart';
import '../objectbox.g.dart';
import '../objectbox_store_provider.dart';

class LocalJobPostRepository {
  Future<void> save(RecruiterJob job) async {
    if (!ObjectBoxStoreProvider.isInitialized) {
      await ObjectBoxStoreProvider.initialize();
    }

    final box = ObjectBoxStoreProvider.box<JobPostRecord>();
    final existing = box
        .query(JobPostRecord_.jobId.equals(job.id))
        .build()
        .findFirst();
    final now = DateTime.now().millisecondsSinceEpoch;

    final record = existing ??
        JobPostRecord(
          jobId: job.id,
          title: job.title,
          department: job.department,
          location: job.location,
          description: job.description,
          requirementsJson: '[]',
          status: job.status,
          createdAt: now,
          updatedAt: now,
        );

    record.jobId = job.id;
    record.title = job.title;
    record.department = job.department;
    record.location = job.location;
    record.description = job.description;
    record.requirementsJson = jsonEncode(job.requirements);
    record.status = job.status;
    record.updatedAt = now;

    box.put(record);
  }

  Future<List<RecruiterJob>> list() async {
    if (!ObjectBoxStoreProvider.isInitialized) {
      await ObjectBoxStoreProvider.initialize();
    }

    final box = ObjectBoxStoreProvider.box<JobPostRecord>();
    final records = box
        .query()
        .order(JobPostRecord_.updatedAt, flags: Order.descending)
        .build()
        .find();

    return records.map(_toJob).toList();
  }

  Future<RecruiterJob?> getById(String jobId) async {
    if (!ObjectBoxStoreProvider.isInitialized) {
      await ObjectBoxStoreProvider.initialize();
    }

    final box = ObjectBoxStoreProvider.box<JobPostRecord>();
    final record = box
        .query(JobPostRecord_.jobId.equals(jobId))
        .build()
        .findFirst();

    if (record == null) return null;
    return _toJob(record);
  }

  Future<void> clear() async {
    if (!ObjectBoxStoreProvider.isInitialized) {
      await ObjectBoxStoreProvider.initialize();
    }

    ObjectBoxStoreProvider.box<JobPostRecord>().removeAll();
  }

  RecruiterJob _toJob(JobPostRecord record) {
    final requirements = (jsonDecode(record.requirementsJson) as List<dynamic>)
        .map((item) => item.toString())
        .toList();

    return RecruiterJob(
      id: record.jobId,
      title: record.title,
      department: record.department,
      location: record.location,
      description: record.description,
      requirements: requirements,
      status: record.status,
    );
  }
}
