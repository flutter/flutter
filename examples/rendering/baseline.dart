// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

RenderBox getBox(double lh) {
  RenderParagraph paragraph = new RenderParagraph(
    new StyledTextSpan(
      new TextStyle(
        color: const Color(0xFF0000A0)
      ),
      <TextSpan>[
        new PlainTextSpan('test'),
        new StyledTextSpan(
          new TextStyle(
            fontFamily: 'serif',
            fontSize: 50.0,
            height: lh
          ),
          <TextSpan>[new PlainTextSpan('مرحبا Hello')]
        )
      ]
    )
  );
  return new RenderPadding(
    padding: new EdgeDims.all(10.0),
    child: new RenderConstrainedBox(
      additionalConstraints: new BoxConstraints.tightFor(height: 200.0),
      child: new RenderDecoratedBox(
        decoration: new BoxDecoration(
          backgroundColor: const Color(0xFFFFFFFF)
        ),
        child: new RenderPadding(
          padding: new EdgeDims.all(10.0),
          child: new RenderCustomPaint(
            child: paragraph,
            onPaint: (PaintingCanvas canvas, Size size) {
              double baseline = paragraph.getDistanceToBaseline(TextBaseline.alphabetic);
              double w = paragraph.getMaxIntrinsicWidth(new BoxConstraints.loose(size));
              double h = paragraph.getMaxIntrinsicHeight(new BoxConstraints.loose(size));
              Path path = new Path();
              path.moveTo(0.0, 0.0);
              path.lineTo(w, 0.0);
              path.moveTo(0.0, baseline);
              path.lineTo(w, baseline);
              path.moveTo(0.0, h);
              path.lineTo(w, h);
              Paint paint = new Paint()
               ..color = const Color(0xFFFF9000)
               ..style = ui.PaintingStyle.stroke
               ..strokeWidth = 3.0;
              canvas.drawPath(path, paint);
            }
          )
        )
      )
    )
  );
}

void main() {
  RenderBox root = new RenderFlex(children: <RenderBox>[
      new RenderConstrainedBox(
        additionalConstraints: new BoxConstraints.tightFor(height: 50.0)
      ),
      getBox(1.0),
      getBox(null),
    ],
    direction: FlexDirection.vertical,
    alignItems: FlexAlignItems.stretch
  );
  new FlutterBinding(root: root);
}
