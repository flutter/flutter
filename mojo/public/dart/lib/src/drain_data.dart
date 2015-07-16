// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of core;

class DataPipeDrainer {
  MojoDataPipeConsumer _consumer;
  MojoEventStream _eventStream;
  List<ByteData> _dataList;
  int _dataSize;

  DataPipeDrainer(this._consumer) {
    _eventStream = new MojoEventStream(_consumer.handle);
    _dataList = new List();
    _dataSize = 0;
  }

  ByteData _copy(ByteData byteData) =>
      new ByteData.view(
          new Uint8List.fromList(byteData.buffer.asUint8List()).buffer);

  MojoResult _doRead() {
    ByteData thisRead = _consumer.beginRead();
    if (thisRead == null) {
      throw 'Data pipe beginRead failed: ${_consumer.status}';
    }
    _dataList.add(_copy(thisRead));
    _dataSize += thisRead.lengthInBytes;
    return _consumer.endRead(thisRead.lengthInBytes);
  }

  ByteData _concatData() {
    var data = new ByteData(_dataSize);
    int end = 0;
    for (var chunk in _dataList) {
      data.buffer.asUint8List().setRange(
          end, end + chunk.lengthInBytes, chunk.buffer.asUint8List());
      end += chunk.lengthInBytes;
    }
    return data;
  }

  Future<ByteData> drain() {
    var completer = new Completer();
    _eventStream.listen((List<int> event) {
      var mojoSignals = new MojoHandleSignals(event[1]);
      if (mojoSignals.isReadable) {
        var result = _doRead();
        if (!result.isOk) {
          _eventStream.close();
          _eventStream = null;
          completer.complete(_concatData());
        } else {
          _eventStream.enableReadEvents();
        }
      } else if (mojoSignals.isPeerClosed) {
        _eventStream.close();
        _eventStream = null;
        completer.complete(_concatData());
      } else {
        throw 'Unexpected handle event: $mojoSignals';
      }
    });
    return completer.future;
  }

  static Future<ByteData> drainHandle(MojoDataPipeConsumer consumer) {
    var drainer = new DataPipeDrainer(consumer);
    return drainer.drain();
  }
}
