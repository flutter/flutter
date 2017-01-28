// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:mockito/mockito_no_mirrors.dart';
import 'package:test/test.dart';

import 'rendering_tester.dart';

class MockPaintingContext extends Mock implements PaintingContext {}
class MockCanvas extends Mock implements Canvas {}

/// Unit tests error.dart behaviors.
void main() {
  final String errorMessage = 'Some error message';
  MockCanvas mockCanvas;
  MockPaintingContext mockPaintingContext;

  setUp(() {
    mockPaintingContext = new MockPaintingContext();
    mockCanvas = new MockCanvas();
    when(mockPaintingContext.canvas).thenReturn(mockCanvas);
  });

  /// Error message should be drawn at an offset when
  test('offset error text on tall windows', () async {
    await runZoned(() async {
      RenderErrorBox errorBoxUnderTest = new RenderErrorBox(errorMessage);
      layout(errorBoxUnderTest);
      errorBoxUnderTest.paint(mockPaintingContext, Offset.zero);
      verify(mockCanvas.drawRect(typed(any), typed(any)));
      verify(mockCanvas.drawParagraph(typed(any), new Offset(0.0, 100.0)));
    }, zoneValues: <String, double>{
      'systemTopPadding': 100.0
    });
  });

  test('no offset on short windows', () async {
    await runZoned(() async {
      RenderErrorBox errorBoxUnderTest = new RenderErrorBox(errorMessage);
      // Assuming 10 logical pixels high is really short.
      layout(errorBoxUnderTest, constraints: new BoxConstraints(maxHeight: 10.0));
      errorBoxUnderTest.paint(mockPaintingContext, Offset.zero);
      verify(mockCanvas.drawRect(typed(any), typed(any)));
      // Assert paragraph still drawn at zero offset.
      verify(mockCanvas.drawParagraph(typed(any), Offset.zero));
    }, zoneValues: <String, double>{
      'systemTopPadding': 100.0
    });
  });
}
