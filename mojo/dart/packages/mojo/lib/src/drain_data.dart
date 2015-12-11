// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of core;

class DataPipeDrainer {
  MojoDataPipeConsumer _consumer;
  MojoEventSubscription _eventSubscription;
  List<ByteData> _dataList = new List<ByteData>();
  int _dataSize = 0;

  DataPipeDrainer(MojoDataPipeConsumer consumer)
      : _consumer = consumer,
        _eventSubscription = new MojoEventSubscription(consumer.handle);

  ByteData _copy(ByteData byteData) => new ByteData.view(
      new Uint8List.fromList(byteData.buffer.asUint8List()).buffer);

  int _doRead() {
    ByteData thisRead = _consumer.beginRead();
    if (thisRead == null) {
      throw 'Data pipe beginRead failed: ${_consumer}';
    }
    _dataList.add(_copy(thisRead));
    _dataSize += thisRead.lengthInBytes;
    return _consumer.endRead(thisRead.lengthInBytes);
  }

  ByteData _concatData() {
    var data = new ByteData(_dataSize);
    int end = 0;
    for (var chunk in _dataList) {
      data.buffer
          .asUint8List()
          .setRange(end, end + chunk.lengthInBytes, chunk.buffer.asUint8List());
      end += chunk.lengthInBytes;
    }
    return data;
  }

  Future<ByteData> drain() {
    var completer = new Completer();
    _eventSubscription.subscribe((int mojoSignals) {
      if (MojoHandleSignals.isReadable(mojoSignals)) {
        int result = _doRead();
        if (result != MojoResult.kOk) {
          _eventSubscription.close();
          _eventSubscription = null;
          completer.complete(_concatData());
        } else {
          _eventSubscription.enableReadEvents();
        }
      } else if (MojoHandleSignals.isPeerClosed(mojoSignals)) {
        _eventSubscription.close();
        _eventSubscription = null;
        completer.complete(_concatData());
      } else {
        String signals = MojoHandleSignals.string(mojoSignals);
        throw 'Unexpected handle event: $signals';
      }
    });
    return completer.future;
  }

  static Future<ByteData> drainHandle(MojoDataPipeConsumer consumer) {
    var drainer = new DataPipeDrainer(consumer);
    return drainer.drain();
  }
}
