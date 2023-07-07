// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:markdown/markdown.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';

import 'common/generate_common.dart';
import 'dart/generate_dart.dart' as dart show Api, api, DartGenerator;
import 'java/generate_java.dart' as java show Api, api, JavaGenerator;

final bool _stampPubspecVersion = false;

/// Parse the 'service.md' into a model and generate both Dart and Java
/// libraries.
void main(List<String> args) async {
  String appDirPath = dirname(Platform.script.toFilePath());

  // Parse service.md into a model.
  final file = File(
    normalize(join(appDirPath, '../../../runtime/vm/service/service.md')),
  );
  final document = Document();
  final buf = StringBuffer(file.readAsStringSync());
  final nodes = document.parseLines(buf.toString().split('\n'));
  print('Parsed ${file.path}.');
  print('Service protocol version ${ApiParseUtil.parseVersionString(nodes)}.');

  // Generate code from the model.
  print('');

  await _generateDart(appDirPath, nodes);
  await _generateJava(appDirPath, nodes);
}

Future _generateDart(String appDirPath, List<Node> nodes) async {
  var outDirPath = normalize(join(appDirPath, '..', 'lib/src'));
  var outDir = Directory(outDirPath);
  if (!outDir.existsSync()) outDir.createSync(recursive: true);
  var outputFile = File(join(outDirPath, 'vm_service.dart'));
  var generator = dart.DartGenerator();
  dart.api = dart.Api();
  dart.api.parse(nodes);
  dart.api.generate(generator);
  outputFile.writeAsStringSync(generator.toString());
  ProcessResult result = Process.runSync('dart', ['format', outDirPath]);
  if (result.exitCode != 0) {
    print('dart format: ${result.stdout}\n${result.stderr}');
    throw result.exitCode;
  }

  if (_stampPubspecVersion) {
    // Update the pubspec file.
    Version version = ApiParseUtil.parseVersionSemVer(nodes);
    _stampPubspec(version);

    // Validate that the changelog contains an entry for the current version.
    _checkUpdateChangelog(version);
  }

  print('Wrote Dart to ${outputFile.path}.');
}

Future _generateJava(String appDirPath, List<Node> nodes) async {
  var srcDirPath = normalize(join(appDirPath, '..', 'java', 'src'));
  var generator = java.JavaGenerator(srcDirPath);

  final scriptPath = Platform.script.toFilePath();
  final kSdk = '/sdk/';
  final scriptLocation =
      scriptPath.substring(scriptPath.indexOf(kSdk) + kSdk.length);
  java.api = java.Api(scriptLocation);
  java.api.parse(nodes);
  java.api.generate(generator);

  // We generate files into the java/src/ folder; ensure the generated files
  // aren't committed to git (but manually maintained files in the same
  // directory are).
  List<String> generatedPaths = generator.allWrittenFiles
      .map((path) => relative(path, from: 'java'))
      .toList();
  generatedPaths.sort();
  File gitignoreFile = File(join(appDirPath, '..', 'java', '.gitignore'));
  gitignoreFile.writeAsStringSync('''
# This is a generated file.

${generatedPaths.join('\n')}
''');

  // Generate a version file.
  Version version = ApiParseUtil.parseVersionSemVer(nodes);
  File file = File(join('java', 'version.properties'));
  file.writeAsStringSync('version=${version.major}.${version.minor}\n');

  print('Wrote Java to $srcDirPath.');
}

// Push the major and minor versions into the pubspec.
void _stampPubspec(Version version) {
  final String pattern = 'version: ';
  File file = File('pubspec.yaml');
  String text = file.readAsStringSync();
  bool found = false;

  text = text.split('\n').map((line) {
    if (line.startsWith(pattern)) {
      found = true;
      Version v = Version.parse(line.substring(pattern.length));
      String? pre = v.preRelease.isEmpty ? null : v.preRelease.join('-');
      String? build = v.build.isEmpty ? null : v.build.join('+');
      v = Version(version.major, version.minor, v.patch,
          pre: pre, build: build);
      return '${pattern}${v.toString()}';
    } else {
      return line;
    }
  }).join('\n');

  if (!found) throw '`${pattern}` not found';

  file.writeAsStringSync(text);
}

void _checkUpdateChangelog(Version version) {
  // Look for `## major.minor`.
  String check = '## ${version.major}.${version.minor}';

  File file = File('CHANGELOG.md');
  String text = file.readAsStringSync();
  bool containsReleaseNotes =
      text.split('\n').any((line) => line.startsWith(check));
  if (!containsReleaseNotes) {
    throw '`${check}` not found in the CHANGELOG.md file';
  }
}
