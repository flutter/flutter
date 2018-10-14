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
}
