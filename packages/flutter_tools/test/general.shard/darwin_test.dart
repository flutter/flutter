// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/targets/darwin.dart';
import 'package:flutter_tools/src/darwin/darwin.dart';
import 'package:test/fake.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group('FlutterDarwinPlatform', () {
    group('iOS', () {
      testWithoutContext('deployment target is 13.0', () {
        expect(FlutterDarwinPlatform.ios.deploymentTarget().toString(), '13.0');
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
    });
    group('macOS', () {
      testWithoutContext('deployment target is 10.15', () {
        expect(FlutterDarwinPlatform.macos.deploymentTarget().toString(), '10.15');
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
    });
  });

  group('print Xcode', () {
    late FakeStdio fakeStdio;

    setUp(() {
      fakeStdio = FakeStdio();
    });

    testUsingContext('Warning with no filePath/lineNumber', () {
      printXcodeWarning('warning message');
      expect(fakeStdio.stderrBuffer.toString(), startsWith('warning: warning message\n'));
    }, overrides: <Type, Generator>{Stdio: () => fakeStdio});

    testUsingContext('Warning with filePath/lineNumber', () {
      printXcodeWarning('warning message', filePath: '/path/to', lineNumber: 123);
      expect(
        fakeStdio.stderrBuffer.toString(),
        startsWith('/path/to:123: warning: warning message\n'),
      );
    }, overrides: <Type, Generator>{Stdio: () => fakeStdio});

    testUsingContext('Warning with lineNumber but no filePath', () {
      printXcodeWarning('warning message', lineNumber: 123);
      expect(fakeStdio.stderrBuffer.toString(), startsWith('warning: warning message\n'));
    }, overrides: <Type, Generator>{Stdio: () => fakeStdio});

    testUsingContext('Error with no filePath/lineNumber', () {
      printXcodeError('error message');
      expect(fakeStdio.stderrBuffer.toString(), startsWith('error: error message\n'));
    }, overrides: <Type, Generator>{Stdio: () => fakeStdio});

    testUsingContext('Error with filePath/lineNumber', () {
      printXcodeError('error message', filePath: '/path/to', lineNumber: 123);
      expect(fakeStdio.stderrBuffer.toString(), startsWith('/path/to:123: error: error message\n'));
    }, overrides: <Type, Generator>{Stdio: () => fakeStdio});

    testUsingContext('Error with lineNumber but no filePath', () {
      printXcodeError('error message', lineNumber: 123);
      expect(fakeStdio.stderrBuffer.toString(), startsWith('error: error message\n'));
    }, overrides: <Type, Generator>{Stdio: () => fakeStdio});

    testUsingContext('Note with no filePath/lineNumber', () {
      printXcodeNote('note message');
      expect(fakeStdio.stderrBuffer.toString(), startsWith('note: note message\n'));
    }, overrides: <Type, Generator>{Stdio: () => fakeStdio});

    testUsingContext('Note with filePath/lineNumber', () {
      printXcodeNote('note message', filePath: '/path/to', lineNumber: 123);
      expect(fakeStdio.stderrBuffer.toString(), startsWith('/path/to:123: note: note message\n'));
    }, overrides: <Type, Generator>{Stdio: () => fakeStdio});

    testUsingContext('Note with lineNumber but no filePath', () {
      printXcodeNote('note message', lineNumber: 123);
      expect(fakeStdio.stderrBuffer.toString(), startsWith('note: note message\n'));
    }, overrides: <Type, Generator>{Stdio: () => fakeStdio});
  });
}

class FakeStdio extends Fake implements Stdio {
  final stderrBuffer = StringBuffer();

  @override
  void stderrWrite(String message, {void Function(String, dynamic, StackTrace)? fallback}) {
    stderrBuffer.writeln(message);
  }
}
