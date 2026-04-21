import 'package:objectbox/objectbox.dart';

@Entity()
class SavedJobRecord {
  SavedJobRecord({
    this.id = 0,
    required this.jobId,
    required this.title,
    this.unitLabel,
    this.location,
    required this.savedAt,
    this.notes,
    required this.isActive,
  });

  int id;

  @Unique()
  String jobId;

  String title;
  String? unitLabel;
  String? location;
  int savedAt;
  String? notes;
  bool isActive;
}
