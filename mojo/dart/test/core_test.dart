// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:_testing/expect.dart';
import 'package:mojo/core.dart';

invalidHandleTest() {
  MojoHandle invalidHandle = new MojoHandle(MojoHandle.INVALID);

  // Close.
  MojoResult result = invalidHandle.close();
  Expect.isTrue(result.isInvalidArgument);

  // Wait.
  MojoWaitResult mwr =
      invalidHandle.wait(MojoHandleSignals.kReadWrite, 1000000);
  Expect.isTrue(mwr.result.isInvalidArgument);

  MojoWaitManyResult mwmr = MojoHandle.waitMany([invalidHandle.h], [
    MojoHandleSignals.kReadWrite
  ], MojoHandle.DEADLINE_INDEFINITE);
  Expect.isTrue(mwmr.result.isInvalidArgument);

  // Message pipe.
  MojoMessagePipe pipe = new MojoMessagePipe();
  Expect.isNotNull(pipe);
  ByteData bd = new ByteData(10);
  pipe.endpoints[0].handle.close();
  pipe.endpoints[1].handle.close();
  result = pipe.endpoints[0].write(bd);
  Expect.isTrue(result.isInvalidArgument);

  MojoMessagePipeReadResult readResult = pipe.endpoints[0].read(bd);
  Expect.isTrue(pipe.endpoints[0].status.isInvalidArgument);

  // Data pipe.
  MojoDataPipe dataPipe = new MojoDataPipe();
  Expect.isNotNull(dataPipe);
  dataPipe.producer.handle.close();
  dataPipe.consumer.handle.close();

  int bytesWritten = dataPipe.producer.write(bd);
  Expect.isTrue(dataPipe.producer.status.isInvalidArgument);

  ByteData writeData = dataPipe.producer.beginWrite(10);
  Expect.isNull(writeData);
  Expect.isTrue(dataPipe.producer.status.isInvalidArgument);
  dataPipe.producer.endWrite(10);
  Expect.isTrue(dataPipe.producer.status.isInvalidArgument);

  int read = dataPipe.consumer.read(bd);
  Expect.isTrue(dataPipe.consumer.status.isInvalidArgument);

  ByteData readData = dataPipe.consumer.beginRead(10);
  Expect.isNull(readData);
  Expect.isTrue(dataPipe.consumer.status.isInvalidArgument);
  dataPipe.consumer.endRead(10);
  Expect.isTrue(dataPipe.consumer.status.isInvalidArgument);

  // Shared buffer.
  MojoSharedBuffer sharedBuffer = new MojoSharedBuffer.create(10);
  Expect.isNotNull(sharedBuffer);
  sharedBuffer.close();
  MojoSharedBuffer duplicate = new MojoSharedBuffer.duplicate(sharedBuffer);
  Expect.isNull(duplicate);

  sharedBuffer = new MojoSharedBuffer.create(10);
  Expect.isNotNull(sharedBuffer);
  sharedBuffer.close();
  result = sharedBuffer.map(0, 10);
  Expect.isTrue(result.isInvalidArgument);
}

basicMessagePipeTest() {
  MojoMessagePipe pipe = new MojoMessagePipe();
  Expect.isNotNull(pipe);
  Expect.isTrue(pipe.status.isOk);
  Expect.isNotNull(pipe.endpoints);

  MojoMessagePipeEndpoint end0 = pipe.endpoints[0];
  MojoMessagePipeEndpoint end1 = pipe.endpoints[1];
  Expect.isTrue(end0.handle.isValid);
  Expect.isTrue(end1.handle.isValid);

  // Not readable, yet.
  MojoWaitResult mwr = end0.handle.wait(MojoHandleSignals.kReadable, 0);
  Expect.isTrue(mwr.result.isDeadlineExceeded);

  // Should be writable.
  mwr = end0.handle.wait(MojoHandleSignals.kWritable, 0);
  Expect.isTrue(mwr.result.isOk);

  // Try to read.
  ByteData data = new ByteData(10);
  end0.read(data);
  Expect.isTrue(end0.status.isShouldWait);

  // Write end1.
  String hello = "hello";
  ByteData helloData =
      new ByteData.view((new Uint8List.fromList(hello.codeUnits)).buffer);
  MojoResult result = end1.write(helloData);
  Expect.isTrue(result.isOk);

  // end0 should now be readable.
  MojoWaitManyResult mwmr = MojoHandle.waitMany([end0.handle.h], [
    MojoHandleSignals.kReadable
  ], MojoHandle.DEADLINE_INDEFINITE);
  Expect.isTrue(mwmr.result.isOk);

  // Read from end0.
  MojoMessagePipeReadResult readResult = end0.read(data);
  Expect.isNotNull(readResult);
  Expect.isTrue(readResult.status.isOk);
  Expect.equals(readResult.bytesRead, helloData.lengthInBytes);
  Expect.equals(readResult.handlesRead, 0);

  String hello_result = new String.fromCharCodes(
      data.buffer.asUint8List().sublist(0, readResult.bytesRead).toList());
  Expect.equals(hello_result, "hello");

  // end0 should no longer be readable.
  mwr = end0.handle.wait(MojoHandleSignals.kReadable, 10);
  Expect.isTrue(mwr.result.isDeadlineExceeded);

  // Close end0's handle.
  result = end0.handle.close();
  Expect.isTrue(result.isOk);

  // end1 should no longer be readable or writable.
  mwr = end1.handle.wait(MojoHandleSignals.kReadWrite, 1000);
  Expect.isTrue(mwr.result.isFailedPrecondition);

  result = end1.handle.close();
  Expect.isTrue(result.isOk);
}

basicDataPipeTest() {
  MojoDataPipe pipe = new MojoDataPipe();
  Expect.isNotNull(pipe);
  Expect.isTrue(pipe.status.isOk);
  Expect.isTrue(pipe.consumer.handle.isValid);
  Expect.isTrue(pipe.producer.handle.isValid);

  MojoDataPipeProducer producer = pipe.producer;
  MojoDataPipeConsumer consumer = pipe.consumer;
  Expect.isTrue(producer.handle.isValid);
  Expect.isTrue(consumer.handle.isValid);

  // Consumer should not be readable.
  MojoWaitResult mwr = consumer.handle.wait(MojoHandleSignals.kReadable, 0);
  Expect.isTrue(mwr.result.isDeadlineExceeded);

  // Producer should be writable.
  mwr = producer.handle.wait(MojoHandleSignals.kWritable, 0);
  Expect.isTrue(mwr.result.isOk);

  // Try to read from consumer.
  ByteData buffer = new ByteData(20);
  consumer.read(buffer, buffer.lengthInBytes, MojoDataPipeConsumer.FLAG_NONE);
  Expect.isTrue(consumer.status.isShouldWait);

  // Try to begin a two-phase read from consumer.
  ByteData b = consumer.beginRead(20, MojoDataPipeConsumer.FLAG_NONE);
  Expect.isNull(b);
  Expect.isTrue(consumer.status.isShouldWait);

  // Write to producer.
  String hello = "hello ";
  ByteData helloData =
      new ByteData.view((new Uint8List.fromList(hello.codeUnits)).buffer);
  int written = producer.write(
      helloData, helloData.lengthInBytes, MojoDataPipeProducer.FLAG_NONE);
  Expect.isTrue(producer.status.isOk);
  Expect.equals(written, helloData.lengthInBytes);

  // Now that we have written, the consumer should be readable.
  MojoWaitManyResult mwmr = MojoHandle.waitMany([consumer.handle.h], [
    MojoHandleSignals.kReadable
  ], MojoHandle.DEADLINE_INDEFINITE);
  Expect.isTrue(mwr.result.isOk);

  // Do a two-phase write to the producer.
  ByteData twoPhaseWrite =
      producer.beginWrite(20, MojoDataPipeProducer.FLAG_NONE);
  Expect.isTrue(producer.status.isOk);
  Expect.isNotNull(twoPhaseWrite);
  Expect.isTrue(twoPhaseWrite.lengthInBytes >= 20);

  String world = "world";
  twoPhaseWrite.buffer.asUint8List().setAll(0, world.codeUnits);
  producer.endWrite(Uint8List.BYTES_PER_ELEMENT * world.codeUnits.length);
  Expect.isTrue(producer.status.isOk);

  // Read one character from consumer.
  int read = consumer.read(buffer, 1, MojoDataPipeConsumer.FLAG_NONE);
  Expect.isTrue(consumer.status.isOk);
  Expect.equals(read, 1);

  // Close the producer.
  MojoResult result = producer.handle.close();
  Expect.isTrue(result.isOk);

  // Consumer should still be readable.
  mwr = consumer.handle.wait(MojoHandleSignals.kReadable, 0);
  Expect.isTrue(mwr.result.isOk);

  // Get the number of remaining bytes.
  int remaining = consumer.read(null, 0, MojoDataPipeConsumer.FLAG_QUERY);
  Expect.isTrue(consumer.status.isOk);
  Expect.equals(remaining, "hello world".length - 1);

  // Do a two-phase read.
  ByteData twoPhaseRead =
      consumer.beginRead(remaining, MojoDataPipeConsumer.FLAG_NONE);
  Expect.isTrue(consumer.status.isOk);
  Expect.isNotNull(twoPhaseRead);
  Expect.isTrue(twoPhaseRead.lengthInBytes <= remaining);

  Uint8List uint8_list = buffer.buffer.asUint8List();
  uint8_list.setAll(1, twoPhaseRead.buffer.asUint8List());
  uint8_list = uint8_list.sublist(0, 1 + twoPhaseRead.lengthInBytes);

  consumer.endRead(twoPhaseRead.lengthInBytes);
  Expect.isTrue(consumer.status.isOk);

  String helloWorld = new String.fromCharCodes(uint8_list.toList());
  Expect.equals("hello world", helloWorld);

  result = consumer.handle.close();
  Expect.isTrue(result.isOk);
}

basicSharedBufferTest() {
  MojoSharedBuffer mojoBuffer =
      new MojoSharedBuffer.create(100, MojoSharedBuffer.CREATE_FLAG_NONE);
  Expect.isNotNull(mojoBuffer);
  Expect.isNotNull(mojoBuffer.status);
  Expect.isTrue(mojoBuffer.status.isOk);
  Expect.isNotNull(mojoBuffer.handle);
  Expect.isTrue(mojoBuffer.handle is MojoHandle);
  Expect.isTrue(mojoBuffer.handle.isValid);

  mojoBuffer.map(0, 100, MojoSharedBuffer.MAP_FLAG_NONE);
  Expect.isNotNull(mojoBuffer.status);
  Expect.isTrue(mojoBuffer.status.isOk);
  Expect.isNotNull(mojoBuffer.mapping);
  Expect.isTrue(mojoBuffer.mapping is ByteData);

  mojoBuffer.mapping.setInt8(50, 42);

  MojoSharedBuffer duplicate = new MojoSharedBuffer.duplicate(
      mojoBuffer, MojoSharedBuffer.DUPLICATE_FLAG_NONE);
  Expect.isNotNull(duplicate);
  Expect.isNotNull(duplicate.status);
  Expect.isTrue(duplicate.status.isOk);
  Expect.isTrue(duplicate.handle is MojoHandle);
  Expect.isTrue(duplicate.handle.isValid);

  duplicate.map(0, 100, MojoSharedBuffer.MAP_FLAG_NONE);
  Expect.isTrue(duplicate.status.isOk);
  Expect.isNotNull(duplicate.mapping);
  Expect.isTrue(duplicate.mapping is ByteData);

  mojoBuffer.close();
  mojoBuffer = null;

  duplicate.mapping.setInt8(51, 43);

  duplicate.unmap();
  Expect.isNotNull(duplicate.status);
  Expect.isTrue(duplicate.status.isOk);
  Expect.isNull(duplicate.mapping);

  duplicate.map(50, 50, MojoSharedBuffer.MAP_FLAG_NONE);
  Expect.isNotNull(duplicate.status);
  Expect.isTrue(duplicate.status.isOk);
  Expect.isNotNull(duplicate.mapping);
  Expect.isTrue(duplicate.mapping is ByteData);

  Expect.equals(duplicate.mapping.getInt8(0), 42);
  Expect.equals(duplicate.mapping.getInt8(1), 43);

  duplicate.unmap();
  Expect.isNotNull(duplicate.status);
  Expect.isTrue(duplicate.status.isOk);
  Expect.isNull(duplicate.mapping);

  duplicate.close();
  duplicate = null;
}

main() {
  invalidHandleTest();
  basicMessagePipeTest();
  basicDataPipeTest();
  basicSharedBufferTest();
}
