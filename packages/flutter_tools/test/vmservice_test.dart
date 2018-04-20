// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';

import 'package:flutter_tools/src/base/port_scanner.dart';
import 'package:flutter_tools/src/vmservice.dart';

import 'src/common.dart';
import 'src/context.dart';

void main() {
  group('VMService', () {
    testUsingContext('fails connection eagerly in the connect() method', () async {
      final int port = await const HostPortScanner().findAvailablePort();
      expect(
        VMService.connect(Uri.parse('http://localhost:$port')),
        throwsToolExit(),
      );
    });
  });
}
