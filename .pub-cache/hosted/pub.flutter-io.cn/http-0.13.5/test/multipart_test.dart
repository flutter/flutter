// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:http/src/boundary_characters.dart';
import 'package:http_parser/http_parser.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  test('empty', () {
    var request = http.MultipartRequest('POST', dummyUrl);
    expect(request, bodyMatches('''
        --{{boundary}}--
        '''));
  });

  test('boundary characters', () {
    var testBoundary = String.fromCharCodes(boundaryCharacters);
    var contentType = MediaType.parse('text/plain; boundary=$testBoundary');
    var boundary = contentType.parameters['boundary'];
    expect(boundary, testBoundary);
  });

  test('with fields and files', () {
    var request = http.MultipartRequest('POST', dummyUrl);
    request.fields['field1'] = 'value1';
    request.fields['field2'] = 'value2';
    request.files.add(http.MultipartFile.fromString('file1', 'contents1',
        filename: 'filename1.txt'));
    request.files.add(http.MultipartFile.fromString('file2', 'contents2'));

    expect(request, bodyMatches('''
        --{{boundary}}
        content-disposition: form-data; name="field1"

        value1
        --{{boundary}}
        content-disposition: form-data; name="field2"

        value2
        --{{boundary}}
        content-type: text/plain; charset=utf-8
        content-disposition: form-data; name="file1"; filename="filename1.txt"

        contents1
        --{{boundary}}
        content-type: text/plain; charset=utf-8
        content-disposition: form-data; name="file2"

        contents2
        --{{boundary}}--
        '''));
  });

  test('with a unicode field name', () {
    var request = http.MultipartRequest('POST', dummyUrl);
    request.fields['fïēld'] = 'value';

    expect(request, bodyMatches('''
        --{{boundary}}
        content-disposition: form-data; name="fïēld"

        value
        --{{boundary}}--
        '''));
  });

  test('with a field name with newlines', () {
    var request = http.MultipartRequest('POST', dummyUrl);
    request.fields['foo\nbar\rbaz\r\nbang'] = 'value';

    expect(request, bodyMatches('''
        --{{boundary}}
        content-disposition: form-data; name="foo%0D%0Abar%0D%0Abaz%0D%0Abang"

        value
        --{{boundary}}--
        '''));
  });

  test('with a field name with a quote', () {
    var request = http.MultipartRequest('POST', dummyUrl);
    request.fields['foo"bar'] = 'value';

    expect(request, bodyMatches('''
        --{{boundary}}
        content-disposition: form-data; name="foo%22bar"

        value
        --{{boundary}}--
        '''));
  });

  test('with a unicode field value', () {
    var request = http.MultipartRequest('POST', dummyUrl);
    request.fields['field'] = 'vⱥlūe';

    expect(request, bodyMatches('''
        --{{boundary}}
        content-disposition: form-data; name="field"
        content-type: text/plain; charset=utf-8
        content-transfer-encoding: binary

        vⱥlūe
        --{{boundary}}--
        '''));
  });

  test('with a unicode filename', () {
    var request = http.MultipartRequest('POST', dummyUrl);
    request.files.add(http.MultipartFile.fromString('file', 'contents',
        filename: 'fïlēname.txt'));

    expect(request, bodyMatches('''
        --{{boundary}}
        content-type: text/plain; charset=utf-8
        content-disposition: form-data; name="file"; filename="fïlēname.txt"

        contents
        --{{boundary}}--
        '''));
  });

  test('with a filename with newlines', () {
    var request = http.MultipartRequest('POST', dummyUrl);
    request.files.add(http.MultipartFile.fromString('file', 'contents',
        filename: 'foo\nbar\rbaz\r\nbang'));

    expect(request, bodyMatches('''
        --{{boundary}}
        content-type: text/plain; charset=utf-8
        content-disposition: form-data; name="file"; filename="foo%0D%0Abar%0D%0Abaz%0D%0Abang"

        contents
        --{{boundary}}--
        '''));
  });

  test('with a filename with a quote', () {
    var request = http.MultipartRequest('POST', dummyUrl);
    request.files.add(
        http.MultipartFile.fromString('file', 'contents', filename: 'foo"bar'));

    expect(request, bodyMatches('''
        --{{boundary}}
        content-type: text/plain; charset=utf-8
        content-disposition: form-data; name="file"; filename="foo%22bar"

        contents
        --{{boundary}}--
        '''));
  });

  test('with a string file with a content-type but no charset', () {
    var request = http.MultipartRequest('POST', dummyUrl);
    var file = http.MultipartFile.fromString('file', '{"hello": "world"}',
        contentType: MediaType('application', 'json'));
    request.files.add(file);

    expect(request, bodyMatches('''
        --{{boundary}}
        content-type: application/json; charset=utf-8
        content-disposition: form-data; name="file"

        {"hello": "world"}
        --{{boundary}}--
        '''));
  });

  test('with a file with a iso-8859-1 body', () {
    var request = http.MultipartRequest('POST', dummyUrl);
    // "Ã¥" encoded as ISO-8859-1 and then read as UTF-8 results in "å".
    var file = http.MultipartFile.fromString('file', 'non-ascii: "Ã¥"',
        contentType: MediaType('text', 'plain', {'charset': 'iso-8859-1'}));
    request.files.add(file);

    expect(request, bodyMatches('''
        --{{boundary}}
        content-type: text/plain; charset=iso-8859-1
        content-disposition: form-data; name="file"

        non-ascii: "å"
        --{{boundary}}--
        '''));
  });

  test('with a stream file', () {
    var request = http.MultipartRequest('POST', dummyUrl);
    var controller = StreamController<List<int>>(sync: true);
    request.files.add(http.MultipartFile('file', controller.stream, 5));

    expect(request, bodyMatches('''
        --{{boundary}}
        content-type: application/octet-stream
        content-disposition: form-data; name="file"

        hello
        --{{boundary}}--
        '''));

    controller
      ..add([104, 101, 108, 108, 111])
      ..close();
  });

  test('with an empty stream file', () {
    var request = http.MultipartRequest('POST', dummyUrl);
    var controller = StreamController<List<int>>(sync: true);
    request.files.add(http.MultipartFile('file', controller.stream, 0));

    expect(request, bodyMatches('''
        --{{boundary}}
        content-type: application/octet-stream
        content-disposition: form-data; name="file"


        --{{boundary}}--
        '''));

    controller.close();
  });

  test('with a byte file', () {
    var request = http.MultipartRequest('POST', dummyUrl);
    var file = http.MultipartFile.fromBytes('file', [104, 101, 108, 108, 111]);
    request.files.add(file);

    expect(request, bodyMatches('''
        --{{boundary}}
        content-type: application/octet-stream
        content-disposition: form-data; name="file"

        hello
        --{{boundary}}--
        '''));
  });

  test('with a file that has an error', () async {
    var file = http.MultipartFile(
        'file', Future<List<int>>.error('error').asStream(), 1);
    var request = http.MultipartRequest('POST', dummyUrl)..files.add(file);
    expect(request.finalize().drain<void>(), throwsA('error'));
  });
}
