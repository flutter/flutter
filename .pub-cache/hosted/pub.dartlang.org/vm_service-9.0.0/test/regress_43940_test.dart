// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

void main() {
  test('Call dispose handler before onDone completion', () async {
    final controller = StreamController<String>(onCancel: () async {
      await Future.delayed(const Duration(seconds: 1));
    });
    bool completed = false;
    final fakeService = VmService(
      controller.stream,
      controller.sink.add,
      disposeHandler: () async {
        completed = true;
      },
    );

    unawaited(fakeService.dispose());
    await fakeService.onDone;
    expect(completed, true);
  });
}
