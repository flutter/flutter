// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';

// Test that stream listener callbacks all happen in the zone where the
// listen occurred.

void main() {
  StreamController controller;
  controller = StreamController();
  testStream('singlesub-async', controller, controller.stream);
  controller = StreamController.broadcast();
  testStream('broadcast-async', controller, controller.stream);
  controller = StreamController();
  testStream(
      'asbroadcast-async', controller, controller.stream.asBroadcastStream());

  controller = StreamController(sync: true);
  testStream('singlesub-sync', controller, controller.stream);
  controller = StreamController.broadcast(sync: true);
  testStream('broadcast-sync', controller, controller.stream);
  controller = StreamController(sync: true);
  testStream(
      'asbroadcast-sync', controller, controller.stream.asBroadcastStream());
}

void testStream(String name, StreamController controller, Stream stream) {
  test(name, () {
    var outer = Zone.current;
    runZoned(() {
      var newZone1 = Zone.current;
      late StreamSubscription sub;
      sub = stream.listen(expectAsync1((v) {
        expect(v, 42);
        expect(Zone.current, newZone1);
        outer.run(() {
          sub.onData(expectAsync1((v) {
            expect(v, 37);
            expect(Zone.current, newZone1);
            runZoned(() {
              sub.onData(expectAsync1((v) {
                expect(v, 87);
                expect(Zone.current, newZone1);
              }));
            });
            if (controller is SynchronousStreamController) {
              scheduleMicrotask(() => controller.add(87));
            } else {
              controller.add(87);
            }
          }));
        });
        if (controller is SynchronousStreamController) {
          scheduleMicrotask(() => controller.add(37));
        } else {
          controller.add(37);
        }
      }));
    });
    controller.add(42);
  });
}
