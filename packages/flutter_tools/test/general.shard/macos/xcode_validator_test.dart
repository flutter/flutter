// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/base/version.dart';
import 'package:flutter_tools/src/doctor_validator.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:flutter_tools/src/macos/xcode_validator.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';

void main() {
  group('Xcode validation', () {
    testWithoutContext('Emits missing status when Xcode is not installed', () async {
      final ProcessManager processManager = FakeProcessManager.any();
      final Xcode xcode = Xcode.test(
        processManager: processManager,
        xcodeProjectInterpreter: XcodeProjectInterpreter.test(processManager: processManager, version: null),
      );
      final XcodeValidator validator = XcodeValidator(xcode: xcode, userMessages: UserMessages());
      final ValidationResult result = await validator.validate();
      expect(result.type, ValidationType.missing);
      expect(result.statusInfo, isNull);
      expect(result.messages.last.type, ValidationMessageType.error);
      expect(result.messages.last.message, contains('Xcode not installed'));
    });

    testWithoutContext('Emits missing status when Xcode installation is incomplete', () async {
      final ProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>['/usr/bin/xcode-select', '--print-path'],
          stdout: '/Library/Developer/CommandLineTools',
        ),
      ]);
      final Xcode xcode = Xcode.test(
      processManager: processManager,
        xcodeProjectInterpreter: XcodeProjectInterpreter.test(processManager: processManager, version: null),
      );
      final XcodeValidator validator = XcodeValidator(xcode: xcode, userMessages: UserMessages());
      final ValidationResult result = await validator.validate();
      expect(result.type, ValidationType.missing);
      expect(result.messages.last.type, ValidationMessageType.error);
      expect(result.messages.last.message, contains('Xcode installation is incomplete'));
    });

    testWithoutContext('Emits partial status when Xcode version too low', () async {
      final ProcessManager processManager = FakeProcessManager.any();
      final Xcode xcode = Xcode.test(
        processManager: processManager,
        xcodeProjectInterpreter: XcodeProjectInterpreter.test(processManager: processManager, version: Version(7, 0, 1)),
      );
      final XcodeValidator validator = XcodeValidator(xcode: xcode, userMessages: UserMessages());
      final ValidationResult result = await validator.validate();
      expect(result.type, ValidationType.partial);
      expect(result.messages.last.type, ValidationMessageType.error);
      expect(result.messages.last.message, contains('Flutter requires Xcode 13 or higher'));
    });

    testWithoutContext('Emits partial status when Xcode below recommended version', () async {
      final ProcessManager processManager = FakeProcessManager.any();
      final Xcode xcode = Xcode.test(
        processManager: processManager,
        xcodeProjectInterpreter: XcodeProjectInterpreter.test(processManager: processManager, version: Version(12, 4, null)),
      );
      final XcodeValidator validator = XcodeValidator(xcode: xcode, userMessages: UserMessages());
      final ValidationResult result = await validator.validate();
      expect(result.type, ValidationType.partial);
      expect(result.messages.last.type, ValidationMessageType.hint);
      expect(result.messages.last.message, contains('Flutter recommends a minimum Xcode version of 13'));
    }, skip: true); // [intended] Unskip and update when minimum and required check versions diverge.

    testWithoutContext('Emits partial status when Xcode EULA not signed', () async {
      final ProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>['/usr/bin/xcode-select', '--print-path'],
          stdout: '/Library/Developer/CommandLineTools',
        ),
        const FakeCommand(
          command: <String>[
            'which',
            'sysctl',
          ],
        ),
        const FakeCommand(
          command: <String>[
            'sysctl',
            'hw.optional.arm64',
          ],
          exitCode: 1,
        ),
        const FakeCommand(
          command: <String>['xcrun', 'clang'],
          exitCode: 1,
          stderr:
          'Xcode EULA has not been accepted.\nLaunch Xcode and accept the license.',
        ),
        const FakeCommand(
          command: <String>['xcrun', 'simctl', 'list'],
        ),
      ]);
      final Xcode xcode = Xcode.test(
        processManager: processManager,
        xcodeProjectInterpreter: XcodeProjectInterpreter.test(processManager: processManager),
      );
      final XcodeValidator validator = XcodeValidator(xcode: xcode, userMessages: UserMessages());
      final ValidationResult result = await validator.validate();
      expect(result.type, ValidationType.partial);
      expect(result.messages.last.type, ValidationMessageType.error);
      expect(result.messages.last.message, contains('code end user license agreement not signed'));
    });

    testWithoutContext('Emits partial status when simctl is not installed', () async {
      final ProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>['/usr/bin/xcode-select', '--print-path'],
          stdout: '/Library/Developer/CommandLineTools',
        ),
        const FakeCommand(
          command: <String>[
            'which',
            'sysctl',
          ],
        ),
        const FakeCommand(
          command: <String>[
            'sysctl',
            'hw.optional.arm64',
          ],
          exitCode: 1,
        ),
        const FakeCommand(
          command: <String>['xcrun', 'clang'],
        ),
        const FakeCommand(
          command: <String>['xcrun', 'simctl', 'list'],
          exitCode: 1,
        ),
      ]);
      final Xcode xcode = Xcode.test(
        processManager: processManager,
        xcodeProjectInterpreter: XcodeProjectInterpreter.test(processManager: processManager),
      );
      final XcodeValidator validator = XcodeValidator(xcode: xcode, userMessages: UserMessages());
      final ValidationResult result = await validator.validate();
      expect(result.type, ValidationType.partial);
      expect(result.messages.last.type, ValidationMessageType.error);
      expect(result.messages.last.message, contains('Xcode requires additional components'));
    });

    testWithoutContext('Succeeds when all checks pass', () async {
      final ProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>['/usr/bin/xcode-select', '--print-path'],
          stdout: '/Library/Developer/CommandLineTools',
        ),
        const FakeCommand(
          command: <String>[
            'which',
            'sysctl',
          ],
        ),
        const FakeCommand(
          command: <String>[
            'sysctl',
            'hw.optional.arm64',
          ],
          exitCode: 1,
        ),
        const FakeCommand(
          command: <String>['xcrun', 'clang'],
        ),
        const FakeCommand(
          command: <String>['xcrun', 'simctl', 'list'],
        ),
      ]);
      final Xcode xcode = Xcode.test(
        processManager: processManager,
        xcodeProjectInterpreter: XcodeProjectInterpreter.test(processManager: processManager),
      );
      final XcodeValidator validator = XcodeValidator(xcode: xcode, userMessages: UserMessages());
      final ValidationResult result = await validator.validate();
      expect(result.type, ValidationType.installed);
      expect(result.messages.length, 1);
      final ValidationMessage firstMessage = result.messages.first;
      expect(firstMessage.type, ValidationMessageType.information);
      expect(firstMessage.message, 'Xcode at /Library/Developer/CommandLineTools');
      expect(result.statusInfo, '1000.0.0');
    });
  });
}
