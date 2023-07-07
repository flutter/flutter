// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:mime/mime.dart';
import 'package:test/test.dart';

void _writeInChunks(
    List<int> data, int chunkSize, StreamController<List<int>> controller) {
  if (chunkSize == -1) chunkSize = data.length;

  for (var pos = 0; pos < data.length; pos += chunkSize) {
    var remaining = data.length - pos;
    var writeLength = min(chunkSize, remaining);
    controller.add(data.sublist(pos, pos + writeLength));
  }
  controller.close();
}

enum TestMode { immediateListen, delayListen, pauseResume }

void _runParseTest(
  String message,
  String boundary,
  TestMode mode, [
  List<Map>? expectedHeaders,
  List<String?>? expectedParts,
  bool expectError = false,
]) {
  Future testWrite(List<int> data, [int chunkSize = -1]) {
    var controller = StreamController<List<int>>(sync: true);

    var stream =
        controller.stream.transform(MimeMultipartTransformer(boundary));
    var i = 0;
    var completer = Completer();
    var futures = <Future>[];
    stream.listen((multipart) {
      var part = i++;
      if (expectedHeaders != null) {
        expect(multipart.headers, equals(expectedHeaders[part]));
      }
      switch (mode) {
        case TestMode.immediateListen:
          futures.add(multipart.fold<List<int>>(
              [], (buffer, data) => buffer..addAll(data)).then((data) {
            if (expectedParts?[part] != null) {
              expect(data, equals(expectedParts?[part]!.codeUnits));
            }
          }));
          break;

        case TestMode.delayListen:
          futures.add(
            Future(
              () => multipart.fold<List<int>>(
                [],
                (buffer, data) => buffer..addAll(data),
              ).then(
                (data) {
                  if (expectedParts?[part] != null) {
                    expect(data, equals(expectedParts?[part]!.codeUnits));
                  }
                },
              ),
            ),
          );
          break;

        case TestMode.pauseResume:
          var completer = Completer();
          futures.add(completer.future);
          var buffer = [];
          late StreamSubscription subscription;
          subscription = multipart.listen((data) {
            buffer.addAll(data);
            subscription.pause();
            Future(() => subscription.resume());
          }, onDone: () {
            if (expectedParts?[part] != null) {
              expect(buffer, equals(expectedParts?[part]!.codeUnits));
            }
            completer.complete();
          });
          addTearDown(subscription.cancel);
          break;
      }
    }, onError: (Object error) {
      if (!expectError) throw error;
    }, onDone: () {
      if (expectedParts != null) {
        expect(i, equals(expectedParts.length));
      }
      Future.wait(futures).then(completer.complete);
    });

    _writeInChunks(data, chunkSize, controller);

    return completer.future;
  }

  Future testFirstPartOnly(List<int> data, [int chunkSize = -1]) {
    var completer = Completer();
    var controller = StreamController<List<int>>(sync: true);

    var stream =
        controller.stream.transform(MimeMultipartTransformer(boundary));

    stream.first.then((multipart) {
      if (expectedHeaders != null) {
        expect(multipart.headers, equals(expectedHeaders[0]));
      }
      return multipart.fold<List<int>>([], (b, d) => b..addAll(d)).then(
        (data) {
          if (expectedParts != null && expectedParts[0] != null) {
            expect(data, equals(expectedParts[0]!.codeUnits));
          }
        },
      );
    }).then((_) {
      completer.complete();
    });

    _writeInChunks(data, chunkSize, controller);

    return completer.future;
  }

  Future testCompletePartAfterCancel(List<int> data, int parts,
      [int chunkSize = -1]) {
    var completer = Completer();
    var controller = StreamController<List<int>>(sync: true);
    var stream =
        controller.stream.transform(MimeMultipartTransformer(boundary));
    late StreamSubscription subscription;
    var i = 0;
    var futures = <Future>[];
    subscription = stream.listen((multipart) {
      var partIndex = i;

      if (partIndex >= parts) {
        throw StateError('Expected no more parts, but got one.');
      }

      if (expectedHeaders != null) {
        expect(multipart.headers, equals(expectedHeaders[partIndex]));
      }
      futures.add(
          multipart.fold<List<int>>([], (b, d) => b..addAll(d)).then((data) {
        if (expectedParts != null && expectedParts[partIndex] != null) {
          expect(data, equals(expectedParts[partIndex]!.codeUnits));
        }
      }));

      if (partIndex == (parts - 1)) {
        subscription.cancel();
        Future.wait(futures).then(completer.complete);
      }
      i++;
    });

    _writeInChunks(data, chunkSize, controller);

    return completer.future;
  }

  // Test parsing the data three times delivering the data in
  // different chunks.
  var data = message.codeUnits;
  test('test', () {
    expect(
        Future.wait([
          testWrite(data),
          testWrite(data, 10),
          testWrite(data, 2),
          testWrite(data, 1),
        ]),
        completes);
  });

  if (expectedParts!.isNotEmpty) {
    test('test-first-part-only', () {
      expect(
          Future.wait([
            testFirstPartOnly(data),
            testFirstPartOnly(data, 10),
            testFirstPartOnly(data, 2),
            testFirstPartOnly(data, 1),
          ]),
          completes);
    });

    test('test-n-parts-only', () {
      var numPartsExpected = expectedParts.length - 1;
      if (numPartsExpected == 0) numPartsExpected = 1;

      expect(
          Future.wait([
            testCompletePartAfterCancel(data, numPartsExpected),
            testCompletePartAfterCancel(data, numPartsExpected, 10),
            testCompletePartAfterCancel(data, numPartsExpected, 2),
            testCompletePartAfterCancel(data, numPartsExpected, 1),
          ]),
          completes);
    });
  }
}

void _testParse(String message, String boundary,
    [List<Map>? expectedHeaders,
    List<String?>? expectedParts,
    bool expectError = false]) {
  _runParseTest(message, boundary, TestMode.immediateListen, expectedHeaders,
      expectedParts, expectError);
  _runParseTest(message, boundary, TestMode.delayListen, expectedHeaders,
      expectedParts, expectError);
  _runParseTest(message, boundary, TestMode.pauseResume, expectedHeaders,
      expectedParts, expectError);
}

void _testParseValid() {
  // Empty message from Chrome form post.
  var message = '------WebKitFormBoundaryU3FBruSkJKG0Yor1--\r\n';
  _testParse(message, '----WebKitFormBoundaryU3FBruSkJKG0Yor1', [], []);

  // Sample from Wikipedia.
  message = '''
This is a message with multiple parts in MIME format.\r
--frontier\r
Content-Type: text/plain\r
\r
This is the body of the message.\r
--frontier\r
Content-Type: application/octet-stream\r
Content-Transfer-Encoding: base64\r
\r
PGh0bWw+CiAgPGhlYWQ+CiAgPC9oZWFkPgogIDxib2R5PgogICAgPHA+VGhpcyBpcyB0aGUg
Ym9keSBvZiB0aGUgbWVzc2FnZS48L3A+CiAgPC9ib2R5Pgo8L2h0bWw+Cg=\r
--frontier--\r\n''';
  var headers1 = <String, String>{'content-type': 'text/plain'};
  var headers2 = <String, String>{
    'content-type': 'application/octet-stream',
    'content-transfer-encoding': 'base64'
  };
  var body1 = 'This is the body of the message.';
  var body2 = '''
PGh0bWw+CiAgPGhlYWQ+CiAgPC9oZWFkPgogIDxib2R5PgogICAgPHA+VGhpcyBpcyB0aGUg
Ym9keSBvZiB0aGUgbWVzc2FnZS48L3A+CiAgPC9ib2R5Pgo8L2h0bWw+Cg=''';
  _testParse(message, 'frontier', [headers1, headers2], [body1, body2]);

  // Sample from HTML 4.01 Specification.
  message = '''
\r\n--AaB03x\r
Content-Disposition: form-data; name="submit-name"\r
\r
Larry\r
--AaB03x\r
Content-Disposition: form-data; name="files"; filename="file1.txt"\r
Content-Type: text/plain\r
\r
... contents of file1.txt ...\r
--AaB03x--\r\n''';
  headers1 = <String, String>{
    'content-disposition': 'form-data; name="submit-name"'
  };
  headers2 = <String, String>{
    'content-type': 'text/plain',
    'content-disposition': 'form-data; name="files"; filename="file1.txt"'
  };
  body1 = 'Larry';
  body2 = '... contents of file1.txt ...';
  _testParse(message, 'AaB03x', [headers1, headers2], [body1, body2]);

  // Longer form from submitting the following from Chrome.
  //
  // <html>
  // <body>
  // <FORM action="http://127.0.0.1:1234/"
  //     enctype="multipart/form-data"
  //     method='post'>
  //  <P>
  //  Text: <INPUT type='text' name='text_input'>
  //  Password: <INPUT type='password' name='password_input'>
  //  Checkbox: <INPUT type='checkbox' name='checkbox_input'>
  //  Radio: <INPUT type='radio' name='radio_input'>
  //  Send <INPUT type='submit'>
  //  </P>
  // </FORM>
  // </body>
  // </html>

  message = '''
\r\n------WebKitFormBoundaryQ3cgYAmGRF8yOeYB\r
Content-Disposition: form-data; name="text_input"\r
\r
text\r
------WebKitFormBoundaryQ3cgYAmGRF8yOeYB\r
Content-Disposition: form-data; name="password_input"\r
\r
password\r
------WebKitFormBoundaryQ3cgYAmGRF8yOeYB\r
Content-Disposition: form-data; name="checkbox_input"\r
\r
on\r
------WebKitFormBoundaryQ3cgYAmGRF8yOeYB\r
Content-Disposition: form-data; name="radio_input"\r
\r
on\r
------WebKitFormBoundaryQ3cgYAmGRF8yOeYB--\r\n''';
  headers1 = <String, String>{
    'content-disposition': 'form-data; name="text_input"'
  };
  headers2 = <String, String>{
    'content-disposition': 'form-data; name="password_input"'
  };
  var headers3 = <String, String>{
    'content-disposition': 'form-data; name="checkbox_input"'
  };
  var headers4 = <String, String>{
    'content-disposition': 'form-data; name="radio_input"'
  };
  body1 = 'text';
  body2 = 'password';
  var body3 = 'on';
  var body4 = 'on';
  _testParse(message, '----WebKitFormBoundaryQ3cgYAmGRF8yOeYB',
      [headers1, headers2, headers3, headers4], [body1, body2, body3, body4]);

  // Same form from Firefox.
  message = '''
\r\n-----------------------------52284550912143824192005403738\r
Content-Disposition: form-data; name="text_input"\r
\r
text\r
-----------------------------52284550912143824192005403738\r
Content-Disposition: form-data; name="password_input"\r
\r
password\r
-----------------------------52284550912143824192005403738\r
Content-Disposition: form-data; name="checkbox_input"\r
\r
on\r
-----------------------------52284550912143824192005403738\r
Content-Disposition: form-data; name="radio_input"\r
\r
on\r
-----------------------------52284550912143824192005403738--\r\n''';
  _testParse(
      message,
      '---------------------------52284550912143824192005403738',
      [headers1, headers2, headers3, headers4],
      [body1, body2, body3, body4]);

  // And Internet Explorer
  message = '''
\r\n-----------------------------7dc8f38c60326\r
Content-Disposition: form-data; name="text_input"\r
\r
text\r
-----------------------------7dc8f38c60326\r
Content-Disposition: form-data; name="password_input"\r
\r
password\r
-----------------------------7dc8f38c60326\r
Content-Disposition: form-data; name="checkbox_input"\r
\r
on\r
-----------------------------7dc8f38c60326\r
Content-Disposition: form-data; name="radio_input"\r
\r
on\r
-----------------------------7dc8f38c60326--\r\n''';
  _testParse(message, '---------------------------7dc8f38c60326',
      [headers1, headers2, headers3, headers4], [body1, body2, body3, body4]);

  // Test boundary prefix inside prefix and content.
  message = '''
-\r
--\r
--b\r
--bo\r
--bou\r
--boun\r
--bound\r
--bounda\r
--boundar\r
--boundary\r
Content-Type: text/plain\r
\r
-\r
--\r
--b\r
--bo\r
--bou\r
--boun\r
--bound\r\r
--bounda\r\r\r
--boundar\r\r\r\r
--boundary\r
Content-Type: text/plain\r
\r
--boundar\r
--bounda\r
--bound\r
--boun\r
--bou\r
--bo\r
--b\r\r\r\r
--\r\r\r
-\r\r
--boundary--\r\n''';
  var headers = <String, String>{'content-type': 'text/plain'};
  body1 = '''
-\r
--\r
--b\r
--bo\r
--bou\r
--boun\r
--bound\r\r
--bounda\r\r\r
--boundar\r\r\r''';
  body2 = '''
--boundar\r
--bounda\r
--bound\r
--boun\r
--bou\r
--bo\r
--b\r\r\r\r
--\r\r\r
-\r''';
  _testParse(message, 'boundary', [headers, headers], [body1, body2]);

  // Without initial CRLF.
  message = '''
--xxx\r
\r
\r
Body 1\r
--xxx\r
\r
\r
Body2\r
--xxx--\r\n''';
  _testParse(message, 'xxx', null, ['\r\nBody 1', '\r\nBody2']);
}

void _testParseInvalid() {
  // Missing end boundary.
  var message = '''
\r
--xxx\r
\r
\r
Body 1\r
--xxx\r
\r
\r
Body2\r
--xxx\r\n''';
  _testParse(message, 'xxx', null, [null, null], true);
}

void main() {
  _testParseValid();
  _testParseInvalid();
}
