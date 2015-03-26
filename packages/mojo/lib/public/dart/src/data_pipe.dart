// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of core;

class MojoDataPipeProducer {
  static const int FLAG_NONE = 0;
  static const int FLAG_ALL_OR_NONE = 1 << 0;

  MojoHandle handle;
  MojoResult status;
  final int elementBytes;

  MojoDataPipeProducer(this.handle,
      [this.status = MojoResult.OK, this.elementBytes = 1]);

  int write(ByteData data, [int numBytes = -1, int flags = 0]) {
    if (handle == null) {
      status = MojoResult.INVALID_ARGUMENT;
      return 0;
    }

    int data_numBytes = (numBytes == -1) ? data.lengthInBytes : numBytes;
    List result =
        MojoDataPipeNatives.MojoWriteData(handle.h, data, data_numBytes, flags);
    if (result == null) {
      status = MojoResult.INVALID_ARGUMENT;
      return 0;
    }

    assert((result is List) && (result.length == 2));
    status = new MojoResult(result[0]);
    return result[1];
  }

  ByteData beginWrite(int bufferBytes, [int flags = 0]) {
    if (handle == null) {
      status = MojoResult.INVALID_ARGUMENT;
      return null;
    }

    List result =
        MojoDataPipeNatives.MojoBeginWriteData(handle.h, bufferBytes, flags);
    if (result == null) {
      status = MojoResult.INVALID_ARGUMENT;
      return null;
    }

    assert((result is List) && (result.length == 2));
    status = new MojoResult(result[0]);
    return result[1];
  }

  MojoResult endWrite(int bytesWritten) {
    if (handle == null) {
      status = MojoResult.INVALID_ARGUMENT;
      return status;
    }
    int result = MojoDataPipeNatives.MojoEndWriteData(handle.h, bytesWritten);
    status = new MojoResult(result);
    return status;
  }

  String toString() => "MojoDataPipeProducer(handle: $handle, status: $status)";
}

class MojoDataPipeConsumer {
  static const int FLAG_NONE = 0;
  static const int FLAG_ALL_OR_NONE = 1 << 0;
  static const int FLAG_DISCARD = 1 << 1;
  static const int FLAG_QUERY = 1 << 2;
  static const int FLAG_PEEK = 1 << 3;

  MojoHandle handle;
  MojoResult status;
  final int elementBytes;

  MojoDataPipeConsumer(this.handle,
      [this.status = MojoResult.OK, this.elementBytes = 1]);

  int read(ByteData data, [int numBytes = -1, int flags = 0]) {
    if (handle == null) {
      status = MojoResult.INVALID_ARGUMENT;
      return 0;
    }

    int data_numBytes = (numBytes == -1) ? data.lengthInBytes : numBytes;
    List result =
        MojoDataPipeNatives.MojoReadData(handle.h, data, data_numBytes, flags);
    if (result == null) {
      status = MojoResult.INVALID_ARGUMENT;
      return 0;
    }
    assert((result is List) && (result.length == 2));
    status = new MojoResult(result[0]);
    return result[1];
  }

  ByteData beginRead([int bufferBytes = 0, int flags = 0]) {
    if (handle == null) {
      status = MojoResult.INVALID_ARGUMENT;
      return null;
    }

    List result =
        MojoDataPipeNatives.MojoBeginReadData(handle.h, bufferBytes, flags);
    if (result == null) {
      status = MojoResult.INVALID_ARGUMENT;
      return null;
    }

    assert((result is List) && (result.length == 2));
    status = new MojoResult(result[0]);
    return result[1];
  }

  MojoResult endRead(int bytesRead) {
    if (handle == null) {
      status = MojoResult.INVALID_ARGUMENT;
      return status;
    }
    int result = MojoDataPipeNatives.MojoEndReadData(handle.h, bytesRead);
    status = new MojoResult(result);
    return status;
  }

  int query() => read(null, 0, FLAG_QUERY);

  String toString() => "MojoDataPipeConsumer("
      "handle: $handle, status: $status, available: ${query()})";
}

class MojoDataPipe {
  static const int FLAG_NONE = 0;
  static const int DEFAULT_ELEMENT_SIZE = 1;
  static const int DEFAULT_CAPACITY = 0;

  MojoDataPipeProducer producer;
  MojoDataPipeConsumer consumer;
  MojoResult status;

  MojoDataPipe._internal() {
    producer = null;
    consumer = null;
    status = MojoResult.OK;
  }

  factory MojoDataPipe([int elementBytes = DEFAULT_ELEMENT_SIZE,
      int capacityBytes = DEFAULT_CAPACITY, int flags = FLAG_NONE]) {
    List result = MojoDataPipeNatives.MojoCreateDataPipe(
        elementBytes, capacityBytes, flags);
    if (result == null) {
      return null;
    }
    assert((result is List) && (result.length == 3));
    MojoHandle producerHandle = new MojoHandle(result[1]);
    MojoHandle consumerHandle = new MojoHandle(result[2]);
    MojoDataPipe pipe = new MojoDataPipe._internal();
    pipe.producer = new MojoDataPipeProducer(
        producerHandle, new MojoResult(result[0]), elementBytes);
    pipe.consumer = new MojoDataPipeConsumer(
        consumerHandle, new MojoResult(result[0]), elementBytes);
    pipe.status = new MojoResult(result[0]);
    return pipe;
  }
}
