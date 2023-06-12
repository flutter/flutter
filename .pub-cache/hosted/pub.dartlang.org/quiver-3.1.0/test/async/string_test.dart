// Copyright 2013 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:convert' show latin1, utf8;

import 'package:quiver/src/async/string.dart';
import 'package:test/test.dart';

void main() {
  group('byteStreamToString', () {
    test('should decode UTF8 text by default', () {
      var string = '箙、靫';
      var encoded = utf8.encoder.convert(string);
      var data = [encoded.sublist(0, 3), encoded.sublist(3)];
      var stream = Stream<List<int>>.fromIterable(data);
      byteStreamToString(stream).then((decoded) {
        expect(decoded, string);
      });
    });

    test('should decode text with the specified encoding', () {
      var string = 'blåbærgrød';
      var encoded = latin1.encoder.convert(string);
      var data = [encoded.sublist(0, 4), encoded.sublist(4)];
      var stream = Stream<List<int>>.fromIterable(data);
      byteStreamToString(stream, encoding: latin1).then((decoded) {
        expect(decoded, string);
      });
    });
  });
}
