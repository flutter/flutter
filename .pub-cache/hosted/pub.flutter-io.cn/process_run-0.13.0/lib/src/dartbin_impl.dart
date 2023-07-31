import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/src/shell_utils.dart';
import 'package:process_run/src/user_config.dart';

bool _dartExecutableLock = false;

var debugDartExecutableForceWhich = false;

String? findDartExecutableSync(List<String> paths) {
  return findExecutableSync('dart', paths);
}

String? resolveDartExecutable({Map<String, String>? environment}) {
  if (!_dartExecutableLock) {
    _dartExecutableLock = true;
    try {
      var dartExecutable =
          findDartExecutableSync(getUserPaths(environment ?? userEnvironment));
      // Handle the flutter case
      if (dartExecutable != null) {
        return findFlutterDartExecutableSync(dirname(dartExecutable)) ??
            dartExecutable;
      } else {
        return null;
      }
    } finally {
      _dartExecutableLock = false;
    }
  } else {
    // Null when building initial user config
    return null;
  }
}

// Find dart in the cache dir
String? findFlutterDartExecutableSync(String path) {
  return findDartExecutableSync([join(path, 'cache', 'dart-sdk', 'bin')]);
}

String? _resolvedDartExecutable;

///
/// Get dart vm either from executable or using the which command
///
String? get resolvedDartExecutable => _resolvedDartExecutable ??= () {
      var executable = platformResolvedExecutable;
      if (executable != null) {
        return executable;
      }

      return resolveDartExecutable();
    }();

String? _platformResolvedExecutable;

String? get platformResolvedExecutable {
  if (!debugDartExecutableForceWhich) {
    return _platformResolvedExecutable ??= () {
      var executable = Platform.resolvedExecutable;
      if (basenameWithoutExtension(executable) == 'dart') {
        return executable;
      }
    }();
  }
  return null;
}

set resolvedDartExecutable(String? dartExecutable) =>
    _resolvedDartExecutable = dartExecutable;
