// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:ui/src/engine.dart' as engine;

engine.TestLocationStrategy _strategy;

const engine.MethodCodec codec = engine.JSONMethodCodec();

void emptyCallback(ByteData date) {}

void main() {
  setUp(() {
    engine.window.locationStrategy = _strategy = engine.TestLocationStrategy();
  });

  tearDown(() {
    engine.window.locationStrategy = _strategy = null;
  });

  test('Tracks pushed, replaced and popped routes', () {
    engine.window.sendPlatformMessage(
      'flutter/navigation',
      codec.encodeMethodCall(const engine.MethodCall(
        'routePushed',
        <String, dynamic>{'previousRouteName': '/', 'routeName': '/foo'},
      )),
      emptyCallback,
    );
    expect(_strategy.path, '/foo');

    engine.window.sendPlatformMessage(
      'flutter/navigation',
      codec.encodeMethodCall(const engine.MethodCall(
        'routePushed',
        <String, dynamic>{'previousRouteName': '/foo', 'routeName': '/bar'},
      )),
      emptyCallback,
    );
    expect(_strategy.path, '/bar');

    engine.window.sendPlatformMessage(
      'flutter/navigation',
      codec.encodeMethodCall(const engine.MethodCall(
        'routePopped',
        <String, dynamic>{'previousRouteName': '/foo', 'routeName': '/bar'},
      )),
      emptyCallback,
    );
    expect(_strategy.path, '/foo');

    engine.window.sendPlatformMessage(
      'flutter/navigation',
      codec.encodeMethodCall(const engine.MethodCall(
        'routePushed',
        <String, dynamic>{'previousRouteName': '/foo', 'routeName': '/bar/baz'},
      )),
      emptyCallback,
    );
    expect(_strategy.path, '/bar/baz');

    engine.window.sendPlatformMessage(
      'flutter/navigation',
      codec.encodeMethodCall(const engine.MethodCall(
        'routeReplaced',
        <String, dynamic>{
          'previousRouteName': '/bar/baz',
          'routeName': '/bar/baz2',
        },
      )),
      emptyCallback,
    );
    expect(_strategy.path, '/bar/baz2');

    engine.window.sendPlatformMessage(
      'flutter/navigation',
      codec.encodeMethodCall(const engine.MethodCall(
        'routeUpdated',
        <String, dynamic>{'previousRouteName': '/bar/baz2', 'routeName': '/foo/foo/2'},
      )),
      emptyCallback,
    );
    expect(_strategy.path, '/foo/foo/2');
  });
}
