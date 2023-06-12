// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

@Retry(0)

import 'dart:async';

import 'package:dwds/src/utilities/batched_stream.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('Batched stream controller', () {
    test('emits batches', () async {
      const size = 100;
      const delay = Duration(milliseconds: 1000);

      final batchOne = List<int>.generate(size, (index) => index);
      final batchTwo = List<int>.generate(size, (index) => size + index);

      // Setup controller.
      final controller = BatchedStreamController<int>(delay: 500);

      // Verify the output.
      expect(
          controller.stream,
          emitsInOrder([
            batchOne,
            batchTwo,
          ]));

      // Add input.
      final inputController = StreamController<int>();
      final inputAdded = controller.sink.addStream(inputController.stream);

      batchOne.forEach(inputController.sink.add);
      await Future.delayed(delay);
      batchTwo.forEach(inputController.sink.add);

      await inputController.close();
      await inputAdded;
      await controller.close();
    });

    test('emits all inputs in order', () async {
      const size = 10;
      const delay = Duration(milliseconds: 200);

      // Setup controller.
      final controller = BatchedStreamController<int>(delay: 500);

      // Setup output listener.
      final output = controller.stream.toList();

      // Add input.
      final inputController = StreamController<int>();
      final inputAdded = controller.sink.addStream(inputController.stream);

      final input = List<int>.generate(size, (index) => index);
      for (var e in input) {
        inputController.sink.add(e);
        await Future.delayed(delay);
      }

      await inputController.close();
      await inputAdded;
      await controller.close();

      // Verify the output.
      final result = await output;
      expect(result.length, greaterThan(1));

      final flattened = <int>[];
      result.forEach(flattened.addAll);
      expect(flattened, input);
    });
  });
}
