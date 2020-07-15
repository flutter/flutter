// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/device.dart';

/// A fake implementation of the [DeviceLogReader].
class FakeDeviceLogReader extends DeviceLogReader {
  @override
  String get name => 'FakeLogReader';

  StreamController<String> _cachedLinesController;

  final List<String> _lineQueue = <String>[];
  StreamController<String> get _linesController {
    _cachedLinesController ??= StreamController<String>
      .broadcast(onListen: () {
        _lineQueue.forEach(_linesController.add);
        _lineQueue.clear();
     });
    return _cachedLinesController;
  }

  @override
  Stream<String> get logLines => _linesController.stream;

  void addLine(String line) {
    if (_linesController.hasListener) {
      _linesController.add(line);
    } else {
      _lineQueue.add(line);
    }
  }

  @override
  Future<void> dispose() async {
    _lineQueue.clear();
    await _linesController.close();
  }
}
