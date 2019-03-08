// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

// TODO(dnfield): if/when a streaming unzip routine is available for Dart, use that instead.

Future<void> unzipFile(String file, Directory outDir) async {
  await outDir.parent.create(recursive: true);
  final Directory tempDir = await outDir.parent.createTemp();

  String command;
  List<String> args;
  if (Platform.isWindows) {
    command = 'powershell.exe  -nologo -noprofile -command '
        '"& { '
        'Add-Type -A \'System.IO.Compression.FileSystem\'; '
        '[IO.Compression.ZipFile]::ExtractToDirectory(\'$file\', \'${tempDir.path}\'); '
        '}"';
    args = <String>[];
  } else {
    command = 'unzip';
    args = <String>[
      file,
      '-d',
      tempDir.path,
    ];
  }
  final ProcessResult result = await Process.run(command, args);
  if (result.exitCode != 0) {
    throw Exception('Failed to unzip archive!');
  }
  final Directory dir = await tempDir.list().first;
  if (await outDir.exists()) {
    await outDir.delete(recursive: true);
  }
  await dir.rename(outDir.path);
  await tempDir.delete();
}
