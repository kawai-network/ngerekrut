import 'app_flavor_config.dart';

/// Global flavor manager
class FlavorManager {
  static late AppFlavorConfig _flavor;

  static void init(AppFlavorConfig flavor) {
    _flavor = flavor;
  }

  static AppFlavorConfig get flavor => _flavor;

  static bool get isRecruiter => _flavor.type == AppFlavorType.recruiter;
  static bool get isJobSeeker => _flavor.type == AppFlavorType.jobSeeker;
}
