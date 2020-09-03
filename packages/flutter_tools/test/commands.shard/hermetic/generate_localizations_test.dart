// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/commands/generate_localizations.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  testUsingContext('call GenerateLocalizations with default l10n settings', () async {
    // Project directory setup for gen_l10n logic
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    final File arbFile = fileSystem.file(fileSystem.path.join('lib', 'l10n', 'app_en.arb'))
      ..createSync(recursive: true);
    arbFile.writeAsStringSync('''{
  "helloWorld": "Hello, World!",
  "@helloWorld": {
    "description": "Sample description"
  }
}''');
    fileSystem.file('l10n.yaml').createSync();
    fileSystem.file('pubspec.yaml').writeAsStringSync('flutter:\n  generate: true\n');
    // Create an l10n.yaml file
    fileSystem.file('l10n.yaml').createSync();
    // Add generate:true to pubspec.yaml.
    final File pubspecFile = fileSystem.file('pubspec.yaml')..createSync();
    final String content = pubspecFile.readAsStringSync().replaceFirst(
      '\nflutter:\n',
      '\nflutter:\n  generate: true\n',
    );
    pubspecFile.writeAsStringSync(content);

    final GenerateLocalizationsCommand command = GenerateLocalizationsCommand(
      fileSystem: fileSystem,
    );
    await createTestCommandRunner(command).run(<String>['gen-l10n']);

    final FlutterCommandResult result = await command.runCommand();
    expect(result.exitStatus, ExitStatus.success);
    final Directory outputDirectory = fileSystem.directory(fileSystem.path.join('.dart_tool', 'flutter_gen', 'gen_l10n'));
    expect(outputDirectory.existsSync(), true);
    expect(outputDirectory.childFile('app_localizations_en.dart').existsSync(), true);
    expect(outputDirectory.childFile('app_localizations.dart').existsSync(), true);
  });

  // TODO(shihaohong): Test core iterations of every parameter.
}
