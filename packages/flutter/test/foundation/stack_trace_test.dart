// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:test/test.dart';

void main() {
  test('FlutterError.defaultStackFilter', () {
    List<String> filtered = FlutterError.defaultStackFilter(StackTrace.current.toString().trimRight().split('\n')).toList();
    expect(filtered.length, 4);
    expect(filtered[0], matches(r'^#0 +main\.<anonymous closure> \(.*stack_trace_test\.dart:[0-9]+:[0-9]+\)$'));
    expect(filtered[1], matches(r'^#1 +Declarer\.test\.<anonymous closure>\.<<anonymous closure>_async_body>\.<anonymous closure>\.<<anonymous closure>_async_body> \(package:test/.+:[0-9]+:[0-9]+\)$'));
    expect(filtered[2], matches(r'^#[1-9][0-9]+ +Declarer\._runSetUps\.<_runSetUps_async_body> \(package:test/.+:[0-9]+:[0-9]+\)$'));
    expect(filtered[3], matches(r'^\(elided [1-9][0-9]+ frames from package dart:async, package dart:async-patch, and package stack_trace\)$'));
  });

  test('FlutterError.defaultStackFilter (async test body)', () async {
    List<String> filtered = FlutterError.defaultStackFilter(StackTrace.current.toString().trimRight().split('\n')).toList();
    expect(filtered.length, 2);
    expect(filtered[0], matches(r'^#0 +main\.<anonymous closure>\.<<anonymous closure>_async_body> \(.*stack_trace_test\.dart:[0-9]+:[0-9]+\)$'));
    expect(filtered[1], matches(r'^\(elided [1-9][0-9]+ frames from package dart:async and package stack_trace\)$'));
  });
}
