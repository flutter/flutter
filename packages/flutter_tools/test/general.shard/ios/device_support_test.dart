// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fake_async/fake_async.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/base/version.dart';
import 'package:flutter_tools/src/ios/device_support.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';

void main() {
  group('IOSDeviceSupport', () {
    testWithoutContext('does nothing when Xcode is null', () async {
      final processManager = FakeProcessManager.empty();
      final logger = BufferLogger.test();
      final processUtils = ProcessUtils(processManager: processManager, logger: logger);

      final deviceSupport = IOSDeviceSupport(
        logger: logger,
        processUtils: processUtils,
        xcode: null,
      );

      await deviceSupport.prepareDeviceSupport('id-123');

      expect(processManager, hasNoRemainingExpectations);
      expect(logger.statusText, isEmpty);
      expect(logger.traceText, isEmpty);
      expect(logger.errorText, isEmpty);
    });

    testWithoutContext('does nothing when Xcode version is less than 16.3.0', () async {
      final processManager = FakeProcessManager.empty();
      final logger = BufferLogger.test();
      final processUtils = ProcessUtils(processManager: processManager, logger: logger);

      final deviceSupport = IOSDeviceSupport(
        logger: logger,
        processUtils: processUtils,
        xcode: FakeXcode(currentVersion: Version(16, 2, 0)),
      );

      await deviceSupport.prepareDeviceSupport('id-123');

      expect(processManager, hasNoRemainingExpectations);
      expect(logger.statusText, isEmpty);
      expect(logger.traceText, isEmpty);
      expect(logger.errorText, isEmpty);
    });

    testWithoutContext(
      'runs prepareDeviceSupport and logs stdout to trace when Copying is not present',
      () async {
        final processManager = FakeProcessManager.empty();
        final logger = BufferLogger.test();
        final processUtils = ProcessUtils(processManager: processManager, logger: logger);

        processManager.addCommand(
          const FakeCommand(
            command: <String>[
              'xcrun',
              'xcodebuild',
              '-prepareDeviceSupport',
              '-destination',
              'id=id-123',
            ],
            stdout: 'Preparing device support...',
          ),
        );

        final deviceSupport = IOSDeviceSupport(
          logger: logger,
          processUtils: processUtils,
          xcode: FakeXcode(currentVersion: Version(16, 3, 0)),
        );

        await deviceSupport.prepareDeviceSupport('id-123');

        expect(processManager, hasNoRemainingExpectations);
        expect(logger.traceText, contains('Preparing device support...'));
        expect(logger.statusText, isEmpty);
        expect(logger.errorText, isEmpty);
      },
    );

    testWithoutContext('runs prepareDeviceSupport and logs Copying messages to status', () async {
      final processManager = FakeProcessManager.empty();
      final logger = BufferLogger.test();
      final processUtils = ProcessUtils(processManager: processManager, logger: logger);

      processManager.addCommand(
        const FakeCommand(
          command: <String>[
            'xcrun',
            'xcodebuild',
            '-prepareDeviceSupport',
            '-destination',
            'id=id-123',
          ],
          stdout: 'Copying symbols...',
        ),
      );

      final deviceSupport = IOSDeviceSupport(
        logger: logger,
        processUtils: processUtils,
        xcode: FakeXcode(currentVersion: Version(16, 3, 0)),
      );

      await deviceSupport.prepareDeviceSupport('id-123');

      expect(processManager, hasNoRemainingExpectations);
      expect(
        logger.statusText,
        contains(
          'Copying Device Support symbols. This may take several minutes to complete...\n'
          'Please do not connect or disconnect your device until finished.',
        ),
      );
      expect(logger.statusText, contains('Copying symbols...'));
      expect(logger.statusText, endsWith('\n'));
      expect(
        logger.traceText,
        'executing: xcrun xcodebuild -prepareDeviceSupport -destination id=id-123\n',
      );
      expect(logger.errorText, isEmpty);
    });

    testWithoutContext('runs prepareDeviceSupport and logs stderr to error', () async {
      final processManager = FakeProcessManager.empty();
      final logger = BufferLogger.test();
      final processUtils = ProcessUtils(processManager: processManager, logger: logger);

      processManager.addCommand(
        const FakeCommand(
          command: <String>[
            'xcrun',
            'xcodebuild',
            '-prepareDeviceSupport',
            '-destination',
            'id=id-123',
          ],
          stderr: 'Error occurred',
        ),
      );

      final deviceSupport = IOSDeviceSupport(
        logger: logger,
        processUtils: processUtils,
        xcode: FakeXcode(currentVersion: Version(17, 0, 0)),
      );

      await deviceSupport.prepareDeviceSupport('id-123');

      expect(processManager, hasNoRemainingExpectations);
      expect(logger.errorText, contains('Error occurred'));
    });

    testWithoutContext(
      'prints error message when prepareDeviceSupport takes longer than 10 seconds',
      () {
        FakeAsync().run((fakeAsync) {
          final processManager = FakeProcessManager.empty();
          final logger = BufferLogger.test();
          final processUtils = ProcessUtils(processManager: processManager, logger: logger);

          processManager.addCommand(
            const FakeCommand(
              command: <String>[
                'xcrun',
                'xcodebuild',
                '-prepareDeviceSupport',
                '-destination',
                'id=id-123',
              ],
              duration: Duration(seconds: 11),
            ),
          );

          final deviceSupport = IOSDeviceSupport(
            logger: logger,
            processUtils: processUtils,
            xcode: FakeXcode(currentVersion: Version(16, 3, 0)),
          );

          deviceSupport.prepareDeviceSupport('id-123');

          fakeAsync.elapse(const Duration(seconds: 10));

          expect(
            logger.errorText,
            contains(
              'Xcode is taking longer than expected to start preparing Device Support symbols...\n'
              'Connect your device via USB and try running this command manually:\n'
              '  "xcrun xcodebuild -prepareDeviceSupport -destination id=id-123"',
            ),
          );

          fakeAsync.elapse(const Duration(seconds: 1));
        });
      },
    );

    testWithoutContext('does not print error message if Copying is printed within 10 seconds', () {
      FakeAsync().run((fakeAsync) {
        final processManager = FakeProcessManager.empty();
        final logger = BufferLogger.test();
        final processUtils = ProcessUtils(processManager: processManager, logger: logger);

        processManager.addCommand(
          const FakeCommand(
            command: <String>[
              'xcrun',
              'xcodebuild',
              '-prepareDeviceSupport',
              '-destination',
              'id=id-123',
            ],
            duration: Duration(seconds: 11),
            stdout: 'Copying symbols...',
          ),
        );

        final deviceSupport = IOSDeviceSupport(
          logger: logger,
          processUtils: processUtils,
          xcode: FakeXcode(currentVersion: Version(16, 3, 0)),
        );

        deviceSupport.prepareDeviceSupport('id-123');

        fakeAsync.elapse(const Duration(seconds: 11));

        expect(logger.errorText, isEmpty);
      });
    });
  });
}

class FakeXcode extends Fake implements Xcode {
  FakeXcode({this.currentVersion});

  @override
  final Version? currentVersion;
}
