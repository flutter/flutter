// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
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

  final generationRegex = RegExp(r'Generation:\s+(\d+)');

  for (var attempt = 1; attempt <= maxRetries; attempt++) {
    print('Attempt $attempt of $maxRetries to update $gsPath');

    // 1. Get the current generation ID.
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

    final shouldDeleteTemp = tempDirectory == null;
    final Directory tempDir =
        tempDirectory ?? fs.systemTempDirectory.createTempSync('transactional_update.');
    final File localFile = fs.file(fs.path.join(tempDir.path, 'downloaded.json'));

    var contents = '';

    if (fileExists) {
      // 2. Download that specific version.
      try {
        await runGsUtil(<String>['cp', '$gsPath#$generation', localFile.path]);
        contents = localFile.readAsStringSync();
      } catch (e) {
        print('Failed to download generation $generation of $gsPath: $e');
        if (shouldDeleteTemp) {
          tempDir.deleteSync(recursive: true);
        }
        if (attempt == maxRetries) {
          rethrow;
        }
        await Future<void>.delayed(const Duration(seconds: 1));
        continue;
      }
    }

    // 3. Call callback.
    final String newContents = await callback(contents);

    // 4. Write new contents to a file for upload.
    final File uploadFile = fs.file(fs.path.join(tempDir.path, 'upload.json'));
    uploadFile.writeAsStringSync(newContents);

    // 5. Upload with generation match.
    try {
      await runGsUtil(<String>[
        '-h',
        'x-goog-if-generation-match:$generation',
        'cp',
        uploadFile.path,
        gsPath,
      ]);
      print('Successfully updated $gsPath');
      if (shouldDeleteTemp) {
        tempDir.deleteSync(recursive: true);
      }
      return;
    } catch (e) {
      print('Failed to upload $gsPath with generation match $generation: $e');
      if (shouldDeleteTemp) {
        tempDir.deleteSync(recursive: true);
      }
      if (attempt == maxRetries) {
        rethrow;
      }
      await Future<void>.delayed(const Duration(seconds: 1));
      continue;
    }
  }
  throw Exception('Failed to update $gsPath after $maxRetries attempts');
}
