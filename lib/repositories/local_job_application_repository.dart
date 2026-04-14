import 'dart:convert';

import '../models/application_status.dart';
import '../models/job_application.dart';
import '../models/job_application_record.dart';
import '../objectbox.g.dart';
import '../objectbox_store_provider.dart';

class LocalJobApplicationRepository {
  Future<void> save(JobApplication application) async {
    if (!ObjectBoxStoreProvider.isInitialized) {
      await ObjectBoxStoreProvider.initialize();
    }

    final box = ObjectBoxStoreProvider.box<JobApplicationRecord>();
    final existing = box
        .query(JobApplicationRecord_.applicationId.equals(application.id))
        .build()
        .findFirst();

    final record = existing ?? JobApplicationRecord(
      applicationId: application.id,
      jobId: application.jobId,
      jobTitle: application.jobTitle,
      status: application.status.name,
      appliedAt: application.appliedAt.millisecondsSinceEpoch,
      updatedAt: application.updatedAt.millisecondsSinceEpoch,
    );

    record.jobId = application.jobId;
    record.candidateId = application.candidateId;
    record.jobTitle = application.jobTitle;
    record.company = application.company;
    record.location = application.location;
    record.status = application.status.name;
    record.appliedAt = application.appliedAt.millisecondsSinceEpoch;
    record.updatedAt = application.updatedAt.millisecondsSinceEpoch;
    record.expectedSalary = application.expectedSalary;
    record.coverLetter = application.coverLetter;
    record.resumeId = application.resumeId;
    record.interviewDatesJson = application.interviewDates != null
        ? jsonEncode(application.interviewDates!.map((d) => d.millisecondsSinceEpoch).toList())
        : null;
    record.rejectionReason = application.rejectionReason;
    record.recruiterNotes = application.recruiterNotes;
    record.internalRating = application.internalRating;
    record.source = application.source;

    box.put(record);
  }

  Future<List<JobApplication>> listAll() async {
    if (!ObjectBoxStoreProvider.isInitialized) {
      await ObjectBoxStoreProvider.initialize();
    }

    final box = ObjectBoxStoreProvider.box<JobApplicationRecord>();
    final records = box
        .query()
        .order(JobApplicationRecord_.updatedAt, flags: Order.descending)
        .build()
        .find();

    return records.map(_toApplication).toList();
  }

  Future<List<JobApplication>> listByJobId(String jobId) async {
    if (!ObjectBoxStoreProvider.isInitialized) {
      await ObjectBoxStoreProvider.initialize();
    }

    final box = ObjectBoxStoreProvider.box<JobApplicationRecord>();
    final records = box
        .query(JobApplicationRecord_.jobId.equals(jobId))
        .order(JobApplicationRecord_.updatedAt, flags: Order.descending)
        .build()
        .find();

    return records.map(_toApplication).toList();
  }

  Future<List<JobApplication>> listByStatus(ApplicationStatus status) async {
    if (!ObjectBoxStoreProvider.isInitialized) {
      await ObjectBoxStoreProvider.initialize();
    }

    final box = ObjectBoxStoreProvider.box<JobApplicationRecord>();
    final records = box
        .query(JobApplicationRecord_.status.equals(status.name))
        .order(JobApplicationRecord_.updatedAt, flags: Order.descending)
        .build()
        .find();

    return records.map(_toApplication).toList();
  }

  Future<List<JobApplication>> listActiveApplications() async {
    if (!ObjectBoxStoreProvider.isInitialized) {
      await ObjectBoxStoreProvider.initialize();
    }

    final box = ObjectBoxStoreProvider.box<JobApplicationRecord>();
    final activeStatuses = ApplicationStatus.values
        .where((s) => s.isActive)
        .map((s) => s.name)
        .toList();

    final records = box
        .query(JobApplicationRecord_.status.oneOf(activeStatuses))
        .order(JobApplicationRecord_.updatedAt, flags: Order.descending)
        .build()
        .find();

    return records.map(_toApplication).toList();
  }

  Future<JobApplication?> getById(String applicationId) async {
    if (!ObjectBoxStoreProvider.isInitialized) {
      await ObjectBoxStoreProvider.initialize();
    }

    final box = ObjectBoxStoreProvider.box<JobApplicationRecord>();
    final record = box
        .query(JobApplicationRecord_.applicationId.equals(applicationId))
        .build()
        .findFirst();

    if (record == null) return null;
    return _toApplication(record);
  }

  Future<JobApplication?> getByJobId(String jobId) async {
    if (!ObjectBoxStoreProvider.isInitialized) {
      await ObjectBoxStoreProvider.initialize();
    }

    final box = ObjectBoxStoreProvider.box<JobApplicationRecord>();
    final record = box
        .query(JobApplicationRecord_.jobId.equals(jobId))
        .build()
        .findFirst();

    if (record == null) return null;
    return _toApplication(record);
  }

  Future<void> delete(String applicationId) async {
    if (!ObjectBoxStoreProvider.isInitialized) {
      await ObjectBoxStoreProvider.initialize();
    }

    final box = ObjectBoxStoreProvider.box<JobApplicationRecord>();
    final record = box
        .query(JobApplicationRecord_.applicationId.equals(applicationId))
        .build()
        .findFirst();

    if (record != null) {
      box.remove(record.id);
    }
  }

  Future<void> clear() async {
    if (!ObjectBoxStoreProvider.isInitialized) {
      await ObjectBoxStoreProvider.initialize();
    }

    ObjectBoxStoreProvider.box<JobApplicationRecord>().removeAll();
  }

  JobApplication _toApplication(JobApplicationRecord record) {
    List<DateTime>? parseInterviewDates() {
      if (record.interviewDatesJson == null) return null;
      try {
        final List<dynamic> decoded = jsonDecode(record.interviewDatesJson!);
        return decoded.map((ms) => DateTime.fromMillisecondsSinceEpoch(ms as int)).toList();
      } catch (_) {
        return null;
      }
    }

    ApplicationStatus parseStatus(String status) {
      return ApplicationStatus.values.firstWhere(
        (s) => s.name == status,
        orElse: () => ApplicationStatus.applied,
      );
    }

    return JobApplication(
      id: record.applicationId,
      jobId: record.jobId,
      candidateId: record.candidateId,
      jobTitle: record.jobTitle,
      company: record.company,
      location: record.location,
      status: parseStatus(record.status),
      appliedAt: DateTime.fromMillisecondsSinceEpoch(record.appliedAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(record.updatedAt),
      expectedSalary: record.expectedSalary,
      coverLetter: record.coverLetter,
      resumeId: record.resumeId,
      interviewDates: parseInterviewDates(),
      rejectionReason: record.rejectionReason,
      recruiterNotes: record.recruiterNotes,
      internalRating: record.internalRating,
      source: record.source,
    );
  }
}
