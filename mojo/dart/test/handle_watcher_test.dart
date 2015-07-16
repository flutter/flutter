// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:_testing/expect.dart';
import 'package:mojo/core.dart';

void simpleTest() {
  var pipe = new MojoMessagePipe();
  Expect.isNotNull(pipe);

  var endpoint = pipe.endpoints[0];
  Expect.isTrue(endpoint.handle.isValid);

  var eventStream = new MojoEventStream(endpoint.handle);
  var completer = new Completer();
  int numEvents = 0;

  eventStream.listen((_) {
    numEvents++;
    eventStream.close();
  }, onDone: () {
    completer.complete(numEvents);
  });
  eventStream.enableWriteEvents();

  completer.future.then((int numEvents) {
    Expect.equals(1, numEvents);
  });
}

Future simpleAsyncAwaitTest() async {
  var pipe = new MojoMessagePipe();
  Expect.isNotNull(pipe);

  var endpoint = pipe.endpoints[0];
  Expect.isTrue(endpoint.handle.isValid);

  var eventStream =
      new MojoEventStream(endpoint.handle, MojoHandleSignals.READWRITE);

  int numEvents = 0;
  await for (List<int> event in eventStream) {
    numEvents++;
    eventStream.close();
  }
  Expect.equals(1, numEvents);
}

ByteData byteDataOfString(String s) {
  return new ByteData.view((new Uint8List.fromList(s.codeUnits)).buffer);
}

String stringOfByteData(ByteData bytes) {
  return new String.fromCharCodes(bytes.buffer.asUint8List().toList());
}

void expectStringFromEndpoint(
    String expected, MojoMessagePipeEndpoint endpoint) {
  // Query how many bytes are available.
  var result = endpoint.query();
  Expect.isNotNull(result);
  int size = result.bytesRead;
  Expect.isTrue(size > 0);

  // Read the data.
  ByteData bytes = new ByteData(size);
  result = endpoint.read(bytes);
  Expect.isNotNull(result);
  Expect.equals(size, result.bytesRead);

  // Convert to a string and check.
  String msg = stringOfByteData(bytes);
  Expect.equals(expected, msg);
}

Future pingPongIsolate(MojoMessagePipeEndpoint endpoint) async {
  int pings = 0;
  int pongs = 0;
  var eventStream = new MojoEventStream(endpoint.handle);
  await for (List<int> event in eventStream) {
    var mojoSignals = new MojoHandleSignals(event[1]);
    if (mojoSignals.isReadWrite) {
      // We are either sending or receiving.
      throw new Exception("Unexpected event");
    } else if (mojoSignals.isReadable) {
      expectStringFromEndpoint("Ping", endpoint);
      pings++;
      eventStream.enableWriteEvents();
    } else if (mojoSignals.isWritable) {
      endpoint.write(byteDataOfString("Pong"));
      pongs++;
      eventStream.enableReadEvents();
    }
  }
  eventStream.close();
  Expect.equals(10, pings);
  Expect.equals(10, pongs);
}

Future pingPongTest() async {
  var pipe = new MojoMessagePipe();
  var isolate = await Isolate.spawn(pingPongIsolate, pipe.endpoints[0]);
  var endpoint = pipe.endpoints[1];
  var eventStream =
      new MojoEventStream(endpoint.handle, MojoHandleSignals.READWRITE);

  int pings = 0;
  int pongs = 0;
  await for (List<int> event in eventStream) {
    var mojoSignals = new MojoHandleSignals(event[1]);
    if (mojoSignals.isReadWrite) {
      // We are either sending or receiving.
      throw new Exception("Unexpected event");
    } else if (mojoSignals.isReadable) {
      expectStringFromEndpoint("Pong", endpoint);
      pongs++;
      if (pongs == 10) {
        eventStream.close();
      }
      eventStream.enableWriteEvents(); // Now it is our turn to send.
    } else if (mojoSignals.isWritable) {
      if (pings < 10) {
        endpoint.write(byteDataOfString("Ping"));
        pings++;
      }
      eventStream.enableReadEvents(); // Don't send while waiting for reply.
    }
  }
  Expect.equals(10, pings);
  Expect.equals(10, pongs);
}

main() async {
  simpleTest();
  await simpleAsyncAwaitTest();
  await pingPongTest();
}
