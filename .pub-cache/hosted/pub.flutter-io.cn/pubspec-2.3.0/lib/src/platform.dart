import 'json_utils.dart';

/// Defines an platform listed in the 'platforms' section
/// of the pubspec.yaml.
///
/// The [platform] is the name of the platform that you package
/// supports.
class Platform extends Jsonable {
  String name;

  Platform(this.name);
  Platform.fromJson(this.name);

  @override
  String toJson() => '';

  bool operator ==(other) => other is Platform && other.name == name;
}
