// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:path/path.dart' as pathlib;

final Environment environment = Environment();

void main() async {
  if (io.Directory.current.absolute.path != environment.webUiRootDir.absolute.path) {
    io.stderr.writeln('Current directory is not the root of the web_ui package directory.');
    io.stderr.writeln('web_ui directory is: ${environment.webUiRootDir.absolute.path}');
    io.stderr.writeln('current directory is: ${io.Directory.current.absolute.path}');
    io.exit(1);
  }

  await _checkLicenseHeaders();
  await _runTests();
}

void _checkLicenseHeaders() {
  final List<io.File> allSourceFiles = _flatListSourceFiles(environment.webUiRootDir);
  _expect(allSourceFiles.isNotEmpty, 'Dart source listing of ${environment.webUiRootDir.path} must not be empty.');

  final List<String> allDartPaths = allSourceFiles.map((f) => f.path).toList();
  print(allDartPaths.join('\n'));

  for (String expectedDirectory in const <String>['lib', 'test', 'dev', 'tool']) {
    final String expectedAbsoluteDirectory = pathlib.join(environment.webUiRootDir.path, expectedDirectory);
    _expect(
      allDartPaths.where((p) => p.startsWith(expectedAbsoluteDirectory)).isNotEmpty,
      'Must include the $expectedDirectory/ directory',
    );
  }

  allSourceFiles.forEach(_expectLicenseHeader);
}

final _copyRegex = RegExp(r'// Copyright 2013 The Flutter Authors\. All rights reserved\.');

void _expectLicenseHeader(io.File file) {
  List<String> head = file.readAsStringSync().split('\n').take(3).toList();

  _expect(head.length >= 3, 'File too short: ${file.path}');
  _expect(
    _copyRegex.firstMatch(head[0]) != null,
    'Invalid first line of license header in file ${file.path}',
  );
  _expect(
    head[1] == '// Use of this source code is governed by a BSD-style license that can be',
    'Invalid second line of license header in file ${file.path}',
  );
  _expect(
    head[2] == '// found in the LICENSE file.',
    'Invalid second line of license header in file ${file.path}',
  );
}

void _expect(bool value, String requirement) {
  if (!value) {
    throw Exception('Test failed: ${requirement}');
  }
}

List<io.File> _flatListSourceFiles(io.Directory directory) {
  return directory
      .listSync(recursive: true)
      .whereType<io.File>()
      .where((f) => f.path.endsWith('.dart') || f.path.endsWith('.js'))
      .toList();
}

Future<void> _runTests() async {
  _copyAhemFontIntoWebUi();

  final List<String> testFiles = io.Directory('test')
    .listSync(recursive: true)
    .whereType<io.File>()
    .map<String>((io.File file) => file.path)
    .where((String path) => path.endsWith('_test.dart'))
    .toList();

  final io.Process pubRunTest = await io.Process.start(
    environment.pubExecutable,
    <String>[
      'run',
      'test',
      '--preset=cirrus',
      '--platform=chrome',
      ...testFiles,
    ],
  );

  final StreamSubscription stdoutSub = pubRunTest.stdout.listen(io.stdout.add);
  final StreamSubscription stderrSub = pubRunTest.stderr.listen(io.stderr.add);
  final int exitCode = await pubRunTest.exitCode;
  stdoutSub.cancel();
  stderrSub.cancel();

  if (exitCode != 0) {
    io.stderr.writeln('Test process exited with exit code $exitCode');
    io.exit(1);
  }
}

void _copyAhemFontIntoWebUi() {
  final io.File sourceAhemTtf = io.File(pathlib.join(environment.flutterDirectory.path, 'third_party', 'txt', 'third_party', 'fonts', 'ahem.ttf'));
  final String destinationAhemTtfPath = pathlib.join(environment.webUiRootDir.path, 'lib', 'assets', 'ahem.ttf');
  sourceAhemTtf.copySync(destinationAhemTtfPath);
}

class Environment {
  factory Environment() {
    final io.File self = io.File.fromUri(io.Platform.script);
    final io.Directory webUiRootDir = self.parent.parent;
    final io.Directory engineSrcDir = webUiRootDir.parent.parent.parent;
    final io.Directory outDir = io.Directory(pathlib.join(engineSrcDir.path, 'out'));
    final io.Directory hostDebugUnoptDir = io.Directory(pathlib.join(outDir.path, 'host_debug_unopt'));
    final String dartExecutable = pathlib.canonicalize(io.File(_which(io.Platform.executable)).absolute.path);
    final io.Directory dartSdkDir = io.File(dartExecutable).parent.parent;

    // Googlers frequently have their Dart SDK misconfigured for open-source projects. Let's help them out.
    if (dartExecutable.startsWith('/usr/lib/google-dartlang')) {
      io.stderr.writeln('ERROR: Using unsupported version of the Dart SDK: $dartExecutable');
      io.exit(1);
    }

    return Environment._(
      self: self,
      webUiRootDir: webUiRootDir,
      engineSrcDir: engineSrcDir,
      outDir: outDir,
      hostDebugUnoptDir: hostDebugUnoptDir,
      dartExecutable: dartExecutable,
      dartSdkDir: dartSdkDir,
    );
  }

  Environment._({
    this.self,
    this.webUiRootDir,
    this.engineSrcDir,
    this.outDir,
    this.hostDebugUnoptDir,
    this.dartSdkDir,
    this.dartExecutable,
  });

  final io.File self;
  final io.Directory webUiRootDir;
  final io.Directory engineSrcDir;
  final io.Directory outDir;
  final io.Directory hostDebugUnoptDir;
  final io.Directory dartSdkDir;
  final String dartExecutable;

  String get pubExecutable => pathlib.join(dartSdkDir.path, 'bin', 'pub');
  io.Directory get flutterDirectory => io.Directory(pathlib.join(engineSrcDir.path, 'flutter'));

  @override
  String toString() {
    return '''
runTest.dart script:
  ${self.path}
web_ui directory:
  ${webUiRootDir.path}
engine/src directory:
  ${engineSrcDir.path}
out directory:
  ${outDir.path}
out/host_debug_unopt directory:
  ${hostDebugUnoptDir.path}
Dart SDK directory:
  ${dartSdkDir.path}
dart executable:
  ${dartExecutable}
''';
  }
}

String _which(String executable) {
  final io.ProcessResult result = io.Process.runSync('which', <String>[executable]);
  if (result.exitCode != 0) {
    io.stderr.writeln(result.stderr);
    io.exit(result.exitCode);
  }
  return result.stdout;
}
