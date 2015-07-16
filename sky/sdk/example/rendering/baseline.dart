// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/painting/text_style.dart';
import 'package:sky/rendering/box.dart';
import 'package:sky/rendering/flex.dart';
import 'package:sky/rendering/object.dart';
import 'package:sky/rendering/paragraph.dart';
import 'package:sky/rendering/sky_binding.dart';

RenderBox getBox(double lh) {
  RenderParagraph paragraph = new RenderParagraph(
    new InlineStyle(
      new TextStyle(
        color: const Color(0xFF0000A0)
      ),
      [
        new InlineText('test'),
        new InlineStyle(
          new TextStyle(
            fontFamily: 'serif',
            fontSize: 50.0,
            height: lh
          ),
          [new InlineText('مرحبا Hello')]
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
            callback: (canvas, size) {
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
              Paint paint = new Paint();
              paint.color = const Color(0xFFFF9000);
              paint.setStyle(sky.PaintingStyle.stroke);
              paint.strokeWidth = 3.0;
              canvas.drawPath(path, paint);  
            }
          )
        )
      )
    )
  );
}

void main() {
  RenderBox root = new RenderFlex(children: [
      new RenderConstrainedBox(
        additionalConstraints: new BoxConstraints.tightFor(height: 50.0)
      ),
      getBox(1.0),
      getBox(null),
    ],
    direction: FlexDirection.vertical,
    alignItems: FlexAlignItems.stretch
  );
  new SkyBinding(root: root);
}
