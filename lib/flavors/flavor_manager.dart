import 'app_flavor_config.dart';
import 'flavor_environment.dart';

/// Global flavor manager
class FlavorManager {
  static late AppFlavorConfig _flavor;
  static late FlavorEnvironment _environment;

  static void init(
    AppFlavorConfig flavor, {
    FlavorEnvironment? environment,
  }) {
    _flavor = flavor;
    _environment = environment ?? FlavorEnvironment.fromConfig();
  }

  static AppFlavorConfig get flavor => _flavor;
  static FlavorEnvironment get environment => _environment;

  static bool get isRecruiter => _flavor.type == AppFlavorType.recruiter;
  static bool get isJobSeeker => _flavor.type == AppFlavorType.jobSeeker;
}
