// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

Future<Map<String, String>> loadChecksums(Directory directory) async {
  final File checksumFile = File(path.join(directory.path, 'checksums.json'));
  if (!checksumFile.existsSync()) {
    return <String, String>{};
  }
  final Map<String, String> result = <String, String>{};
  final Map<String, dynamic> jsonResult =
      json.decode(await checksumFile.readAsString());
  for (final String key in jsonResult.keys) {
    result[key] = jsonResult[key];
  }
  return result;
}

Future<void> writeChecksums(
  Map<String, String> checksums,
  Directory directory,
) async {
  final File checksumFile = File(path.join(directory.path, 'checksums.json'));
  const JsonEncoder encoder = JsonEncoder.withIndent('  ');
  await checksumFile.writeAsString(encoder.convert(checksums));
}
