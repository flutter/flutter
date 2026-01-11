// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer' as developer;

import 'package:flutter_test/flutter_test.dart';

Future<bool> hasVmServiceEnabled() async {
  final developer.ServiceProtocolInfo info = await developer.Service.getInfo();
  final result = info.serverUri != null;
  if (!result) {
    // ignore: avoid_print
    print('Run test suite with --enable-vmservice to enable this test.');
  }
  return result;
}
