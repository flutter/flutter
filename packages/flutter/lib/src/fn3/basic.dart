// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/rendering.dart';
import 'package:sky/src/fn3/framework.dart';

export 'package:sky/rendering.dart' show
    BackgroundImage,
    BlockDirection,
    Border,
    BorderSide,
    BoxConstraints,
    BoxDecoration,
    BoxDecorationPosition,
    BoxShadow,
    Color,
    EdgeDims,
    EventDisposition,
    FlexAlignItems,
    FlexDirection,
    FlexJustifyContent,
    Offset,
    Paint,
    Path,
    Point,
    Rect,
    ScrollDirection,
    Shape,
    ShrinkWrap,
    Size,
    ValueChanged;

class DecoratedBox extends OneChildRenderObjectWidget {
  DecoratedBox({
    Key key,
    this.decoration,
    this.position: BoxDecorationPosition.background,
    Widget child
  }) : super(key: key, child: child) {
    assert(decoration != null);
    assert(position != null);
  }

  final BoxDecoration decoration;
  final BoxDecorationPosition position;

  RenderObject createRenderObject() => new RenderDecoratedBox(
    decoration: decoration,
    position: position
  );

  void updateRenderObject(RenderDecoratedBox renderObject) {
    renderObject.decoration = decoration;
    renderObject.position = position;
  }
}
