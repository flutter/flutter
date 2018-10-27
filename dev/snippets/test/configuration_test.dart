// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:platform/platform.dart' show FakePlatform;

import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

import 'package:snippets/configuration.dart';

void main() {
  group('Configuration', () {
    FakePlatform fakePlatform;
    Configuration config;

    setUp(() {
      fakePlatform = FakePlatform(
          operatingSystem: 'linux',
          script: Uri.parse('file:///flutter/dev/snippets/lib/configuration_test.dart'));
      config = Configuration(platform: fakePlatform);
    });
    test('config directory is correct', () async {
      expect(config.getConfigDirectory('foo').path,
          matches(RegExp(r'[/\\]flutter[/\\]dev[/\\]snippets[/\\]config[/\\]foo')));
    });
    test('output directory is correct', () async {
      expect(config.outputDirectory.path,
          matches(RegExp(r'[/\\]flutter[/\\]dev[/\\]docs[/\\]doc[/\\]snippets')));
    });
    test('skeleton directory is correct', () async {
      expect(config.skeletonsDirectory.path,
          matches(RegExp(r'[/\\]flutter[/\\]dev[/\\]snippets[/\\]config[/\\]skeletons')));
    });
    test('templates directory is correct', () async {
      expect(config.templatesDirectory.path,
          matches(RegExp(r'[/\\]flutter[/\\]dev[/\\]snippets[/\\]config[/\\]templates')));
    });
    test('html skeleton file is correct', () async {
      expect(
          config.getHtmlSkeletonFile(SnippetType.application).path,
          matches(RegExp(
              r'[/\\]flutter[/\\]dev[/\\]snippets[/\\]config[/\\]skeletons[/\\]application.html')));
    });
  });
}
