#!/usr/bin/env dart
// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:fixnum/fixnum.dart';
import 'package:test/test.dart';

import '../out/protos/_leading_underscores.pb.dart';

void main() {
  test('can set, read and clear all fields and refer to types', () {
    var message = A_();
    message.setExtension(Leading_underscores_.p, Int64(99));
    expect(message.getExtension(Leading_underscores_.p), Int64(99));
    message.f = 'foo';
    message.f_2 = 'foo2';
    expect(message.f, 'foo');
    expect(message.f_2, 'foo2');
    message.clearF();
    message.clearF_2();
    expect(message.hasF(), false);
    expect(message.hasF_2(), false);
    expect(message.f, '');
    expect(message.f_2, '');
    var messageA = A();
    messageA.b = message;
    messageA.b_6 = message;
    expect(messageA.b_6, message);
    messageA.amap['foo'] = message;
    expect(messageA.amap['foo'], message);

    messageA.red = 'r';
    expect(messageA.red, 'r');
    expect(messageA.green, '');
    messageA.clearColors();
    expect(messageA.red, '');
    expect(messageA.green, '');
    messageA.red = 'r';
    messageA.clearRed();
    expect(messageA.red, '');
    expect(messageA.green, '');
    messageA.green = 'g';
    expect(messageA.green, 'g');
    messageA.clearGreen();
    expect(messageA.red, '');
    expect(messageA.green, '');

    messageA.e = Enum_.constant;
    expect(messageA.e, Enum_.constant);
    messageA.clearE();
    expect(messageA.e, Enum_.default_);
    messageA.clearE();
    messageA.e = Enum_.x1digit_;
    expect(messageA.e, Enum_.x1digit_);
    messageA.r.add(message);
    expect(messageA.r, [message]);
    messageA.setExtension(Leading_underscores_.q, Int64(100));
    expect(messageA.getExtension(Leading_underscores_.q), Int64(100));

    var a = A__()..foo = 'hi';
    expect(a.foo, 'hi');
  });
}
