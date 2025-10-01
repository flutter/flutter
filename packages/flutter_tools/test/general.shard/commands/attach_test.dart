// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/commands/attach.dart';

import '../../src/common.dart';

void main() {
  testWithoutContext('streamWithCallbackOnFirstItem only calls the callback once', () async {
    var calledTimes = 0;
    final Stream<int> stream = Stream.fromIterable([1, 2, 3]);
    final Stream<int> newStream = streamWithCallbackOnFirstItem(stream, () {
      calledTimes++;
    });
    await newStream.drain<void>();
    expect(calledTimes, 1);
  });
}
