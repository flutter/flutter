// Copyright 2013 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

library quiver.collection.delegates.queue_test;

import 'dart:collection' show Queue;

import 'package:quiver/src/collection/delegates/queue.dart';
import 'package:test/test.dart';

class MyQueue extends DelegatingQueue<String> {
  MyQueue(this._delegate);

  final Queue<String> _delegate;

  @override
  Queue<String> get delegate => _delegate;
}

void main() {
  group('DelegatingQueue', () {
    late DelegatingQueue<String> delegatingQueue;

    setUp(() {
      delegatingQueue = MyQueue(Queue<String>.from(['a', 'b', 'cc']));
    });

    test('add', () {
      delegatingQueue.add('d');
      expect(delegatingQueue, equals(['a', 'b', 'cc', 'd']));
    });

    test('addAll', () {
      delegatingQueue.addAll(['d', 'e']);
      expect(delegatingQueue, equals(['a', 'b', 'cc', 'd', 'e']));
    });

    test('addFirst', () {
      delegatingQueue.addFirst('d');
      expect(delegatingQueue, equals(['d', 'a', 'b', 'cc']));
    });

    test('addLast', () {
      delegatingQueue.addLast('d');
      expect(delegatingQueue, equals(['a', 'b', 'cc', 'd']));
    });

    test('clear', () {
      delegatingQueue.clear();
      expect(delegatingQueue, equals([]));
    });

    test('remove', () {
      expect(delegatingQueue.remove('b'), isTrue);
      expect(delegatingQueue, equals(['a', 'cc']));
    });

    test('removeFirst', () {
      expect(delegatingQueue.removeFirst(), 'a');
      expect(delegatingQueue, equals(['b', 'cc']));
    });

    test('removeLast', () {
      expect(delegatingQueue.removeLast(), 'cc');
      expect(delegatingQueue, equals(['a', 'b']));
    });
  });
}
