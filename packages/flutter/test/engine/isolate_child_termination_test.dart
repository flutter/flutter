// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';

void main() {
    test('Child isolates terminated when parent is terminated depth 1', () async {
    int expectedChildren = 2;
    IsolateTracker.reset();
    IsolateTracker tracker = new IsolateTracker();
    ReceivePort receivePort = new ReceivePort();
    ReceivePort rootPort = new ReceivePort();
    ReceivePort deathPort = new ReceivePort();
    receivePort.listen(
            (data) {
          IsolateTracker._childCount += 1;
          if (IsolateTracker._childCount == expectedChildren && IsolateTracker.root != null) {
           cleanup(expectedChildren);
          }
        }
    );
    rootPort.listen(
            (data) {
          IsolateTracker.root = data;
          if (IsolateTracker._childCount == expectedChildren) {
           cleanup(expectedChildren);
          }
        }
    );
    deathPort.listen(
            (data) {
          IsolateTracker._deathCount += 1;
        }
    );
    spawnIsolate([1, receivePort.sendPort, deathPort.sendPort, true], true, rootPort.sendPort);
    expect(await IsolateTracker.numberOfDeaths(expectedChildren, 2000), expectedChildren);
    print("All Isolate deaths accounted for.");
  });

    test('Child isolates terminated when parent is terminated depth 2', () async {
    int expectedChildren = 5;
    IsolateTracker.reset();
    IsolateTracker tracker = new IsolateTracker();
    ReceivePort receivePort = new ReceivePort();
    ReceivePort rootPort = new ReceivePort();
    ReceivePort deathPort = new ReceivePort();
    receivePort.listen(
            (data) {
          IsolateTracker._childCount += 1;
          if (IsolateTracker._childCount == expectedChildren && IsolateTracker.root != null) {
           cleanup(expectedChildren);
          }
        }
    );
    rootPort.listen(
            (data) {
          IsolateTracker.root = data;
          if (IsolateTracker._childCount == expectedChildren) {
           cleanup(expectedChildren);
          }
        }
    );
    deathPort.listen(
            (data) {
          IsolateTracker._deathCount += 1;
        }
    );
    spawnIsolate([2, receivePort.sendPort, deathPort.sendPort, true], true, rootPort.sendPort);
    expect(await IsolateTracker.numberOfDeaths(expectedChildren, 2000), expectedChildren);
    print("All Isolate deaths accounted for.");
  });

  test('Child isolates terminated when parent is terminated depth 3', () async {
    int expectedChildren = 16;
    IsolateTracker.reset();
    IsolateTracker tracker = new IsolateTracker();
    ReceivePort receivePort = new ReceivePort();
    ReceivePort rootPort = new ReceivePort();
    ReceivePort deathPort = new ReceivePort();
    receivePort.listen(
            (data) {
          IsolateTracker._childCount += 1;
          if (IsolateTracker._childCount == expectedChildren && IsolateTracker.root != null) {
           cleanup(expectedChildren);
          }
        }
    );
    rootPort.listen(
            (data) {
          IsolateTracker.root = data;
          if (IsolateTracker._childCount == expectedChildren) {
           cleanup(expectedChildren);
          }
        }
    );
    deathPort.listen(
            (data) {
          IsolateTracker._deathCount += 1;
        }
    );
    spawnIsolate([3, receivePort.sendPort, deathPort.sendPort, true], true, rootPort.sendPort);
    expect(await IsolateTracker.numberOfDeaths(expectedChildren, 2000), expectedChildren);
    print("All Isolate deaths accounted for.");
  });

  test('Child isolates terminated when parent is terminated depth 4', () async {
    int expectedChildren = 65;
    IsolateTracker.reset();
    IsolateTracker tracker = new IsolateTracker();
    ReceivePort receivePort = new ReceivePort();
    ReceivePort rootPort = new ReceivePort();
    ReceivePort deathPort = new ReceivePort();
    receivePort.listen(
            (data) {
          IsolateTracker._childCount += 1;
          if (IsolateTracker._childCount == expectedChildren && IsolateTracker.root != null) {
           cleanup(expectedChildren);
          }
        }
    );
    rootPort.listen(
            (data) {
          IsolateTracker.root = data;
          if (IsolateTracker._childCount == expectedChildren) {
           cleanup(expectedChildren);
          }
        }
    );
    deathPort.listen(
            (data) {
          IsolateTracker._deathCount += 1;
        }
    );
    spawnIsolate([4, receivePort.sendPort, deathPort.sendPort, true], true, rootPort.sendPort);
    expect(await IsolateTracker.numberOfDeaths(expectedChildren, 8000), expectedChildren);
    print("All Isolate deaths accounted for.");
  });
}

void spawnIsolate(msg, [bool isRoot = false, SendPort rootPort]) {
  if (isRoot) {
    Isolate.spawn(isolateJob, msg, onExit: msg[2]).then<Null>((
        Isolate isolate) {
      rootPort.send(isolate);
    });
  }
  else {
    Isolate.spawn(isolateJob, msg, onExit: msg[2]).then<Null>((Isolate isolate) {
    });
  }
}

void cleanup(expectedChildren) async {
  // Slight delay to allow for messages to finish sending.
  // If more deaths than expected are recieved, this delay allows them to register.
  await new Future.delayed(Duration(milliseconds: 200));
  if (IsolateTracker._childCount == expectedChildren && IsolateTracker.root != null) {
    IsolateTracker.root.kill(priority: 1);
  }
}
void isolateJob(msg) {
  msg[1].send(1);
  for (int i = 0; i < msg[0]; i++) {
    spawnIsolate([msg[0] - 1, msg[1], msg[2], false]);
  }

  // Open a dummy port so that the isolate does not end.
  ReceivePort dummyPort = new ReceivePort();
}

class IsolateTracker {
  static int _childCount = 0;
  static int _deathCount = 0;
//  static List<Isolate> _isolates = [];
  static Isolate root;

  static Future<int> numberOfDeaths(expectedDeaths, waitTime) async {
    int elapsed = 0;
    int pauseDuration = 100;
    while (_deathCount != expectedDeaths) {
      await new Future.delayed(Duration(milliseconds: pauseDuration));
      elapsed += pauseDuration;
      // Fail if takes too long to complete
      if (elapsed > waitTime) {
        return -1;
      }
    }
    return _deathCount;
  }

  static void reset() {
    _childCount = 0;
    _deathCount = 0;
    root = null;
  }
}
