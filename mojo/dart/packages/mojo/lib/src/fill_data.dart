// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of core;

class DataPipeFiller {
  final MojoDataPipeProducer _producer;
  final ByteData _data;
  MojoEventSubscription _eventSubscription;
  int _dataPosition = 0;

  DataPipeFiller(MojoDataPipeProducer producer, ByteData data)
      : _producer = producer,
        _data = data,
        _eventSubscription = new MojoEventSubscription(producer.handle);

  int _doWrite() {
    ByteData view = new ByteData.view(
        _data.buffer, _dataPosition, _data.lengthInBytes - _dataPosition);
    int written = _producer.write(view);
    if (_producer.status != MojoResult.kOk) {
      throw 'Data pipe beginWrite failed: '
          '${MojoResult.string(_producer.status)}';
    }
    _dataPosition += written;
    return _producer.status;
  }

  void fill() {
    _eventSubscription.enableWriteEvents();
    _eventSubscription.subscribe((int mojoSignals) {
      if (MojoHandleSignals.isWritable(mojoSignals)) {
        int result = _doWrite();
        if ((_dataPosition >= _data.lengthInBytes) ||
            (result != MojoResult.kOk)) {
          _eventSubscription.close();
          _eventSubscription = null;
        }
      } else if (MojoHandleSignals.isPeerClosed(mojoSignals)) {
        _eventSubscription.close();
        _eventSubscription = null;
      } else {
        String signals = MojoHandleSignals.string(mojoSignals);
        throw 'Unexpected handle event: $signals';
      }
    });
  }

  static void fillHandle(MojoDataPipeProducer producer, ByteData data) {
    var filler = new DataPipeFiller(producer, data);
    filler.fill();
  }
}
