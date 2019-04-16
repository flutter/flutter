// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_devicelab/framework/utils.dart';

import 'common.dart';

void main() {
  group('grep', () {
    test('greps lines', () {
      expect(grep('b', from: 'ab\ncd\nba'), <String>['ab', 'ba']);
    });

    test('understands RegExp', () {
      expect(grep(RegExp('^b'), from: 'ab\nba'), <String>['ba']);
    });
  });

  group('parse service information', () {
    test('parse service uri', () {
      final String badOutput = 'No uri here';
      final String sampleOutput = 'An Observatory debugger and profiler on '
        'Pixel 3 XL is available at: http://127.0.0.1:9090/LpjUpsdEjqI=/';
      expect(parseServiceUri(sampleOutput),
          Uri.parse('http://127.0.0.1:9090/LpjUpsdEjqI=/'));
      expect(parseServiceUri(badOutput), null);
    });

    test('parse service port', () {
      final String badOutput = 'No uri here';
      final String sampleOutput = 'An Observatory debugger and profiler on '
        'Pixel 3 XL is available at: http://127.0.0.1:9090/LpjUpsdEjqI=/';
      expect(parseServicePort(sampleOutput), 9090);
      expect(parseServicePort(badOutput), null);
    });

  });
}
