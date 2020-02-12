// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

import 'package:snippets/configuration.dart';

void main() {
  group('Configuration', () {
    Configuration config;

    setUp(() {
      config = Configuration(flutterRoot: Directory('/flutter sdk'));
    });
    test('config directory is correct', () async {
      expect(config.configDirectory.path,
          matches(RegExp(r'[/\\]flutter sdk[/\\]dev[/\\]snippets[/\\]config')));
    });
    test('output directory is correct', () async {
      expect(config.outputDirectory.path,
          matches(RegExp(r'[/\\]flutter sdk[/\\]dev[/\\]docs[/\\]doc[/\\]snippets')));
    });
    test('skeleton directory is correct', () async {
      expect(config.skeletonsDirectory.path,
          matches(RegExp(r'[/\\]flutter sdk[/\\]dev[/\\]snippets[/\\]config[/\\]skeletons')));
    });
    test('templates directory is correct', () async {
      expect(config.templatesDirectory.path,
          matches(RegExp(r'[/\\]flutter sdk[/\\]dev[/\\]snippets[/\\]config[/\\]templates')));
    });
    test('html skeleton file for sample is correct', () async {
      expect(
          config.getHtmlSkeletonFile(SnippetType.snippet).path,
          matches(RegExp(
              r'[/\\]flutter sdk[/\\]dev[/\\]snippets[/\\]config[/\\]skeletons[/\\]snippet.html')));
    });
    test('html skeleton file for app with no dartpad is correct', () async {
      expect(
          config.getHtmlSkeletonFile(SnippetType.sample).path,
          matches(RegExp(
              r'[/\\]flutter sdk[/\\]dev[/\\]snippets[/\\]config[/\\]skeletons[/\\]sample.html')));
    });
    test('html skeleton file for app with dartpad is correct', () async {
      expect(
          config.getHtmlSkeletonFile(SnippetType.sample, showDartPad: true).path,
          matches(RegExp(
              r'[/\\]flutter sdk[/\\]dev[/\\]snippets[/\\]config[/\\]skeletons[/\\]dartpad-sample.html')));
    });
  });
}
