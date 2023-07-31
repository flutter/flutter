import 'dart:io';

import 'package:process_run/shell.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

Future<void> main() async {
  var shell = Shell();
  var version = Version.parse(
      (loadYaml(await File('pubspec.yaml').readAsString()) as Map)['version']
          .toString());
  print('Version $version');
  print('Tap anything or CTRL-C: $version');

  await sharedStdIn.first;
  await shell.run('''
git tag v$version
git push origin --tags
''');
  await sharedStdIn.terminate();
}
