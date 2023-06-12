// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:test/test.dart';

/// A dummy URL for constructing requests that won't be sent.
Uri get dummyUrl => Uri.http('dart.dev', '');

/// Removes eight spaces of leading indentation from a multiline string.
///
/// Note that this is very sensitive to how the literals are styled. They should
/// be:
///     '''
///     Text starts on own line. Lines up with subsequent lines.
///     Lines are indented exactly 8 characters from the left margin.
///     Close is on the same line.'''
///
/// This does nothing if text is only a single line.
// TODO(nweiz): Make this auto-detect the indentation level from the first
// non-whitespace line.
String cleanUpLiteral(String text) {
  var lines = text.split('\n');
  if (lines.length <= 1) return text;

  for (var j = 0; j < lines.length; j++) {
    if (lines[j].length > 8) {
      lines[j] = lines[j].substring(8, lines[j].length);
    } else {
      lines[j] = '';
    }
  }

  return lines.join('\n');
}

/// A matcher that matches JSON that parses to a value that matches the inner
/// matcher.
Matcher parse(Matcher matcher) => _Parse(matcher);

class _Parse extends Matcher {
  final Matcher _matcher;

  _Parse(this._matcher);

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is String) {
      dynamic parsed;
      try {
        parsed = json.decode(item);
      } catch (e) {
        return false;
      }

      return _matcher.matches(parsed, matchState);
    }
    return false;
  }

  @override
  Description describe(Description description) =>
      description.add('parses to a value that ').addDescriptionOf(_matcher);
}

/// A matcher that validates the body of a multipart request after finalization.
///
/// The string "{{boundary}}" in [pattern] will be replaced by the boundary
/// string for the request, and LF newlines will be replaced with CRLF.
/// Indentation will be normalized.
Matcher bodyMatches(String pattern) => _BodyMatches(pattern);

class _BodyMatches extends Matcher {
  final String _pattern;

  _BodyMatches(this._pattern);

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is http.MultipartRequest) {
      return completes.matches(_checks(item), matchState);
    }

    return false;
  }

  Future<void> _checks(http.MultipartRequest item) async {
    var bodyBytes = await item.finalize().toBytes();
    var body = utf8.decode(bodyBytes);
    var contentType = MediaType.parse(item.headers['content-type']!);
    var boundary = contentType.parameters['boundary']!;
    var expected = cleanUpLiteral(_pattern)
        .replaceAll('\n', '\r\n')
        .replaceAll('{{boundary}}', boundary);

    expect(body, equals(expected));
    expect(item.contentLength, equals(bodyBytes.length));
  }

  @override
  Description describe(Description description) =>
      description.add('has a body that matches "$_pattern"');
}

/// A matcher that matches function or future that throws a
/// [http.ClientException] with the given [message].
///
/// [message] can be a String or a [Matcher].
Matcher throwsClientException([String? message]) {
  var exception = isA<http.ClientException>();
  if (message != null) {
    exception = exception.having((e) => e.message, 'message', message);
  }
  return throwsA(exception);
}

/// Spawn an isolate in the test runner with an http server.
///
/// The server isolate will be killed on teardown.
Future<Uri> startServer() async {
  final channel = spawnHybridUri(Uri(path: '/test/stub_server.dart'));
  final port = await channel.stream.first as int;
  return Uri.http('localhost:$port', '');
}
