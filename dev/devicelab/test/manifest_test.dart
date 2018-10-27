// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_devicelab/framework/manifest.dart';

import 'common.dart';

void main() {
  group('production manifest', () {
    test('must be valid', () {
      final Manifest manifest = loadTaskManifest();
      expect(manifest.tasks, isNotEmpty);

      final ManifestTask task = manifest.tasks.firstWhere((ManifestTask task) => task.name == 'flutter_gallery__start_up');
      expect(task.description, 'Measures the startup time of the Flutter Gallery app on Android.\n');
      expect(task.stage, 'devicelab');
      expect(task.requiredAgentCapabilities, <String>['linux/android']);

      for (ManifestTask task in manifest.tasks) {
        final File taskFile = File('bin/tasks/${task.name}.dart');
        expect(taskFile.existsSync(), true,
          reason: 'File ${taskFile.path} corresponding to manifest task "${task.name}" not found');
      }
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
        } on ManifestError catch (error) {
          expect(error.message, errorMessage);
        }
      });
    }

    test('accepts task with minimum amount of configuration', () {
      final Manifest manifest = loadTaskManifest('''
tasks:
  minimum_configuration_task:
    description: Description is mandatory.
    stage: stage_is_mandatory_too
    required_agent_capabilities: ["so-is-capability"]
''');

      expect(manifest.tasks.single.description, 'Description is mandatory.');
      expect(manifest.tasks.single.stage, 'stage_is_mandatory_too');
      expect(manifest.tasks.single.requiredAgentCapabilities, <String>['so-is-capability']);
      expect(manifest.tasks.single.isFlaky, false);
      expect(manifest.tasks.single.timeoutInMinutes, null);
    });

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
      'Unrecognized property "bar" in Value of task "foo". Allowed properties: description, stage, required_agent_capabilities, flaky, timeout_in_minutes',
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
      'missing required_agent_capabilities',
      'requiredAgentCapabilities must not be empty in task "foo".',
      '''
      tasks:
        foo:
          description: b
          stage: c
          required_agent_capabilities: []
      '''
    );

    testManifestError(
      'bad flaky type',
      'flaky must be a boolean but was String: not-a-boolean',
      '''
      tasks:
        foo:
          description: b
          stage: c
          required_agent_capabilities: ["a"]
          flaky: not-a-boolean
      '''
    );

    test('accepts boolean flaky option', () {
      final Manifest manifest = loadTaskManifest('''
tasks:
  flaky_task:
    description: d
    stage: s
    required_agent_capabilities: ["c"]
    flaky: true
''');

      expect(manifest.tasks.single.name, 'flaky_task');
      expect(manifest.tasks.single.isFlaky, isTrue);
    });

    test('accepts custom timeout_in_minutes option', () {
      final Manifest manifest = loadTaskManifest('''
tasks:
  task_with_custom_timeout:
    description: d
    stage: s
    required_agent_capabilities: ["c"]
    timeout_in_minutes: 120
''');

      expect(manifest.tasks.single.timeoutInMinutes, 120);
    });
  });
}
