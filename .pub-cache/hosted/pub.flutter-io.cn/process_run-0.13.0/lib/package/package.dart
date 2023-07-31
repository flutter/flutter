import 'dart:io';

import 'package:path/path.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

/// Get package version at given dir.
///
/// Default to current dir. Returns null if the dir does not exists or
/// is not a pub package.
Future<Version?> getPackageVersion({String? dir}) async {
  try {
    dir ??= '.';
    var versionText =
        (loadYaml(await File(join(dir, 'pubspec.yaml')).readAsString())
                as Map)['version']
            .toString();
    var version = Version.parse(versionText);
    return version;
  } catch (_) {
    return null;
  }
}
