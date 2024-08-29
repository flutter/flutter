// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';

import 'utils.dart';

void main() async {
  final List<CannedProcess> cannedProcesses = <CannedProcess>[
    CannedProcess((List<String> command) => command.contains('ulfuls'),
        stdout: 'Ashita ga aru sa'),
    CannedProcess((List<String> command) => command.contains('quruli'),
        stdout: 'Tokyo'),
    CannedProcess((List<String> command) => command.contains('elizaveta'),
        stdout: 'Moshimo ano toki'),
    CannedProcess((List<String> command) => command.contains('scott_murphy'),
        stdout: 'Donna toki mo'),
  ];

  test('containsCommand passes if command matched', () async {
    final TestEnvironment testEnvironment = TestEnvironment.withTestEngine(
      cannedProcesses: cannedProcesses,
    );
    try {
      await testEnvironment.environment.processRunner.runProcess(
          <String>['ulfuls', '--lyrics'],
          workingDirectory: testEnvironment.environment.engine.srcDir,
          failOk: true);
      await testEnvironment.environment.processRunner.runProcess(
          <String>['quruli', '--lyrics'],
          workingDirectory: testEnvironment.environment.engine.srcDir,
          failOk: true);
      final List<ExecutedProcess> history = testEnvironment.processHistory;
      expect(history, containsCommand((List<String> command) {
        return command.isNotEmpty && command[0] == 'quruli';
      }));
      expect(history, containsCommand((List<String> command) {
        return command.length > 1 && command[1] == '--lyrics';
      }));
    } finally {
      testEnvironment.cleanup();
    }
  });

  test('doesNotContainCommand passes if command not matched', () async {
    final TestEnvironment testEnvironment = TestEnvironment.withTestEngine(
      cannedProcesses: cannedProcesses,
    );
    try {
      await testEnvironment.environment.processRunner.runProcess(
          <String>['elizaveta', '--lyrics'],
          workingDirectory: testEnvironment.environment.engine.srcDir,
          failOk: true);
      await testEnvironment.environment.processRunner.runProcess(
          <String>['scott_murphy', '--lyrics'],
          workingDirectory: testEnvironment.environment.engine.srcDir,
          failOk: true);
      final List<ExecutedProcess> history = testEnvironment.processHistory;
      expect(history, doesNotContainCommand((List<String> command) {
        return command.length > 1 && command[1] == '--not-an-option';
      }));
    } finally {
      testEnvironment.cleanup();
    }
  });
}
