import '../models/jobseeker/saved_job.dart';
import '../models/saved_job_record.dart';
import '../objectbox.g.dart';
import '../objectbox_store_provider.dart';

class LocalSavedJobRepository {
  Future<void> save(SavedJob savedJob) async {
    if (!ObjectBoxStoreProvider.isInitialized) {
      await ObjectBoxStoreProvider.initialize();
    }

    final box = ObjectBoxStoreProvider.box<SavedJobRecord>();
    final existing = box
        .query(SavedJobRecord_.jobId.equals(savedJob.jobId))
        .build()
        .findFirst();

    final record =
        existing ??
        SavedJobRecord(
          jobId: savedJob.jobId,
          title: savedJob.title,
          savedAt: savedJob.savedAt.millisecondsSinceEpoch,
          isActive: savedJob.isActive,
        );

    record.jobId = savedJob.jobId;
    record.title = savedJob.title;
    record.unitLabel = savedJob.unitLabel;
    record.location = savedJob.location;
    record.savedAt = savedJob.savedAt.millisecondsSinceEpoch;
    record.notes = savedJob.notes;
    record.isActive = savedJob.isActive;

    box.put(record);
  }

  Future<List<SavedJob>> listAll() async {
    if (!ObjectBoxStoreProvider.isInitialized) {
      await ObjectBoxStoreProvider.initialize();
    }

    final box = ObjectBoxStoreProvider.box<SavedJobRecord>();
    final records = box
        .query()
        .order(SavedJobRecord_.savedAt, flags: Order.descending)
        .build()
        .find();

    return records.map(_toSavedJob).toList();
  }

  Future<List<SavedJob>> listActive() async {
    if (!ObjectBoxStoreProvider.isInitialized) {
      await ObjectBoxStoreProvider.initialize();
    }

    final box = ObjectBoxStoreProvider.box<SavedJobRecord>();
    final records = box
        .query(SavedJobRecord_.isActive.equals(true))
        .order(SavedJobRecord_.savedAt, flags: Order.descending)
        .build()
        .find();

    return records.map(_toSavedJob).toList();
  }

  Future<SavedJob?> getById(String jobId) async {
    if (!ObjectBoxStoreProvider.isInitialized) {
      await ObjectBoxStoreProvider.initialize();
    }

    final box = ObjectBoxStoreProvider.box<SavedJobRecord>();
    final record = box
        .query(SavedJobRecord_.jobId.equals(jobId))
        .build()
        .findFirst();

    if (record == null) return null;
    return _toSavedJob(record);
  }

  Future<bool> isSaved(String jobId) async {
    final saved = await getById(jobId);
    return saved?.isActive ?? false;
  }

  Future<void> unsave(String jobId) async {
    if (!ObjectBoxStoreProvider.isInitialized) {
      await ObjectBoxStoreProvider.initialize();
    }

    final box = ObjectBoxStoreProvider.box<SavedJobRecord>();
    final record = box
        .query(SavedJobRecord_.jobId.equals(jobId))
        .build()
        .findFirst();

    if (record != null) {
      box.remove(record.id);
    }
  }

  Future<void> archive(String jobId) async {
    if (!ObjectBoxStoreProvider.isInitialized) {
      await ObjectBoxStoreProvider.initialize();
    }

    final box = ObjectBoxStoreProvider.box<SavedJobRecord>();
    final record = box
        .query(SavedJobRecord_.jobId.equals(jobId))
        .build()
        .findFirst();

    if (record != null) {
      record.isActive = false;
      box.put(record);
    }
  }

  Future<void> clear() async {
    if (!ObjectBoxStoreProvider.isInitialized) {
      await ObjectBoxStoreProvider.initialize();
    }

    ObjectBoxStoreProvider.box<SavedJobRecord>().removeAll();
  }

  SavedJob _toSavedJob(SavedJobRecord record) {
    return SavedJob(
      jobId: record.jobId,
      title: record.title,
      unitLabel: record.unitLabel,
      location: record.location,
      savedAt: DateTime.fromMillisecondsSinceEpoch(record.savedAt),
      notes: record.notes,
      isActive: record.isActive,
    );
  }
}
