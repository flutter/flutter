#!/usr/bin/env dart
// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:fixnum/fixnum.dart';
import 'package:test/test.dart' show test, expect;

import '../out/protos/foo.pb.dart' as pb;

void main() {
  test('merges child message', () {
    final top = pb.Outer()
      ..id = Int64(1)
      ..value = 'sss'
      ..strings.addAll(['s1', 's2'])
      ..inner = (pb.Inner()
        ..id = Int64(2)
        ..value = 'sub'
        ..strings.addAll(['sub1', 'sub2']));

    final update = pb.Outer()
      ..id = Int64(1)
      ..value = 'new'
      ..inner = (pb.Inner()..id = Int64(3));

    top.mergeFromMessage(update);

    final expected = pb.Outer()
      ..id = Int64(1)
      ..value = 'new'
      ..strings.addAll(['s1', 's2'])
      // This is properly merged.
      ..inner = (pb.Inner()
        ..id = Int64(3)
        ..value = 'sub'
        ..strings.addAll(['sub1', 'sub2']));

    expect(top, expected);
  });

  test('merges grandchild message', () {
    final empty = pb.Outer();
    final mergeMe1 = pb.Outer()
      ..inner = (pb.Inner()..inner = (pb.Inner()..id = Int64(1)));
    final mergeMe2 = pb.Outer()
      ..inner = (pb.Inner()..inner = (pb.Inner()..value = 'new'));

    empty.mergeFromMessage(mergeMe1);
    empty.mergeFromMessage(mergeMe2);

    final expected = pb.Outer()
      ..inner = (pb.Inner()
        ..inner = (pb.Inner()
          ..id = Int64(1)
          ..value = 'new'));
    expect(empty, expected);
  });

  test('merges repeated element of child', () {
    final empty = pb.Outer();
    final mergeMe = pb.Outer()..inner = (pb.Inner()..strings.add('one'));

    empty.mergeFromMessage(mergeMe);

    final expected = pb.Outer()..inner = (pb.Inner()..strings.add('one'));
    expect(empty, expected);
  });
}
