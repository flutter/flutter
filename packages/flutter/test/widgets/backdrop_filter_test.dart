// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])
library;

import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Backdrop key is passed to backdrop Layer', (WidgetTester tester) async {
    final backdropKey = BackdropKey();

    Widget build({required bool enableKeys}) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: ListView(
          children: <Widget>[
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                backdropGroupKey: enableKeys ? backdropKey : null,
                child: Container(
                  color: const Color(0x28000000),
                  height: 200,
                  child: const Text('Item 1'),
                ),
              ),
            ),
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                backdropGroupKey: enableKeys ? backdropKey : null,
                child: Container(
                  color: const Color(0x28000000),
                  height: 200,
                  child: const Text('Item 1'),
                ),
              ),
            ),
          ],
        ),
      );
    }

    await tester.pumpWidget(build(enableKeys: true));

    List<BackdropFilterLayer> layers = tester.layers.whereType<BackdropFilterLayer>().toList();

    expect(layers.length, 2);
    expect(layers[0].backdropKey, backdropKey);
    expect(layers[1].backdropKey, backdropKey);

    await tester.pumpWidget(build(enableKeys: false));

    layers = tester.layers.whereType<BackdropFilterLayer>().toList();

    expect(layers.length, 2);
    expect(layers[0].backdropKey, null);
    expect(layers[1].backdropKey, null);
  });

  testWidgets('Backdrop key is passed to backdrop Layer via backdrop group', (
    WidgetTester tester,
  ) async {
    Widget build() {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: BackdropGroup(
          child: ListView(
            children: <Widget>[
              ClipRect(
                child: BackdropFilter.grouped(
                  filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                  child: Container(
                    color: const Color(0x28000000),
                    height: 200,
                    child: const Text('Item 1'),
                  ),
                ),
              ),
              ClipRect(
                child: BackdropFilter.grouped(
                  filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                  child: Container(
                    color: const Color(0x28000000),
                    height: 200,
                    child: const Text('Item 1'),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    await tester.pumpWidget(build());

    final List<BackdropFilterLayer> layers = tester.layers
        .whereType<BackdropFilterLayer>()
        .toList();

    expect(layers.length, 2);
    expect(layers[0].backdropKey, layers[1].backdropKey);
  });
}
