// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of core;

class MojoDataPipeProducer {
  static const int FLAG_NONE = 0;
  static const int FLAG_ALL_OR_NONE = 1 << 0;

  final int elementBytes;
  MojoHandle handle;
  int status;

  MojoDataPipeProducer(this.handle,
      [this.status = MojoResult.kOk, this.elementBytes = 1]);

  int write(ByteData data, [int numBytes = -1, int flags = FLAG_NONE]) {
    if (handle == null) {
      status = MojoResult.kInvalidArgument;
      return 0;
    }

    int data_numBytes = (numBytes == -1) ? data.lengthInBytes : numBytes;
    List result =
        MojoDataPipeNatives.MojoWriteData(handle.h, data, data_numBytes, flags);
    if (result == null) {
      status = MojoResult.kInvalidArgument;
      return 0;
    }

    assert((result is List) && (result.length == 2));
    status = result[0];
    return result[1];
  }

  // TODO(floitsch): remove bufferBytes.
  ByteData beginWrite(int bufferBytes, [int flags = FLAG_NONE]) {
    if (handle == null) {
      status = MojoResult.kInvalidArgument;
      return null;
    }

    List result = MojoDataPipeNatives.MojoBeginWriteData(handle.h, flags);
    if (result == null) {
      status = MojoResult.kInvalidArgument;
      return null;
    }

    assert((result is List) && (result.length == 2));
    status = result[0];
    return result[1];
  }

  int endWrite(int bytesWritten) {
    if (handle == null) {
      status = MojoResult.kInvalidArgument;
      return status;
    }
    int result = MojoDataPipeNatives.MojoEndWriteData(handle.h, bytesWritten);
    status = result;
    return status;
  }

  String toString() => "MojoDataPipeProducer(handle: $handle, "
      "status: ${MojoResult.string(status)})";
}

class MojoDataPipeConsumer {
  static const int FLAG_NONE = 0;
  static const int FLAG_ALL_OR_NONE = 1 << 0;
  static const int FLAG_DISCARD = 1 << 1;
  static const int FLAG_QUERY = 1 << 2;
  static const int FLAG_PEEK = 1 << 3;

  MojoHandle handle;
  final int elementBytes;
  int status;

  MojoDataPipeConsumer(this.handle,
      [this.status = MojoResult.kOk, this.elementBytes = 1]);

  int read(ByteData data, [int numBytes = -1, int flags = FLAG_NONE]) {
    if (handle == null) {
      status = MojoResult.kInvalidArgument;
      return 0;
    }

    int data_numBytes = (numBytes == -1) ? data.lengthInBytes : numBytes;
    List result =
        MojoDataPipeNatives.MojoReadData(handle.h, data, data_numBytes, flags);
    if (result == null) {
      status = MojoResult.kInvalidArgument;
      return 0;
    }
    assert((result is List) && (result.length == 2));
    status = result[0];
    return result[1];
  }

  // TODO(floitsch): remove bufferBytes.
  ByteData beginRead([int bufferBytes = 0, int flags = FLAG_NONE]) {
    if (handle == null) {
      status = MojoResult.kInvalidArgument;
      return null;
    }

    List result = MojoDataPipeNatives.MojoBeginReadData(handle.h, flags);
    if (result == null) {
      status = MojoResult.kInvalidArgument;
      return null;
    }

    assert((result is List) && (result.length == 2));
    status = result[0];
    return result[1];
  }

  int endRead(int bytesRead) {
    if (handle == null) {
      status = MojoResult.kInvalidArgument;
      return status;
    }
    int result = MojoDataPipeNatives.MojoEndReadData(handle.h, bytesRead);
    status = result;
    return status;
  }

  int query() => read(null, 0, FLAG_QUERY);

  String toString() => "MojoDataPipeConsumer(handle: $handle, "
      "status: ${MojoResult.string(status)}, "
      "available: ${query()})";
}

class MojoDataPipe {
  static const int FLAG_NONE = 0;
  static const int DEFAULT_ELEMENT_SIZE = 1;
  static const int DEFAULT_CAPACITY = 0;

  MojoDataPipeProducer producer;
  MojoDataPipeConsumer consumer;
  int status;

  MojoDataPipe._internal() : status = MojoResult.kOk;

  factory MojoDataPipe(
      [int elementBytes = DEFAULT_ELEMENT_SIZE,
      int capacityBytes = DEFAULT_CAPACITY,
      int flags = FLAG_NONE]) {
    List result = MojoDataPipeNatives.MojoCreateDataPipe(
        elementBytes, capacityBytes, flags);
    if (result == null) {
      return null;
    }
    assert((result is List) && (result.length == 3));
    MojoHandle producerHandle = new MojoHandle(result[1]);
    MojoHandle consumerHandle = new MojoHandle(result[2]);
    MojoDataPipe pipe = new MojoDataPipe._internal();
    pipe.producer =
        new MojoDataPipeProducer(producerHandle, result[0], elementBytes);
    pipe.consumer =
        new MojoDataPipeConsumer(consumerHandle, result[0], elementBytes);
    pipe.status = result[0];
    return pipe;
  }
}
