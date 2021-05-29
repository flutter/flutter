// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:math';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;

const String kDocRoot = 'dev/docs/doc';

/// This script downloads an archive of Javadoc and objc doc for the engine from
/// the artifact store and extracts them to the location used for Dartdoc.
Future<void> main(List<String> args) async {
  final String engineVersion = File('bin/internal/engine.version').readAsStringSync().trim();

  final String javadocUrl = 'https://storage.googleapis.com/flutter_infra_release/flutter/$engineVersion/android-javadoc.zip';
  generateDocs(javadocUrl, 'javadoc', 'io/flutter/view/FlutterView.html');

  final String objcdocUrl = 'https://storage.googleapis.com/flutter_infra_release/flutter/$engineVersion/ios-objcdoc.zip';
  generateDocs(objcdocUrl, 'objcdoc', 'Classes/FlutterViewController.html');
}

/// Fetches the zip archive at the specified url.
///
/// Returns null if the archive fails to download after [maxTries] attempts.
Future<Archive> fetchArchive(String url, int maxTries) async {
  List<int> responseBytes;
  for (int i = 0; i < maxTries; i++) {
    final http.Response response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      responseBytes = response.bodyBytes;
      break;
    }
    stderr.writeln('Failed attempt ${i+1} to fetch $url.');

    // On failure print a short snipped from the body in case it's helpful.
    final int bodyLength = min(1024, response.body.length);
    stderr.writeln('Response status code ${response.statusCode}. Body: ' + response.body.substring(0, bodyLength));
    sleep(const Duration(seconds: 1));
  }
  return responseBytes == null ? null : ZipDecoder().decodeBytes(responseBytes);
}

Future<void> generateDocs(String url, String docName, String checkFile) async {
  const int maxTries = 5;
  final Archive archive = await fetchArchive(url, maxTries);
  if (archive == null) {
    stderr.writeln('Failed to fetch zip archive from: $url after $maxTries attempts. Giving up.');
    exit(1);
  }

  final Directory output = Directory('$kDocRoot/$docName');
  print('Extracting $docName to ${output.path}');
  output.createSync(recursive: true);

  for (final ArchiveFile af in archive) {
    if (!af.name.endsWith('/')) {
      final File file = File('${output.path}/${af.name}');
      file.createSync(recursive: true);
      file.writeAsBytesSync(af.content as List<int>);
    }
  }

  final File testFile = File('${output.path}/$checkFile');
  if (!testFile.existsSync()) {
    print('Expected file ${testFile.path} not found');
    exit(1);
  }
  print('$docName ready to go!');
}
