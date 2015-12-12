// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:mojo/core.dart';

// Helper class to drain the contents of a mojo data pipe to a file.
class PipeToFile {
  MojoDataPipeConsumer _consumer;
  MojoEventSubscription _events;
  IOSink _outputStream;

  PipeToFile(this._consumer, String outputPath) {
    _events = new MojoEventSubscription(_consumer.handle);
    _outputStream = new File(outputPath).openWrite();
  }

  Future<int> _doRead() async {
    ByteData thisRead = _consumer.beginRead();
    if (thisRead == null) {
      throw 'Data pipe beginRead failed: ${_consumer.status}';
    }
    // TODO(mpcomplete): Should I worry about the _eventStream listen callback
    // being invoked again before this completes?
    await _outputStream.add(thisRead.buffer.asUint8List());
    return _consumer.endRead(thisRead.lengthInBytes);
  }

  Future<int> drain() {
    Completer<int> completer = new Completer();
    _events.subscribe((int signal) {
      (() async {
        if (MojoHandleSignals.isReadable(signal)) {
          int result = await _doRead();
          if (result != MojoResult.kOk) {
            _events.close();
            _events = null;
            _outputStream.close();
            completer.complete(result);
          } else {
            _events.enableReadEvents();
          }
        } else if (MojoHandleSignals.isPeerClosed(signal)) {
          _events.close();
          _events = null;
          _outputStream.close();
          completer.complete(MojoResult.kOk);
        } else {
          throw 'Unexpected handle event: ${MojoHandleSignals.string(signal)}';
        }
      })();
    });
    return completer.future;
  }

  static Future<int> copyToFile(MojoDataPipeConsumer consumer, String outputPath) {
    PipeToFile drainer = new PipeToFile(consumer, outputPath);
    return drainer.drain();
  }
}
