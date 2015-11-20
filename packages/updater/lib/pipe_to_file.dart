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
  MojoEventSubscription _eventStream;
  IOSink _outputStream;

  PipeToFile(this._consumer, String outputPath) {
    _eventStream = new MojoEventSubscription(_consumer.handle);
    _outputStream = new File(outputPath).openWrite();
  }

  Future<MojoResult> _doRead() async {
    ByteData thisRead = _consumer.beginRead();
    if (thisRead == null) {
      throw 'Data pipe beginRead failed: ${_consumer.status}';
    }
    // TODO(mpcomplete): Should I worry about the _eventStream listen callback
    // being invoked again before this completes?
    await _outputStream.add(thisRead.buffer.asUint8List());
    return _consumer.endRead(thisRead.lengthInBytes);
  }

  Future drain() async {
    Completer completer = new Completer();
    // TODO(mpcomplete): Is it legit to pass an async callback to listen?
    _eventStream.subscribe((List<int> event) async {
      MojoHandleSignals mojoSignals = new MojoHandleSignals(event[1]);
      if (mojoSignals.isReadable) {
        MojoResult result = await _doRead();
        if (!result.isOk) {
          _eventStream.close();
          _eventStream = null;
          _outputStream.close();
          completer.complete(result);
        } else {
          _eventStream.enableReadEvents();
        }
      } else if (mojoSignals.isPeerClosed) {
        _eventStream.close();
        _eventStream = null;
        _outputStream.close();
        completer.complete(MojoResult.OK);
      } else {
        throw 'Unexpected handle event: $mojoSignals';
      }
    });
    return completer.future;
  }

  static Future<MojoResult> copyToFile(MojoDataPipeConsumer consumer, String outputPath) {
    PipeToFile drainer = new PipeToFile(consumer, outputPath);
    return drainer.drain();
  }
}
