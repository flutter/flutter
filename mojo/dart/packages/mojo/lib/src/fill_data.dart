// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of core;

class DataPipeFiller {
  final MojoDataPipeProducer _producer;
  final ByteData _data;
  MojoEventSubscription _eventSubscription;
  int _dataPosition;

  DataPipeFiller(this._producer, this._data) {
    _eventSubscription = new MojoEventSubscription(_producer.handle);
    _dataPosition = 0;
  }

  MojoResult _doWrite() {
    ByteData view = new ByteData.view(
        _data.buffer, _dataPosition, _data.lengthInBytes - _dataPosition);
    int written = _producer.write(view);
    if (!_producer.status.isOk) {
      throw 'Data pipe beginWrite failed: ${_producer.status}';
    }
    _dataPosition += written;
    return _producer.status;
  }

  void fill() {
    _eventSubscription.enableWriteEvents();
    _eventSubscription.subscribe((List<int> event) {
      var mojoSignals = new MojoHandleSignals(event[1]);
      if (mojoSignals.isWritable) {
        MojoResult result = _doWrite();
        if (_dataPosition >= _data.lengthInBytes || !result.isOk) {
          _eventSubscription.close();
          _eventSubscription = null;
        }
      } else if (mojoSignals.isPeerClosed) {
        _eventSubscription.close();
        _eventSubscription = null;
      } else {
        throw 'Unexpected handle event: $mojoSignals';
      }
    });
  }

  static void fillHandle(MojoDataPipeProducer producer, ByteData data) {
    var filler = new DataPipeFiller(producer, data);
    filler.fill();
  }
}
