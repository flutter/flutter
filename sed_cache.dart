import 'dart:io';

void main() {
  void replaceInFile(String path, String from, String to) {
    if (!File(path).existsSync()) return;
    var content = File(path).readAsStringSync();
    if (content.contains(from)) {
      File(path).writeAsStringSync(content.replaceAll(from, to));
      print('Replaced in $path');
    }
  }

  replaceInFile('packages/flutter_tools/lib/src/runner/flutter_command_runner.dart', 'Cache.flutterRoot!', 'cache.flutterRoot');
  replaceInFile('packages/flutter_tools/lib/src/build_system/build_system.dart', '[Cache.flutterRoot]', '[cache.flutterRoot]');
  replaceInFile('packages/flutter_tools/lib/src/project_validator.dart', "'Cache.flutterRoot'", "'cache.flutterRoot'");
  
  // resident_runner.dart uses globals.cache.flutterRoot? Wait! The instruction said:
  // "globals.cache.flutterRoot where globals is still used in unmigrated legacy code, or environment.flutterRootDir in build targets._
  // wait PR 25 cache refactor replaces it. For resident_runner, let's use globals.cache.flutterRoot? Since it accesses globals.fs!
  replaceInFile('packages/flutter_tools/lib/src/resident_runner.dart', 'Cache.flutterRoot', 'globals.cache.flutterRoot');

  // gradle_utils.dart
  replaceInFile('packages/flutter_tools/lib/src/android/gradle_utils.dart', 'Cache.flutterRoot!', 'globals.cache.flutterRoot');

  // fakes.dart
  replaceInFile('packages/flutter_tools/test/src/fakes.dart', 'Cache.flutterRoot ??', 'globals.cache.flutterRoot ??');

  // test_flutter_command_runner.dart
  replaceInFile('packages/flutter_tools/test/src/test_flutter_command_runner.dart', 'Cache.flutterRoot ??=', 'globals.cache.flutterRoot ??=');
  replaceInFile('packages/flutter_tools/test/src/test_flutter_command_runner.dart', 'Cache.flutterRoot =', 'globals.cache.flutterRoot =');
  replaceInFile('packages/flutter_tools/test/src/test_flutter_command_runner.dart', 'Cache.flutterRoot!', 'globals.cache.flutterRoot');
}
