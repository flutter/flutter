import 'package:process_run/src/common/import.dart';
import 'package:process_run/src/shell_utils.dart';

import 'shell_environment_common.dart' as common;

export 'shell_environment_common.dart'
    show ShellEnvironmentAliases, ShellEnvironmentPaths, ShellEnvironmentVars;

/// Use current if already and environment object.
ShellEnvironment asShellEnvironment(Map<String, String>? environment) =>
    (environment is ShellEnvironment)
        ? environment
        : ShellEnvironment(environment: environment);

/// Shell modifiable helpers. should not be modified after being set.
class ShellEnvironment extends common.ShellEnvironmentBase {
  /// Create a new shell environment from the current shellEnvironment.
  ///
  /// Defaults create a full parent environment.
  ///
  /// It is recommended that you apply the environment to a shell. But it can
  /// also be set globally (be aware of the potential effect on other part of
  /// your application) to [shellEnvironment]
  ShellEnvironment({Map<String, String>? environment})
      : super.fromEnvironment(environment: environment);

  /// From a run start content, includeParentEnvironment should later be set
  /// to false
  factory ShellEnvironment.full(
      {Map<String, String>? environment,
      bool includeParentEnvironment = true}) {
    ShellEnvironment newEnvironment;
    // devPrint(environment?.keys.where((element) => element.contains('TEKA')));
    if (includeParentEnvironment) {
      newEnvironment = ShellEnvironment();
      newEnvironment.merge(asShellEnvironment(environment));
    } else {
      newEnvironment = asShellEnvironment(environment);
    }
    return newEnvironment;
  }

  /// Create an empty shell environment.
  ///
  /// Mainly used for testing as it is not easy to which environment variable
  /// are required.
  ShellEnvironment.empty() : super.empty();

  /// From json.
  ///
  /// Mainly used for testing as it is not easy to which environment variable
  /// are required.
  ShellEnvironment.fromJson(Map? map) : super.fromJson(map);

  /// Find a [command] path location in the environment
  String? whichSync(String command) {
    return findExecutableSync(
      command,
      paths,
    );
  }

  /// Find a [command] path location in the environment
  Future<String?> which(String command) async {
    return whichSync(command);
  }
}
