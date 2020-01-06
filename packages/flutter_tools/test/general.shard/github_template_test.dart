// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/net.dart';
import 'package:flutter_tools/src/reporting/github_template.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/testbed.dart';

const String _kShortURL = 'https://www.example.com/short';

void main() {
  group('GitHub template creator', () {
    testUsingContext('similar issues URL', () async {
      final GitHubTemplateCreator creator = GitHubTemplateCreator();
      expect(
        await creator.toolCrashSimilarIssuesGitHubURL('this is a 100% error'),
        _kShortURL
      );
    }, overrides: <Type, Generator>{
      HttpClientFactory: () => () => SuccessShortenURLFakeHttpClient(),
      FileSystem: () => MemoryFileSystem(),
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('similar issues URL with network failure', () async {
      final GitHubTemplateCreator creator = GitHubTemplateCreator();
      expect(
        await creator.toolCrashSimilarIssuesGitHubURL('this is a 100% error'),
        'https://github.com/flutter/flutter/issues?q=is%3Aissue+this+is+a+100%25+error'
      );
    }, overrides: <Type, Generator>{
      HttpClientFactory: () => () => FakeHttpClient(),
      FileSystem: () => MemoryFileSystem(),
      ProcessManager: () => FakeProcessManager.any(),
    });

    group('new issue template URL', () {
      StackTrace stackTrace;
      const String command = 'flutter test';
      const String errorString = 'this is a 100% error';
      const String exception = 'failing to succeed!!!';
      const String doctorText = ' [✓] Flutter (Channel report';
      FileSystem fs;

      setUp(() async {
        stackTrace = StackTrace.fromString('trace');
        fs = MemoryFileSystem();
      });

      testUsingContext('shortened', () async {
        final GitHubTemplateCreator creator = GitHubTemplateCreator();
        expect(
            await creator.toolCrashIssueTemplateGitHubURL(command, errorString, exception, stackTrace, doctorText),
            _kShortURL
        );
      }, overrides: <Type, Generator>{
        HttpClientFactory: () => () => SuccessShortenURLFakeHttpClient(),
        FileSystem: () => MemoryFileSystem(),
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('with network failure', () async {
        final GitHubTemplateCreator creator = GitHubTemplateCreator();
        expect(
            await creator.toolCrashIssueTemplateGitHubURL(command, errorString, exception, stackTrace, doctorText),
            'https://github.com/flutter/flutter/issues/new?title=%5Btool_crash%5D+this+is+a+100%25+error&body=%23%'
                '23+Command%0A%60%60%60%0Aflutter+test%0A%60%60%60%0A%0A%23%23+Steps+to+Reproduce%0A1.+...'
                '%0A2.+...%0A3.+...%0A%0A%23%23+Logs%0Afailing+to+succeed%21%21%21%0A%60%60%60%0Atrace%0A'
                '%60%60%60%0A%60%60%60%0A+%5B%E2%9C%93%5D+Flutter+%28Channel+report%0A%60%60%60%0A%0A%23%23'
                '+Flutter+Application+Metadata%0ANo+pubspec+in+working+directory.%0A&labels=tool%2Csevere%3A+crash'
        );
      }, overrides: <Type, Generator>{
        HttpClientFactory: () => () => FakeHttpClient(),
        FileSystem: () => MemoryFileSystem(),
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('app metadata', () async {
        final GitHubTemplateCreator creator = GitHubTemplateCreator();
        final Directory projectDirectory = fs.currentDirectory;
        final File pluginsFile = projectDirectory.childFile('.flutter-plugins');

        projectDirectory
            .childFile('pubspec.yaml')
            .writeAsStringSync('''
name: failing_app
version: 2.0.1+100
flutter:
  uses-material-design: true
  module:
    androidX: true
    androidPackage: com.example.failing.android
    iosBundleIdentifier: com.example.failing.ios
''');

        pluginsFile
            .writeAsStringSync('''
camera=/fake/pub.dartlang.org/camera-0.5.7+2/
device_info=/fake/pub.dartlang.org/pub.dartlang.org/device_info-0.4.1+4/
        ''');

        final String actualURL = await creator.toolCrashIssueTemplateGitHubURL(command, errorString, exception, stackTrace, doctorText);
        final String actualBody = Uri.parse(actualURL).queryParameters['body'];
        const String expectedBody = '''## Command
```
flutter test
```

## Steps to Reproduce
1. ...
2. ...
3. ...

## Logs
failing to succeed!!!
```
trace
```
```
 [✓] Flutter (Channel report
```

## Flutter Application Metadata
**Version**: 2.0.1+100
**Material**: true
**Android X**: true
**Module**: true
**Plugin**: false
**Android package**: com.example.failing.android
**iOS bundle identifier**: com.example.failing.ios
### Plugins
camera-0.5.7+2
device_info-0.4.1+4

''';

        expect(actualBody, expectedBody);
      }, overrides: <Type, Generator>{
        HttpClientFactory: () => () => FakeHttpClient(),
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });
    });
  });
}


class SuccessFakeHttpHeaders extends FakeHttpHeaders {
  @override
  List<String> operator [](String name) => <String>[_kShortURL];
}

class SuccessFakeHttpClientResponse extends FakeHttpClientResponse {
  @override
  int get statusCode => 201;

  @override
  HttpHeaders get headers {
    return SuccessFakeHttpHeaders();
  }
}

class SuccessFakeHttpClientRequest extends FakeHttpClientRequest {
  @override
  Future<HttpClientResponse> close() async {
    return SuccessFakeHttpClientResponse();
  }
}

class SuccessShortenURLFakeHttpClient extends FakeHttpClient {
  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    return SuccessFakeHttpClientRequest();
  }
}
