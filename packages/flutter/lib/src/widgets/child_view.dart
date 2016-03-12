// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';

import 'media_query.dart';
import 'framework.dart';

export 'package:flutter/rendering.dart' show ChildViewConnection;

class ChildView extends StatelessWidget {
  ChildView({ Key key, this.child }) : super(key: key);

  final ChildViewConnection child;

  Widget build(BuildContext context) {
    assert(MediaQuery.of(context) != null);
    return new _ChildViewWidget(
      child: child,
      scale: MediaQuery.of(context).devicePixelRatio
    );
  }
}

class _ChildViewWidget extends LeafRenderObjectWidget {
  _ChildViewWidget({
    ChildViewConnection child,
    this.scale
  }) : child = child, super(key: new GlobalObjectKey(child));

  final ChildViewConnection child;
  final double scale;

  RenderChildView createRenderObject(BuildContext context) => new RenderChildView(child: child, scale: scale);

  void updateRenderObject(BuildContext context, RenderChildView renderObject) {
    renderObject
      ..child = child
      ..scale = scale;
  }
}
