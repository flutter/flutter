// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
    });

    testUsingContext('similar issues URL with network failure', () async {
      final GitHubTemplateCreator creator = GitHubTemplateCreator();
      expect(
        await creator.toolCrashSimilarIssuesGitHubURL('this is a 100% error'),
        'https://github.com/flutter/flutter/issues?q=is%3Aissue+this+is+a+100%25+error'
      );
    }, overrides: <Type, Generator>{
      HttpClientFactory: () => () => FakeHttpClient(),
    });

    testUsingContext('new issue template URL', () async {
      final GitHubTemplateCreator creator = GitHubTemplateCreator();
      const String command = 'flutter test';
      const String errorString = 'this is a 100% error';
      const String exception = 'failing to succeed!!!';
      final StackTrace stackTrace = StackTrace.fromString('trace');
      const String doctorText = ' [✓] Flutter (Channel report';

      expect(
        await creator.toolCrashIssueTemplateGitHubURL(command, errorString, exception, stackTrace, doctorText),
        _kShortURL
      );
    }, overrides: <Type, Generator>{
      HttpClientFactory: () => () => SuccessShortenURLFakeHttpClient(),
    });

    testUsingContext('new issue template URL with network failure', () async {
      final GitHubTemplateCreator creator = GitHubTemplateCreator();
      const String command = 'flutter test';
      const String errorString = 'this is a 100% error';
      const String exception = 'failing to succeed!!!';
      final StackTrace stackTrace = StackTrace.fromString('trace');
      const String doctorText = ' [✓] Flutter (Channel report';

      expect(
        await creator.toolCrashIssueTemplateGitHubURL(command, errorString, exception, stackTrace, doctorText),
        'https://github.com/flutter/flutter/issues/new?title=%5Btool_crash%5D+this+is+a+100%25+error&body=%23%'
          '23+Command%0A++%60%60%60%0A++flutter+test%0A++%60%60%60%0A%0A++%23%23+Steps+to+Reproduce%0A++1.+...'
          '%0A++2.+...%0A++3.+...%0A%0A++%23%23+Logs%0A++failing+to+succeed%21%21%21%0A++%60%60%60%0A++trace%0A'
          '++%60%60%60%0A++%60%60%60%0A+++%5B%E2%9C%93%5D+Flutter+%28Channel+report%0A++%60%60%60%0A%0A++%23%23'
          '+Flutter+Application+Metadata%0A++%2A%2AVersion%2A%2A%3A+null%0A%2A%2AMaterial%2A%2A%3A+false%0A%2A'
          '%2AAndroid+X%2A%2A%3A+false%0A%2A%2AModule%2A%2A%3A+false%0A%2A%2APlugin%2A%2A%3A+false%0A%2A%2AAndr'
          'oid+package%2A%2A%3A+null%0A%2A%2AiOS+bundle+identifier%2A%2A%3A+null%0A%0A++&labels=tool%2Csevere%3'
          'A+crash'
      );
    }, overrides: <Type, Generator>{
      HttpClientFactory: () => () => FakeHttpClient(),
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
