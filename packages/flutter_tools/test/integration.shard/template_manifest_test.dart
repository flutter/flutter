// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io'; // ignore: dart_io_import

import 'package:path/path.dart' as path; // ignore: package_path_import
import 'package:flutter_tools/src/convert.dart';
import '../src/common.dart';

/// Checks that all active template files are defined in the template_manifest.json file.
void main() {
  test('Check template manifest is up to date', () {
    final Map<String, Object> manifest = json.decode(
      File('templates/template_manifest.json').readAsStringSync(),
    ) as Map<String, Object>;
    final Set<Uri> declaredFileList = Set<Uri>.from(
      (manifest['files'] as List<Object>).cast<String>().map<Uri>(path.toUri));

    final Set<Uri> activeTemplateList = Directory('templates')
      .listSync(recursive: true)
      .whereType<File>()
      .where((File file) => path.basename(file.path) != 'template_manifest.json' &&
        path.basename(file.path) != '.DS_Store')
      .map((File file) => file.uri)
      .toSet();

    final Set<Uri> difference = activeTemplateList.difference(declaredFileList);

    expect(difference, isEmpty, reason: 'manifest and template directory should be in-sync');
  });
}
