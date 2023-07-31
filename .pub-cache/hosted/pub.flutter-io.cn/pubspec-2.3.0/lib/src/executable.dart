import 'json_utils.dart';

/// Defines an executable listed in the 'exectuables' section
/// of the pubspec.yaml.
///
/// Once the package is activated using pub global activate
/// each of the executables listed in the pubspec.yaml will
/// be exectuable.
/// The [name] is the name of the executable you run from the cli.
/// The optional [script] is the name of the dart library in the bin
/// directory. If the [script] isn't supplied this defaults to [name];
/// typing <name> executes bin/<script>.dart.

class Executable extends Jsonable {
  String name;
  String? script;

  Executable(this.name, String? script);
  Executable.fromJson(this.name, String? script);

  /// returns the project relative path to the script.
  ///
  /// e.g.
  /// executables:
  ///   dcli_install: dcli_install
  ///
  /// scriptPath => bin/dcli_install.dart
  ///
  String get scriptPath => 'bin/${script ?? name}.dart';

  @override
  String toJson() => script ?? '';

  bool operator ==(other) => other is Executable && other.script == script;
}
