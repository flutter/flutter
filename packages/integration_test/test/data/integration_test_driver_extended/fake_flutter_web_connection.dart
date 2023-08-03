// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/flutter_driver.dart';
import 'package:webdriver/sync_io.dart';

class FakeFlutterWebConnection implements FlutterWebConnection {
  @override
  bool supportsTimelineAction = false;

  @override
  Future<void> close() async {}

  @override
  Stream<LogEntry> get logs => throw UnimplementedError();

  @override
  Future<List<int>> screenshot() {
    throw UnimplementedError();
  }

  Object? fakeResponse;
  Error? communicationError;

  @override
  Future<Object?> sendCommand(String script, Duration? duration) async {
    if (communicationError != null) {
      throw communicationError!;
    }
    return fakeResponse;
  }
}
