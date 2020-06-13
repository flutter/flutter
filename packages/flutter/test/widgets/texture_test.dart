// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Texture with default FilterQuality', (WidgetTester tester) async {
    await tester.pumpWidget(
        const Center(child: Texture(textureId: 1,))
    );

    Texture texture = tester.firstWidget(find.byType(Texture));
    expect(texture, isNotNull);
    expect(texture.textureId, 1);
    expect(texture.filterQuality, FilterQuality.low);
  });

  testWidgets('Texture with FilterQuality', (WidgetTester tester) async {
    await tester.pumpWidget(
        const Center(child: Texture(textureId: 1, filterQuality: FilterQuality.none))
    );

    Texture texture = tester.firstWidget(find.byType(Texture));
    expect(texture, isNotNull);
    expect(texture.textureId, 1);
    expect(texture.filterQuality, FilterQuality.none);

    await tester.pumpWidget(
        const Center(child: Texture(textureId: 1, filterQuality: FilterQuality.low))
    );

    texture = tester.firstWidget(find.byType(Texture));
    expect(texture, isNotNull);
    expect(texture.textureId, 1);
    expect(texture.filterQuality, FilterQuality.low);
  });
}
