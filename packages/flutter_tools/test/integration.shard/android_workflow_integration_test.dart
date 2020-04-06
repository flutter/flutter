// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:platform/platform.dart';
import 'package:archive/archive.dart';
import 'package:process/process.dart';

import '../src/common.dart';

const String kAndroidRepo = 'https://dl.google.com/android/repository/';

const Map<String, String> kPlatformTools = <String, String>{
  'windows': 'commandlinetools-win-6200805_latest.zip',
  'macos': 'commandlinetools-mac-6200805_latest.zip',
  'linux': 'commandlinetools-linux-6200805_latest.zip',
};

const List<String> kComponents = <String>[
  'platforms;android-29',
  'cmdline-tools;latest',
  'platform-tools', // no latest tag.
  'build-tools;29.0.3', // no latest tag.
];

const ProcessManager processManager = LocalProcessManager();
const Platform platform = LocalPlatform();
const FileSystem fileSystem = LocalFileSystem();

/// Download the latest Android SDK and verify that flutter doctor is clean.
Future<void> main() async {
  Directory workingDirectory;

  test('Android SDK structure is correct in doctor checks', () async {
    workingDirectory = fileSystem.systemTempDirectory
        .createTempSync('flutter_tools_android_workflow_test.')
          ..createSync(recursive: true);

    // Download platform tools.
    final HttpClient client = HttpClient();
    final HttpClientRequest request = await client.getUrl(
        Uri.parse(kAndroidRepo + kPlatformTools[platform.operatingSystem]));
    final HttpClientResponse response = await request.close();

    expect(response.statusCode, HttpStatus.ok);

    final Completer<void> requestCompleted = Completer<void>();
    final BytesBuilder builder = BytesBuilder();
    response.listen(builder.add, onDone: requestCompleted.complete);
    await requestCompleted.future;
    client.close();
    final Uint8List zippedTools = builder.toBytes();

    // Unpack archive
    final Archive archive = ZipDecoder().decodeBytes(zippedTools);
    for (final ArchiveFile archiveFile in archive.files) {
      // The archive package doesn't correctly set isFile.
      if (!archiveFile.isFile || archiveFile.name.endsWith('/')) {
        continue;
      }
      final File destFile = fileSystem.file(fileSystem.path.join(
        workingDirectory.path,
        archiveFile.name,
      ));
      if (!destFile.parent.existsSync()) {
        destFile.parent.createSync(recursive: true);
      }
      destFile.writeAsBytesSync(archiveFile.content as List<int>);
      if (archiveFile.name.contains('sdkmanager')) {
        await makeExecutable(destFile, platform, processManager);
      }
    }

    // Update the local SDK to include platform-tools, cmdline-tools, and 29
    final ProcessResult process = await processManager.run(<String>[
      fileSystem.path.join(workingDirectory.path, 'tools', 'bin', 'sdkmanager'),
      '--sdk_root=${workingDirectory.absolute.path}',
      '--update'
    ]);
    expect(process.exitCode, 0);

    final Process additionalProcess = await processManager.start(<String>[
      fileSystem.path.join(workingDirectory.path, 'tools', 'bin', 'sdkmanager'),
      '--sdk_root=${workingDirectory.absolute.path}',
      ...kComponents,
    ]);
    additionalProcess.stdout.transform(utf8.decoder).listen((String chunk) {
      print(chunk);
      additionalProcess.stdin.writeln('y');
    });
    expect(await additionalProcess.exitCode, 0);

    final ProcessResult doctorResult = await processManager.run(<String>[
      'flutter',
      'doctor',
    ], environment: <String, String>{
      'ANDROID_HOME': workingDirectory.path
    });

    expect(doctorResult.stdout, 'Some Android licenses not accepted');
  }, skip: 'Too slow to run on CI, downloads most of Android SDK');

  tearDown(() {
    workingDirectory?.deleteSync(recursive: true);
  });
}

Future<void> makeExecutable(
    File file, Platform platform, ProcessManager processManager) async {
  if (platform.isLinux || platform.isMacOS) {
    await processManager.run(<String>['chmod', 'a+x', file.path]);
  }
}
