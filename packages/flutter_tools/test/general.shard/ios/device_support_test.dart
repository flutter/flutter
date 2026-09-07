// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fake_async/fake_async.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
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
        homeDirectory: null,
        modelCode: null,
        operatingSystemVersion: null,
        cpuArchitectureString: null,
        deviceId: 'id-123',
      );

      await deviceSupport.prepareDeviceSupport();

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
        homeDirectory: null,
        modelCode: null,
        operatingSystemVersion: null,
        cpuArchitectureString: null,
        deviceId: 'id-123',
      );

      await deviceSupport.prepareDeviceSupport();

      expect(processManager, hasNoRemainingExpectations);
      expect(logger.statusText, isEmpty);
      expect(logger.traceText, isEmpty);
      expect(logger.errorText, isEmpty);
    });

    testWithoutContext('does nothing when existingDeviceSupportSymbols is non-null', () async {
      final FileSystem fileSystem = MemoryFileSystem.test();
      final Directory homeDir = fileSystem.directory('/Users/username');
      final Directory supportDir = homeDir
          .childDirectory('Library')
          .childDirectory('Developer')
          .childDirectory('Xcode')
          .childDirectory('iOS DeviceSupport');
      supportDir
          .childDirectory('iPhone15,2 17.0')
          .childDirectory('Symbols')
          .createSync(recursive: true);

      final processManager = FakeProcessManager.empty();
      final logger = BufferLogger.test();
      final processUtils = ProcessUtils(processManager: processManager, logger: logger);

      final deviceSupport = IOSDeviceSupport(
        logger: logger,
        processUtils: processUtils,
        xcode: FakeXcode(currentVersion: Version(16, 3, 0)),
        homeDirectory: homeDir,
        modelCode: 'iPhone15,2',
        operatingSystemVersion: '17.0',
        cpuArchitectureString: 'arm64e',
        deviceId: 'id-123',
      );

      await deviceSupport.prepareDeviceSupport();

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
          homeDirectory: null,
          modelCode: null,
          operatingSystemVersion: null,
          cpuArchitectureString: null,
          deviceId: 'id-123',
        );

        await deviceSupport.prepareDeviceSupport();

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
        homeDirectory: null,
        modelCode: null,
        operatingSystemVersion: null,
        cpuArchitectureString: null,
        deviceId: 'id-123',
      );

      await deviceSupport.prepareDeviceSupport();

      expect(processManager, hasNoRemainingExpectations);
      expect(
        logger.statusText,
        contains(
          'Copying Device Support symbols. This may take several minutes to complete...\n'
          'Please do not connect or disconnect your device or open Xcode until finished.',
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
        homeDirectory: null,
        modelCode: null,
        operatingSystemVersion: null,
        cpuArchitectureString: null,
        deviceId: 'id-123',
      );

      await deviceSupport.prepareDeviceSupport();

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
            homeDirectory: null,
            modelCode: null,
            operatingSystemVersion: null,
            cpuArchitectureString: null,
            deviceId: 'id-123',
          );

          deviceSupport.prepareDeviceSupport();

          fakeAsync.elapse(const Duration(seconds: 10));

          expect(
            logger.errorText,
            contains(
              'Xcode is taking longer than expected to start preparing Device Support symbols...\n'
              'Try closing Xcode, connecting your device via USB, and running the following command:\n'
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
          homeDirectory: null,
          modelCode: null,
          operatingSystemVersion: null,
          cpuArchitectureString: null,
          deviceId: 'id-123',
        );

        deviceSupport.prepareDeviceSupport();

        fakeAsync.elapse(const Duration(seconds: 11));

        expect(logger.errorText, isEmpty);
      });
    });

    group('missingSymbolsWarning', () {
      group('Xcode < 16.3', () {
        testWithoutContext('returns unable to find warning when supportDir is null', () {
          final deviceSupport = IOSDeviceSupport(
            logger: BufferLogger.test(),
            processUtils: ProcessUtils(
              processManager: FakeProcessManager.empty(),
              logger: BufferLogger.test(),
            ),
            xcode: FakeXcode(currentVersion: Version(16, 2, 0)),
            homeDirectory: null,
            modelCode: 'iPhone15,2',
            operatingSystemVersion: '17.0',
            cpuArchitectureString: 'arm64e',
            deviceId: 'id-123',
          );
          final String? warning = deviceSupport.missingSymbolsWarning();
          expect(
            warning,
            'Xcode Device Support was not found for this device. This will likely reduce debugging '
            'performance and may cause the app to hang on a white screen during launch.\n'
            'To trigger Device Symbols to be copied, connect the device via USB, close and then '
            're-open Xcode. It may take several minutes for Xcode to copy symbols from the device.\n'
            'Once Device Support symbols are finished being copied, they are expected to be found at '
            '\$HOME/Library/Developer/Xcode/iOS DeviceSupport\n'
            'Please retry "flutter run" once symbols are finished being copied.',
          );
        });

        testWithoutContext('returns unable to find warning when device directory does not exist', () {
          final FileSystem fileSystem = MemoryFileSystem.test();
          final Directory homeDir = fileSystem.directory('/Users/username');
          final deviceSupport = IOSDeviceSupport(
            logger: BufferLogger.test(),
            processUtils: ProcessUtils(
              processManager: FakeProcessManager.empty(),
              logger: BufferLogger.test(),
            ),
            xcode: FakeXcode(currentVersion: Version(16, 2, 0)),
            homeDirectory: homeDir,
            modelCode: 'iPhone15,2',
            operatingSystemVersion: '17.0',
            cpuArchitectureString: 'arm64e',
            deviceId: 'id-123',
          );
          final String? warning = deviceSupport.missingSymbolsWarning();
          expect(
            warning,
            'Xcode Device Support was not found for this device. This will likely reduce debugging '
            'performance and may cause the app to hang on a white screen during launch.\n'
            'To trigger Device Symbols to be copied, connect the device via USB, close and then '
            're-open Xcode. It may take several minutes for Xcode to copy symbols from the device.\n'
            'Once Device Support symbols are finished being copied, they are expected to be found at '
            '/Users/username/Library/Developer/Xcode/iOS DeviceSupport/iPhone15,2 17.0/Symbols or '
            '/Users/username/Library/Developer/Xcode/iOS DeviceSupport/iPhone15,2 17.0/arm64e/Symbols\n'
            'Please retry "flutter run" once symbols are finished being copied.',
          );
        });

        testWithoutContext(
          'returns incomplete copy warning when device directory exists but symbols folder does not',
          () {
            final FileSystem fileSystem = MemoryFileSystem.test();
            final Directory homeDir = fileSystem.directory('/Users/username');
            final Directory supportDir = homeDir
                .childDirectory('Library')
                .childDirectory('Developer')
                .childDirectory('Xcode')
                .childDirectory('iOS DeviceSupport');
            supportDir.childDirectory('iPhone15,2 17.0').createSync(recursive: true);

            final deviceSupport = IOSDeviceSupport(
              logger: BufferLogger.test(),
              processUtils: ProcessUtils(
                processManager: FakeProcessManager.empty(),
                logger: BufferLogger.test(),
              ),
              xcode: FakeXcode(currentVersion: Version(16, 2, 0)),
              homeDirectory: homeDir,
              modelCode: 'iPhone15,2',
              operatingSystemVersion: '17.0',
              cpuArchitectureString: 'arm64e',
              deviceId: 'id-123',
            );
            final String? warning = deviceSupport.missingSymbolsWarning();
            expect(
              warning,
              'Xcode has not finished copying Device Support symbols for this device. This will '
              'likely reduce debugging performance and may cause the app to hang on a white screen '
              'during launch.\n'
              'To trigger Device Symbols to be copied, connect the device via USB, close and then '
              're-open Xcode. It may take several minutes for Xcode to copy symbols from the device.\n'
              'Once Device Support symbols are finished being copied, they are expected to be found at '
              '/Users/username/Library/Developer/Xcode/iOS DeviceSupport/iPhone15,2 17.0/Symbols or '
              '/Users/username/Library/Developer/Xcode/iOS DeviceSupport/iPhone15,2 17.0/arm64e/Symbols\n'
              'Please retry "flutter run" once symbols are finished being copied.',
            );
          },
        );

        testWithoutContext('returns null when symbol directory exists', () {
          final FileSystem fileSystem = MemoryFileSystem.test();
          final Directory homeDir = fileSystem.directory('/Users/username');
          final Directory supportDir = homeDir
              .childDirectory('Library')
              .childDirectory('Developer')
              .childDirectory('Xcode')
              .childDirectory('iOS DeviceSupport');
          supportDir
              .childDirectory('iPhone15,2 17.0')
              .childDirectory('Symbols')
              .createSync(recursive: true);

          final deviceSupport = IOSDeviceSupport(
            logger: BufferLogger.test(),
            processUtils: ProcessUtils(
              processManager: FakeProcessManager.empty(),
              logger: BufferLogger.test(),
            ),
            xcode: FakeXcode(currentVersion: Version(16, 2, 0)),
            homeDirectory: homeDir,
            modelCode: 'iPhone15,2',
            operatingSystemVersion: '17.0',
            cpuArchitectureString: 'arm64e',
            deviceId: 'id-123',
          );
          final String? warning = deviceSupport.missingSymbolsWarning();
          expect(warning, isNull);
        });

        testWithoutContext('returns null when architecture symbol directory exists', () {
          final FileSystem fileSystem = MemoryFileSystem.test();
          final Directory homeDir = fileSystem.directory('/Users/username');
          final Directory supportDir = homeDir
              .childDirectory('Library')
              .childDirectory('Developer')
              .childDirectory('Xcode')
              .childDirectory('iOS DeviceSupport');
          supportDir
              .childDirectory('iPhone15,2 17.0')
              .childDirectory('arm64e')
              .childDirectory('Symbols')
              .createSync(recursive: true);

          final deviceSupport = IOSDeviceSupport(
            logger: BufferLogger.test(),
            processUtils: ProcessUtils(
              processManager: FakeProcessManager.empty(),
              logger: BufferLogger.test(),
            ),
            xcode: FakeXcode(currentVersion: Version(16, 2, 0)),
            homeDirectory: homeDir,
            modelCode: 'iPhone15,2',
            operatingSystemVersion: '17.0',
            cpuArchitectureString: 'arm64e',
            deviceId: 'id-123',
          );
          final String? warning = deviceSupport.missingSymbolsWarning();
          expect(warning, isNull);
        });

        testWithoutContext(
          'returns warning when symbol directory exists and warnWhenSymbolsExist is true',
          () {
            final FileSystem fileSystem = MemoryFileSystem.test();
            final Directory homeDir = fileSystem.directory('/Users/username');
            final Directory supportDir = homeDir
                .childDirectory('Library')
                .childDirectory('Developer')
                .childDirectory('Xcode')
                .childDirectory('iOS DeviceSupport');
            supportDir
                .childDirectory('iPhone15,2 17.0')
                .childDirectory('Symbols')
                .createSync(recursive: true);

            final deviceSupport = IOSDeviceSupport(
              logger: BufferLogger.test(),
              processUtils: ProcessUtils(
                processManager: FakeProcessManager.empty(),
                logger: BufferLogger.test(),
              ),
              xcode: FakeXcode(currentVersion: Version(16, 2, 0)),
              homeDirectory: homeDir,
              modelCode: 'iPhone15,2',
              operatingSystemVersion: '17.0',
              cpuArchitectureString: 'arm64e',
              deviceId: 'id-123',
            );
            final String? warning = deviceSupport.missingSymbolsWarning(warnWhenSymbolsExist: true);
            expect(
              warning,
              'Xcode Device Support symbols exist for this device, but are being read from '
              'process memory. This will likely reduce debugging performance and may cause the app to hang on a white screen during launch.\n'
              'To re-copy symbols from your device, complete the following steps:\n'
              '  1. Remove cached symbols:\n'
              '     rm -rf "/Users/username/Library/Developer/Xcode/iOS DeviceSupport/iPhone15,2 17.0"\n'
              '  2. Connect the device via USB, close and then re-open Xcode. It may take several '
              'minutes for Xcode to copy symbols from the device. Once Device Support symbols are finished being copied, they are expected to be found at '
              '/Users/username/Library/Developer/Xcode/iOS DeviceSupport/iPhone15,2 17.0/Symbols',
            );
          },
        );
      });

      group('Xcode 16.3+', () {
        testWithoutContext('returns unable to find warning when supportDir is null', () {
          final deviceSupport = IOSDeviceSupport(
            logger: BufferLogger.test(),
            processUtils: ProcessUtils(
              processManager: FakeProcessManager.empty(),
              logger: BufferLogger.test(),
            ),
            xcode: FakeXcode(currentVersion: Version(16, 3, 0)),
            homeDirectory: null,
            modelCode: 'iPhone15,2',
            operatingSystemVersion: '17.0',
            cpuArchitectureString: 'arm64e',
            deviceId: 'id-123',
          );
          final String? warning = deviceSupport.missingSymbolsWarning();
          expect(
            warning,
            'Xcode Device Support was not found for this device. This will likely reduce debugging '
            'performance and may cause the app to hang on a white screen during launch.\n'
            'To trigger Device Symbols to be copied, connect the device via USB, and run this command:\n'
            '  "xcrun xcodebuild -prepareDeviceSupport -destination id=id-123"\n'
            'Once Device Support symbols are finished being copied, they are expected to be found at '
            '\$HOME/Library/Developer/Xcode/iOS DeviceSupport\n'
            'Please retry "flutter run" once symbols are finished being copied.',
          );
        });

        testWithoutContext('returns unable to find warning when device directory does not exist', () {
          final FileSystem fileSystem = MemoryFileSystem.test();
          final Directory homeDir = fileSystem.directory('/Users/username');
          final deviceSupport = IOSDeviceSupport(
            logger: BufferLogger.test(),
            processUtils: ProcessUtils(
              processManager: FakeProcessManager.empty(),
              logger: BufferLogger.test(),
            ),
            xcode: FakeXcode(currentVersion: Version(16, 3, 0)),
            homeDirectory: homeDir,
            modelCode: 'iPhone15,2',
            operatingSystemVersion: '17.0',
            cpuArchitectureString: 'arm64e',
            deviceId: 'id-123',
          );
          final String? warning = deviceSupport.missingSymbolsWarning();
          expect(
            warning,
            'Xcode Device Support was not found for this device. This will likely reduce debugging '
            'performance and may cause the app to hang on a white screen during launch.\n'
            'To trigger Device Symbols to be copied, connect the device via USB, and run this command:\n'
            '  "xcrun xcodebuild -prepareDeviceSupport -destination id=id-123"\n'
            'Once Device Support symbols are finished being copied, they are expected to be found at '
            '/Users/username/Library/Developer/Xcode/iOS DeviceSupport/iPhone15,2 17.0/Symbols or '
            '/Users/username/Library/Developer/Xcode/iOS DeviceSupport/iPhone15,2 17.0/arm64e/Symbols\n'
            'Please retry "flutter run" once symbols are finished being copied.',
          );
        });

        testWithoutContext(
          'returns incomplete copy warning when device directory exists but symbols folder does not',
          () {
            final FileSystem fileSystem = MemoryFileSystem.test();
            final Directory homeDir = fileSystem.directory('/Users/username');
            final Directory supportDir = homeDir
                .childDirectory('Library')
                .childDirectory('Developer')
                .childDirectory('Xcode')
                .childDirectory('iOS DeviceSupport');
            supportDir.childDirectory('iPhone15,2 17.0').createSync(recursive: true);

            final deviceSupport = IOSDeviceSupport(
              logger: BufferLogger.test(),
              processUtils: ProcessUtils(
                processManager: FakeProcessManager.empty(),
                logger: BufferLogger.test(),
              ),
              xcode: FakeXcode(currentVersion: Version(16, 3, 0)),
              homeDirectory: homeDir,
              modelCode: 'iPhone15,2',
              operatingSystemVersion: '17.0',
              cpuArchitectureString: 'arm64e',
              deviceId: 'id-123',
            );
            final String? warning = deviceSupport.missingSymbolsWarning();
            expect(
              warning,
              'Xcode has not finished copying Device Support symbols for this device. This will '
              'likely reduce debugging performance and may cause the app to hang on a white screen '
              'during launch.\n'
              'To trigger Device Symbols to be copied, connect the device via USB, and run this command:\n'
              '  "xcrun xcodebuild -prepareDeviceSupport -destination id=id-123"\n'
              'Once Device Support symbols are finished being copied, they are expected to be found at '
              '/Users/username/Library/Developer/Xcode/iOS DeviceSupport/iPhone15,2 17.0/Symbols or '
              '/Users/username/Library/Developer/Xcode/iOS DeviceSupport/iPhone15,2 17.0/arm64e/Symbols\n'
              'Please retry "flutter run" once symbols are finished being copied.',
            );
          },
        );

        testWithoutContext('returns null when symbol directory exists', () {
          final FileSystem fileSystem = MemoryFileSystem.test();
          final Directory homeDir = fileSystem.directory('/Users/username');
          final Directory supportDir = homeDir
              .childDirectory('Library')
              .childDirectory('Developer')
              .childDirectory('Xcode')
              .childDirectory('iOS DeviceSupport');
          supportDir
              .childDirectory('iPhone15,2 17.0')
              .childDirectory('Symbols')
              .createSync(recursive: true);

          final deviceSupport = IOSDeviceSupport(
            logger: BufferLogger.test(),
            processUtils: ProcessUtils(
              processManager: FakeProcessManager.empty(),
              logger: BufferLogger.test(),
            ),
            xcode: FakeXcode(currentVersion: Version(16, 3, 0)),
            homeDirectory: homeDir,
            modelCode: 'iPhone15,2',
            operatingSystemVersion: '17.0',
            cpuArchitectureString: 'arm64e',
            deviceId: 'id-123',
          );
          final String? warning = deviceSupport.missingSymbolsWarning();
          expect(warning, isNull);
        });

        testWithoutContext('returns null when architecture symbol directory exists', () {
          final FileSystem fileSystem = MemoryFileSystem.test();
          final Directory homeDir = fileSystem.directory('/Users/username');
          final Directory supportDir = homeDir
              .childDirectory('Library')
              .childDirectory('Developer')
              .childDirectory('Xcode')
              .childDirectory('iOS DeviceSupport');
          supportDir
              .childDirectory('iPhone15,2 17.0')
              .childDirectory('arm64e')
              .childDirectory('Symbols')
              .createSync(recursive: true);

          final deviceSupport = IOSDeviceSupport(
            logger: BufferLogger.test(),
            processUtils: ProcessUtils(
              processManager: FakeProcessManager.empty(),
              logger: BufferLogger.test(),
            ),
            xcode: FakeXcode(currentVersion: Version(16, 3, 0)),
            homeDirectory: homeDir,
            modelCode: 'iPhone15,2',
            operatingSystemVersion: '17.0',
            cpuArchitectureString: 'arm64e',
            deviceId: 'id-123',
          );
          final String? warning = deviceSupport.missingSymbolsWarning();
          expect(warning, isNull);
        });

        testWithoutContext(
          'returns warning when symbol directory exists and warnWhenSymbolsExist is true',
          () {
            final FileSystem fileSystem = MemoryFileSystem.test();
            final Directory homeDir = fileSystem.directory('/Users/username');
            final Directory supportDir = homeDir
                .childDirectory('Library')
                .childDirectory('Developer')
                .childDirectory('Xcode')
                .childDirectory('iOS DeviceSupport');
            supportDir
                .childDirectory('iPhone15,2 17.0')
                .childDirectory('Symbols')
                .createSync(recursive: true);

            final deviceSupport = IOSDeviceSupport(
              logger: BufferLogger.test(),
              processUtils: ProcessUtils(
                processManager: FakeProcessManager.empty(),
                logger: BufferLogger.test(),
              ),
              xcode: FakeXcode(currentVersion: Version(16, 3, 0)),
              homeDirectory: homeDir,
              modelCode: 'iPhone15,2',
              operatingSystemVersion: '17.0',
              cpuArchitectureString: 'arm64e',
              deviceId: 'id-123',
            );
            final String? warning = deviceSupport.missingSymbolsWarning(warnWhenSymbolsExist: true);
            expect(
              warning,
              'Xcode Device Support symbols exist for this device, but are being read from '
              'process memory. This will likely reduce debugging performance and may cause the app to hang on a white screen during launch.\n'
              'To re-copy symbols from your device, complete the following steps:\n'
              '  1. Remove cached symbols:\n'
              '     rm -rf "/Users/username/Library/Developer/Xcode/iOS DeviceSupport/iPhone15,2 17.0"\n'
              '  2. Connect the device via USB and trigger a copy:\n'
              '     xcrun xcodebuild -prepareDeviceSupport -destination id=id-123',
            );
          },
        );
      });
    });

    group('existingDeviceSupportSymbols', () {
      testWithoutContext('returns null when neither directory exists', () {
        final FileSystem fileSystem = MemoryFileSystem.test();
        final Directory homeDir = fileSystem.directory('/Users/username');
        final deviceSupport = IOSDeviceSupport(
          logger: BufferLogger.test(),
          processUtils: ProcessUtils(
            processManager: FakeProcessManager.empty(),
            logger: BufferLogger.test(),
          ),
          xcode: null,
          homeDirectory: homeDir,
          modelCode: 'iPhone15,2',
          operatingSystemVersion: '17.0',
          cpuArchitectureString: 'arm64e',
          deviceId: 'id-123',
        );
        expect(deviceSupport.existingDeviceSupportSymbols, isNull);
      });

      testWithoutContext('is dynamic getter and re-evaluates symbol directories', () {
        final FileSystem fileSystem = MemoryFileSystem.test();
        final Directory homeDir = fileSystem.directory('/Users/username');
        final deviceSupport = IOSDeviceSupport(
          logger: BufferLogger.test(),
          processUtils: ProcessUtils(
            processManager: FakeProcessManager.empty(),
            logger: BufferLogger.test(),
          ),
          xcode: null,
          homeDirectory: homeDir,
          modelCode: 'iPhone15,2',
          operatingSystemVersion: '17.0',
          cpuArchitectureString: 'arm64e',
          deviceId: 'id-123',
        );
        expect(deviceSupport.existingDeviceSupportSymbols, isNull);

        final Directory symbolDir =
            homeDir
                .childDirectory('Library')
                .childDirectory('Developer')
                .childDirectory('Xcode')
                .childDirectory('iOS DeviceSupport')
                .childDirectory('iPhone15,2 17.0')
                .childDirectory('Symbols')
              ..createSync(recursive: true);

        expect(deviceSupport.existingDeviceSupportSymbols?.path, symbolDir.path);
      });

      testWithoutContext('returns symbolDirectory when symbolDirectory exists', () {
        final FileSystem fileSystem = MemoryFileSystem.test();
        final Directory homeDir = fileSystem.directory('/Users/username');
        final Directory supportDir = homeDir
            .childDirectory('Library')
            .childDirectory('Developer')
            .childDirectory('Xcode')
            .childDirectory('iOS DeviceSupport');
        final Directory symbolDir =
            supportDir.childDirectory('iPhone15,2 17.0').childDirectory('Symbols')
              ..createSync(recursive: true);

        final deviceSupport = IOSDeviceSupport(
          logger: BufferLogger.test(),
          processUtils: ProcessUtils(
            processManager: FakeProcessManager.empty(),
            logger: BufferLogger.test(),
          ),
          xcode: null,
          homeDirectory: homeDir,
          modelCode: 'iPhone15,2',
          operatingSystemVersion: '17.0',
          cpuArchitectureString: 'arm64e',
          deviceId: 'id-123',
        );
        expect(deviceSupport.existingDeviceSupportSymbols?.path, symbolDir.path);
      });

      testWithoutContext('returns archSymbolDirectory when archSymbolDirectory exists', () {
        final FileSystem fileSystem = MemoryFileSystem.test();
        final Directory homeDir = fileSystem.directory('/Users/username');
        final Directory supportDir = homeDir
            .childDirectory('Library')
            .childDirectory('Developer')
            .childDirectory('Xcode')
            .childDirectory('iOS DeviceSupport');
        supportDir
            .childDirectory('iPhone15,2 17.0')
            .childDirectory('Symbols')
            .createSync(recursive: true);
        final Directory archSymbolDir =
            supportDir
                .childDirectory('iPhone15,2 17.0')
                .childDirectory('arm64e')
                .childDirectory('Symbols')
              ..createSync(recursive: true);

        final deviceSupport = IOSDeviceSupport(
          logger: BufferLogger.test(),
          processUtils: ProcessUtils(
            processManager: FakeProcessManager.empty(),
            logger: BufferLogger.test(),
          ),
          xcode: null,
          homeDirectory: homeDir,
          modelCode: 'iPhone15,2',
          operatingSystemVersion: '17.0',
          cpuArchitectureString: 'arm64e',
          deviceId: 'id-123',
        );
        expect(deviceSupport.existingDeviceSupportSymbols?.path, archSymbolDir.path);
      });
    });
  });
}

class FakeXcode extends Fake implements Xcode {
  FakeXcode({this.currentVersion});

  @override
  final Version? currentVersion;
}
