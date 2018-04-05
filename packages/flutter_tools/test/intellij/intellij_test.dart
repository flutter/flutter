// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/intellij/intellij.dart';
import 'package:test/test.dart';

import '../src/context.dart';

void main() {
  group('IntelliJ', () {
    group('plugins', () {
      testUsingContext('found', () async {
        final String pluginsPath =
            fs.path.join('test', 'data', 'intellij', 'plugins');
        final IntelliJPlugins plugins = new IntelliJPlugins(pluginsPath);

        final List<ValidationMessage> messages = <ValidationMessage>[];
        plugins.validatePackage(messages,
            <String>['flutter-intellij', 'flutter-intellij.jar'], 'Flutter',
            minVersion: IntelliJPlugins.kMinFlutterPluginVersion);
        plugins.validatePackage(messages, <String>['Dart'], 'Dart');

        ValidationMessage message = messages
            .firstWhere((ValidationMessage m) => m.message.startsWith('Dart '));
        expect(message.message, 'Dart plugin version 162.2485');

        message = messages.firstWhere(
            (ValidationMessage m) => m.message.startsWith('Flutter '));
        expect(message.message, contains('Flutter plugin version 0.1.3'));
        expect(message.message, contains('recommended minimum version'));
      });

      testUsingContext('not found', () async {
        final String pluginsPath =
            fs.path.join('test', 'data', 'intellij', 'no_plugins');
        final IntelliJPlugins plugins = new IntelliJPlugins(pluginsPath);

        final List<ValidationMessage> messages = <ValidationMessage>[];
        plugins.validatePackage(messages,
            <String>['flutter-intellij', 'flutter-intellij.jar'], 'Flutter',
            minVersion: IntelliJPlugins.kMinFlutterPluginVersion);
        plugins.validatePackage(messages, <String>['Dart'], 'Dart');

        ValidationMessage message = messages
            .firstWhere((ValidationMessage m) => m.message.startsWith('Dart '));
        expect(message.message, contains('Dart plugin not installed'));

        message = messages.firstWhere(
            (ValidationMessage m) => m.message.startsWith('Flutter '));
        expect(message.message, contains('Flutter plugin not installed'));
      });
    });
  });
}
