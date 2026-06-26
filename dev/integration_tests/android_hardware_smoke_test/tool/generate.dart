// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_print

import 'dart:io';

void main() async {
  final Uri scriptUri = Platform.script;
  final Directory scriptDir = Directory.fromUri(scriptUri).parent;
  final Directory projectDir = scriptDir.parent;

  print('Generating Pigeon files in ${projectDir.path}...');

  final ProcessResult result = await Process.run(
    'flutter',
    <String>['pub', 'run', 'pigeon', '--input', 'pigeons/messages.dart'],
    workingDirectory: projectDir.path,
    runInShell: true,
  );

  if (result.exitCode != 0) {
    stderr.writeln('Pigeon generation failed:');
    stderr.writeln(result.stderr);
    exit(result.exitCode);
  }

  print(result.stdout);

  final generatedKotlinFile = File(
    '${projectDir.path}/android/app/src/main/kotlin/com/example/android_hardware_smoke_test/Messages.g.kt',
  );

  if (generatedKotlinFile.existsSync()) {
    final String content = generatedKotlinFile.readAsStringSync();
    if (content.contains('@file:Suppress("UNCHECKED_CAST", "ArrayInDataClass")')) {
      print('Prepending package name suppression to generated Kotlin file...');
      final String modified = content.replaceFirst(
        '@file:Suppress("UNCHECKED_CAST", "ArrayInDataClass")',
        '@file:Suppress("UNCHECKED_CAST", "ArrayInDataClass", "PackageName")',
      );
      generatedKotlinFile.writeAsStringSync(modified);
    }
  }

  print('Generation complete!');
}
