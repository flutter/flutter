// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')

import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  late Directory tempDir;
  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('http_test_');
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  test('with a file from disk', () async {
    var filePath = path.join(tempDir.path, 'test-file');
    File(filePath).writeAsStringSync('hello');
    var file = await http.MultipartFile.fromPath('file', filePath);
    var request = http.MultipartRequest('POST', dummyUrl);
    request.files.add(file);

    expect(request, bodyMatches('''
        --{{boundary}}
        content-type: application/octet-stream
        content-disposition: form-data; name="file"; filename="test-file"

        hello
        --{{boundary}}--
      '''));
  });
}
