// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math';
import 'package:file/file.dart';

/// Performs a transactional update of a file in Google Cloud Storage.
///
/// It downloads the file, calls the [callback] to get the new contents, and
/// uploads the new contents. It uses generation IDs to ensure that the file
/// has not been modified between download and upload.
///
/// If the file is modified concurrently, it retries the operation up to
/// [maxRetries] times.
Future<void> transactionalUpdate({
  required String gsPath,
  required Future<String> Function(String currentContents) callback,
  required Future<String> Function(List<String> args) runGsUtil,
  required FileSystem fs,
  int maxRetries = 5,
  Directory? tempDirectory,
  bool dryRun = false,
}) async {
  if (dryRun) {
    print('Dry run: simulating update for $gsPath');
    final String newContents = await callback('');
    print('Resulting manifest content:\n$newContents');
    return;
  }

  final createTemp = tempDirectory == null;
  final Directory tempDir =
      tempDirectory ?? fs.systemTempDirectory.createTempSync('transactional_update.');

  try {
    await _transactionalUpdate(
      gsPath: gsPath,
      callback: callback,
      runGsUtil: runGsUtil,
      fs: fs,
      maxRetries: maxRetries,
      tempDir: tempDir,
    );
  } finally {
    if (createTemp) {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (e) {
        print('Failed to delete temp directory ${tempDir.path}: $e');
      }
    }
  }
}

Future<void> _transactionalUpdate({
  required String gsPath,
  required Future<String> Function(String currentContents) callback,
  required Future<String> Function(List<String> args) runGsUtil,
  required FileSystem fs,
  required int maxRetries,
  required Directory tempDir,
}) async {
  final generationRegex = RegExp(r'Generation:\s+(\d+)');

  for (var attempt = 1; attempt <= maxRetries; attempt++) {
    print('Attempt $attempt of $maxRetries to update $gsPath');

    var generation = '0';
    var fileExists = true;

    try {
      final String statOutput = await runGsUtil(<String>['stat', gsPath]);
      final Match? match = generationRegex.firstMatch(statOutput);
      if (match == null) {
        throw Exception('Could not find generation ID in stat output:\n$statOutput');
      }
      generation = match.group(1)!;
    } catch (e) {
      print('Failed to stat $gsPath, assuming file does not exist: $e');
      fileExists = false;
      generation = '0';
    }

    final File localFile = fs.file(fs.path.join(tempDir.path, 'downloaded.json'));
    var contents = '';

    if (fileExists) {
      try {
        await runGsUtil(<String>['cp', '$gsPath#$generation', localFile.path]);
        contents = localFile.readAsStringSync();
      } catch (e) {
        print('Failed to download generation $generation of $gsPath: $e');
        if (attempt == maxRetries) {
          rethrow;
        }
        final int backoffMs = pow(2, attempt).toInt() * 1000;
        final int jitterMs = Random().nextInt(1000);
        await Future<void>.delayed(Duration(milliseconds: backoffMs + jitterMs));
        continue;
      }
    }

    final String newContents = await callback(contents);

    final File uploadFile = fs.file(fs.path.join(tempDir.path, 'upload.json'));
    uploadFile.writeAsStringSync(newContents);

    try {
      await runGsUtil(<String>[
        '-h',
        'x-goog-if-generation-match:$generation',
        'cp',
        uploadFile.path,
        gsPath,
      ]);
      print('Successfully updated $gsPath');
      return;
    } catch (e) {
      print('Failed to upload $gsPath with generation match $generation: $e');
      if (attempt == maxRetries) {
        rethrow;
      }
      final int backoffMs = pow(2, attempt).toInt() * 1000;
      final int jitterMs = Random().nextInt(1000);
      await Future<void>.delayed(Duration(milliseconds: backoffMs + jitterMs));
      continue;
    }
  }
  throw Exception('Failed to update $gsPath after $maxRetries attempts');
}
