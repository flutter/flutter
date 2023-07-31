// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Deprecated('Tests deprecated functionality')
library io_sink_impl;

import 'dart:io';

import 'package:async/async.dart';

/// This class isn't used, it's just used to verify that [IOSinkBase] produces a
/// valid implementation of [IOSink].
class IOSinkImpl extends IOSinkBase implements IOSink {
  @override
  void onAdd(List<int> data) {}

  @override
  void onError(Object error, [StackTrace? stackTrace]) {}

  @override
  void onClose() {}

  @override
  Future<void> onFlush() => Future.value();
}
