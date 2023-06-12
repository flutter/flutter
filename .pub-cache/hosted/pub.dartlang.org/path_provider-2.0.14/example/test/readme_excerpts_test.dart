// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_example/readme_excerpts.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    PathProviderPlatform.instance = FakePathProvider();
  });

  test('sanity check readmeSnippets', () async {
    // Ensure that the snippet code runs successfully.
    final List<Directory?> results = await readmeSnippets();
    // It should demonstrate a couple of calls.
    expect(results.length, greaterThan(2));
    // And the calls should all be different.
    expect(results.toSet().length, results.length);
  });
}

class FakePathProvider extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return 'docs';
  }

  @override
  Future<String?> getDownloadsPath() async {
    return 'downloads';
  }

  @override
  Future<String?> getTemporaryPath() async {
    return 'temp';
  }
}
