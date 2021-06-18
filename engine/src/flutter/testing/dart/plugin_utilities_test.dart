// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:litetest/litetest.dart';

String top() => 'top';

class Foo {
  const Foo();
  static int getInt() => 1;
  double getDouble() => 1.0;
}

const Foo foo = Foo();

void main() {
  test('PluginUtilities Callback Handles', () {
    // Top level callback.
    final CallbackHandle hTop = PluginUtilities.getCallbackHandle(top)!;
    expect(hTop, notEquals(0));
    expect(PluginUtilities.getCallbackHandle(top), hTop);
    final Function topClosure = PluginUtilities.getCallbackFromHandle(hTop)!;
    expect(topClosure(), 'top');

    // Static method callback.
    final CallbackHandle hGetInt = PluginUtilities.getCallbackHandle(Foo.getInt)!;
    expect(hGetInt, notEquals(0));
    expect(PluginUtilities.getCallbackHandle(Foo.getInt), hGetInt);
    final Function getIntClosure = PluginUtilities.getCallbackFromHandle(hGetInt)!;
    expect(getIntClosure(), 1);

    // Instance method callbacks cannot be looked up.
    const Foo foo = Foo();
    expect(PluginUtilities.getCallbackHandle(foo.getDouble), isNull);

    // Anonymous closures cannot be looked up.
    final Function anon = (int a, int b) => a + b; // ignore: prefer_function_declarations_over_variables
    expect(PluginUtilities.getCallbackHandle(anon), isNull);
  });
}
