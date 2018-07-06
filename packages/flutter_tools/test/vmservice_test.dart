// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';

import 'package:flutter_tools/src/vmservice.dart';

import 'src/common.dart';
import 'src/context.dart';

void main() {
  group('VMService', () {
    testUsingContext('fails connection eagerly in the connect() method', () async {
      expect(
        VMService.connect(Uri.parse('http://host.invalid:9999/')),
        throwsToolExit(),
      );
    });
  });
}
