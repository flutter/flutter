// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';

import 'package:flutter_devicelab/framework/manifest.dart';

void main() {
  group('production manifest', () {
    test('must be valid', () {
      Manifest manifest = loadTaskManifest();
      expect(manifest.tasks, isNotEmpty);

      ManifestTask task = manifest.tasks.firstWhere((ManifestTask task) => task.name == 'flutter_gallery__start_up');
      expect(task.description, 'Measures the startup time of the Flutter Gallery app on Android.\n');
      expect(task.stage, 'devicelab');
      expect(task.requiredAgentCapabilities, <String>['has-android-device']);
    });
  });

  group('manifest parser', () {
    void testManifestError(
      String testDescription,
      String errorMessage,
      String yaml,
    ) {
      test(testDescription, () {
        try {
          loadTaskManifest(yaml);
        } on ManifestError catch(error) {
          expect(error.message, errorMessage);
        }
      });
    }

    testManifestError(
      'invalid top-level type',
      'Manifest must be a dictionary but was YamlScalar: null',
      '',
    );

    testManifestError(
      'invalid top-level key',
      'Unrecognized property "bad" in manifest. Allowed properties: tasks',
      '''
      bad:
        key: yes
      ''',
    );

    testManifestError(
      'invalid tasks list type',
      'Value of "tasks" must be a dictionary but was YamlList: [a, b]',
      '''
      tasks:
        - a
        - b
      '''
    );

    testManifestError(
      'invalid task name type',
      'Task name must be a string but was int: 1',
      '''
      tasks:
        1: 2
      '''
    );

    testManifestError(
      'invalid task type',
      'Value of task "foo" must be a dictionary but was int: 2',
      '''
      tasks:
        foo: 2
      '''
    );

    testManifestError(
      'invalid task property',
      'Unrecognized property "bar" in Value of task "foo". Allowed properties: description, stage, required_agent_capabilities',
      '''
      tasks:
        foo:
          bar: 2
      '''
    );

    testManifestError(
      'invalid required_agent_capabilities type',
      'required_agent_capabilities must be a list but was int: 1',
      '''
      tasks:
        foo:
          required_agent_capabilities: 1
      '''
    );

    testManifestError(
      'invalid required_agent_capabilities element type',
      'required_agent_capabilities[0] must be a string but was int: 1',
      '''
      tasks:
        foo:
          required_agent_capabilities: [1]
      '''
    );

    testManifestError(
      'missing description',
      'Task description must not be empty in task "foo".',
      '''
      tasks:
        foo:
          required_agent_capabilities: ["a"]
      '''
    );

    testManifestError(
      'missing stage',
      'Task stage must not be empty in task "foo".',
      '''
      tasks:
        foo:
          description: b
          required_agent_capabilities: ["a"]
      '''
    );

    testManifestError(
      'missing stage',
      'requiredAgentCapabilities must not be empty in task "foo".',
      '''
      tasks:
        foo:
          description: b
          stage: c
          required_agent_capabilities: []
      '''
    );
  });
}
