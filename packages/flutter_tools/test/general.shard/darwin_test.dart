// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/targets/darwin.dart';
import 'package:flutter_tools/src/darwin/darwin.dart';

import '../src/common.dart';

void main() {
  group('FlutterDarwinPlatform', () {
    group('iOS', () {
      testWithoutContext('deployment target is 15.0', () {
        expect(FlutterDarwinPlatform.ios.deploymentTarget().toString(), '15.0');
      });
      testWithoutContext('debug artifactName', () {
        expect(FlutterDarwinPlatform.ios.artifactName(BuildMode.debug), 'ios');
      });
      testWithoutContext('profile artifactName', () {
        expect(FlutterDarwinPlatform.ios.artifactName(BuildMode.profile), 'ios-profile');
      });
      testWithoutContext('release artifactName', () {
        expect(FlutterDarwinPlatform.ios.artifactName(BuildMode.release), 'ios-release');
      });
      testWithoutContext('fromTargetPlatform', () {
        expect(
          FlutterDarwinPlatform.fromTargetPlatform(TargetPlatform.ios),
          FlutterDarwinPlatform.ios,
        );
        expect(FlutterDarwinPlatform.fromTargetPlatform(TargetPlatform.android), null);
      });
      testWithoutContext('fromName', () {
        expect(FlutterDarwinPlatform.fromName('ios'), FlutterDarwinPlatform.ios);
        expect(FlutterDarwinPlatform.fromName('iOS'), null);
        expect(FlutterDarwinPlatform.fromName('android'), null);
      });
    });
    group('macOS', () {
      testWithoutContext('deployment target is 12.0', () {
        expect(FlutterDarwinPlatform.macos.deploymentTarget().toString(), '12.0');
      });

      testWithoutContext('debug artifactName', () {
        expect(FlutterDarwinPlatform.macos.artifactName(BuildMode.debug), 'darwin-x64');
      });
      testWithoutContext('profile artifactName', () {
        expect(FlutterDarwinPlatform.macos.artifactName(BuildMode.profile), 'darwin-x64-profile');
      });
      testWithoutContext('release artifactName', () {
        expect(FlutterDarwinPlatform.macos.artifactName(BuildMode.release), 'darwin-x64-release');
      });
      testWithoutContext('fromTargetPlatform', () {
        expect(
          FlutterDarwinPlatform.fromTargetPlatform(TargetPlatform.darwin),
          FlutterDarwinPlatform.macos,
        );
        expect(FlutterDarwinPlatform.fromTargetPlatform(TargetPlatform.android), null);
      });
      testWithoutContext('fromName', () {
        expect(FlutterDarwinPlatform.fromName('macos'), FlutterDarwinPlatform.macos);
        expect(FlutterDarwinPlatform.fromName('macOS'), null);
        expect(FlutterDarwinPlatform.fromName('android'), null);
      });
    });
  });

  group('print Xcode', () {
    late BufferLogger logger;

    setUp(() {
      logger = BufferLogger.test();
    });

    testWithoutContext('Warning with no filePath/lineNumber', () {
      printXcodeWarning('warning message', logger: logger);
      expect(logger.errorText, startsWith('warning: warning message\n'));
      expect(logger.hadErrorOutput, isFalse);
    });

    testWithoutContext('Warning with filePath/lineNumber', () {
      printXcodeWarning('warning message', logger: logger, filePath: '/path/to', lineNumber: 123);
      expect(logger.errorText, startsWith('/path/to:123: warning: warning message\n'));
      expect(logger.hadErrorOutput, isFalse);
    });

    testWithoutContext('Warning with lineNumber but no filePath', () {
      printXcodeWarning('warning message', logger: logger, lineNumber: 123);
      expect(logger.errorText, startsWith('warning: warning message\n'));
      expect(logger.hadErrorOutput, isFalse);
    });

    testWithoutContext('Error with no filePath/lineNumber', () {
      printXcodeError('error message', logger: logger);
      expect(logger.errorText, startsWith('error: error message\n'));
      expect(logger.hadErrorOutput, isTrue);
    });

    testWithoutContext('Error with filePath/lineNumber', () {
      printXcodeError('error message', logger: logger, filePath: '/path/to', lineNumber: 123);
      expect(logger.errorText, startsWith('/path/to:123: error: error message\n'));
      expect(logger.hadErrorOutput, isTrue);
    });

    testWithoutContext('Error with lineNumber but no filePath', () {
      printXcodeError('error message', logger: logger, lineNumber: 123);
      expect(logger.errorText, startsWith('error: error message\n'));
      expect(logger.hadErrorOutput, isTrue);
    });

    testWithoutContext('Note with no filePath/lineNumber', () {
      printXcodeNote('note message', logger: logger);
      expect(logger.errorText, startsWith('note: note message\n'));
      expect(logger.hadErrorOutput, isFalse);
    });

    testWithoutContext('Note with filePath/lineNumber', () {
      printXcodeNote('note message', logger: logger, filePath: '/path/to', lineNumber: 123);
      expect(logger.errorText, startsWith('/path/to:123: note: note message\n'));
      expect(logger.hadErrorOutput, isFalse);
    });

    testWithoutContext('Note with lineNumber but no filePath', () {
      printXcodeNote('note message', logger: logger, lineNumber: 123);
      expect(logger.errorText, startsWith('note: note message\n'));
      expect(logger.hadErrorOutput, isFalse);
    });

    testWithoutContext('VerboseLogger output format', () {
      final verboseLogger = VerboseLogger(logger);
      printXcodeWarning(
        'warning message',
        logger: verboseLogger,
        filePath: '/path/to',
        lineNumber: 123,
      );
      expect(
        logger.errorText,
        matches(RegExp(r'^\[[^\]]*\] /path/to:123: warning: warning message\n$')),
      );
      expect(verboseLogger.hadErrorOutput, isFalse);
    });
  });
}
