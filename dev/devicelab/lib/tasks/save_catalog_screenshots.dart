// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart';
import 'package:path/path.dart';

String authorizationToken;

class UploadError extends Error {
  UploadError(this.message);
  final String message;
  @override
  String toString() => 'UploadError($message)';
}

void logMessage(String s) { print(s); }

class Upload {
  Upload(this.fromPath, this.largeName, this.smallName);

  static math.Random random;
  static const String uriAuthority = 'www.googleapis.com';
  static const String uriPath = 'upload/storage/v1/b/flutter-catalog/o';

  final String fromPath;
  final String largeName;
  final String smallName;

  List<int> largeImage;
  List<int> smallImage;
  bool largeImageSaved = false;
  int retryCount = 0;
  bool isComplete = false;

  // Exponential backoff per https://cloud.google.com/storage/docs/exponential-backoff
  Duration get timeLimit {
    if (retryCount == 0)
      return const Duration(milliseconds: 1000);
    random ??= math.Random();
    return Duration(milliseconds: random.nextInt(1000) + math.pow(2, retryCount) * 1000);
  }

  Future<bool> save(HttpClient client, String name, List<int> content) async {
    try {
      final Uri uri = Uri.https(uriAuthority, uriPath, <String, String>{
        'uploadType': 'media',
        'name': name,
      });
      final HttpClientRequest request = await client.postUrl(uri);
      request
        ..headers.contentType = ContentType('image', 'png')
        ..headers.add('Authorization', 'Bearer $authorizationToken')
        ..add(content);

      final HttpClientResponse response = await request.close().timeout(timeLimit);
      if (response.statusCode == HttpStatus.ok) {
        logMessage('Saved $name');
        await response.drain<void>();
      } else {
        // TODO(hansmuller): only retry on 5xx and 429 responses
        logMessage('Request to save "$name" (length ${content.length}) failed with status ${response.statusCode}, will retry');
        logMessage(await response.transform<String>(utf8.decoder).join());
      }
      return response.statusCode == HttpStatus.ok;
    } on TimeoutException catch (_) {
      logMessage('Request to save "$name" (length ${content.length}) timed out, will retry');
      return false;
    }
  }

  Future<bool> run(HttpClient client) async {
    assert(!isComplete);
    if (retryCount > 2)
      throw UploadError('upload of "$fromPath" to "$largeName" and "$smallName" failed after 2 retries');

    largeImage ??= await File(fromPath).readAsBytes();
    smallImage ??= encodePng(copyResize(decodePng(largeImage), 300));

    if (!largeImageSaved)
      largeImageSaved = await save(client, largeName, largeImage);
    isComplete = largeImageSaved && await save(client, smallName, smallImage);

    retryCount += 1;
    return isComplete;
  }

  static bool isNotComplete(Upload upload) => !upload.isComplete;
}

Future<void> saveScreenshots(List<String> fromPaths, List<String> largeNames, List<String> smallNames) async {
  assert(fromPaths.length == largeNames.length);
  assert(fromPaths.length == smallNames.length);

  List<Upload> uploads = List<Upload>(fromPaths.length);
  for (int index = 0; index < uploads.length; index += 1)
    uploads[index] = Upload(fromPaths[index], largeNames[index], smallNames[index]);

  while (uploads.any(Upload.isNotComplete)) {
    final HttpClient client = HttpClient();
    uploads = uploads.where(Upload.isNotComplete).toList();
    await Future.wait<bool>(uploads.map<Future<bool>>((Upload upload) => upload.run(client)));
    client.close(force: true);
  }
}


// If path is lib/foo.png then screenshotName is foo.
String screenshotName(String path) => basenameWithoutExtension(path);

Future<void> saveCatalogScreenshots({
    Directory directory, // Where the *.png screenshots are.
    String commit, // The commit hash to be used as a cloud storage "directory".
    String token, // Cloud storage authorization token.
    String prefix, // Prefix for all file names.
  }) async {
  final List<String> screenshots = <String>[];
  for (FileSystemEntity entity in directory.listSync()) {
    if (entity is File && entity.path.endsWith('.png')) {
      final File file = entity;
      screenshots.add(file.path);
    }
  }

  final List<String> largeNames = <String>[]; // Cloud storage names for the full res screenshots.
  final List<String> smallNames = <String>[]; // Likewise for the scaled down screenshots.
  for (String path in screenshots) {
    final String name = screenshotName(path);
    largeNames.add('$commit/$prefix$name.png');
    smallNames.add('$commit/$prefix${name}_small.png');
  }

  authorizationToken = token;
  await saveScreenshots(screenshots, largeNames, smallNames);
}
