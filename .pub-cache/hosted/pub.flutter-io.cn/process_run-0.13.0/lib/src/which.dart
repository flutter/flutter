import 'dart:async';

import 'package:path/path.dart';
import 'package:process_run/src/shell_environment.dart';

Future<String?> which(String command,
    {@Deprecated('Use environment') Map<String, String>? env,
    Map<String, String>? environment,
    bool includeParentEnvironment = true}) async {
  return whichSync(command,
      // ignore: deprecated_member_use, deprecated_member_use_from_same_package
      env: env,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment);
}

/// Find the command according to the [paths] or env variables (`PATH`)
String? whichSync(String command,
    {@Deprecated('Use environment') Map<String, String>? env,
    Map<String, String>? environment,
    bool includeParentEnvironment = true}) {
  // only valid for single commands
  if (basename(command) != command) {
    return null;
  }
  // Merge system environment
  var shellEnvironment = ShellEnvironment.full(
      environment: environment,
      includeParentEnvironment: includeParentEnvironment);
  return shellEnvironment.whichSync(command);
}
