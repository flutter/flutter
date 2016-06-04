// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';

import 'framework.dart';
import 'media_query.dart';

export 'package:flutter/rendering.dart' show ChildViewConnection;

/// (mojo-only) A widget that is replaced by content from another process.
///
/// Requires a [MediaQuery] ancestor to provide appropriate media information to
/// the child.
class ChildView extends StatelessWidget {
  /// Creates a widget that is replaced by content from another process.
  ChildView({ Key key, this.child }) : super(key: key);

  /// A connection to the child whose content will replace this widget.
  final ChildViewConnection child;

  @override
  Widget build(BuildContext context) {
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
  }) : child = child, super(key: new GlobalObjectKey(child)) {
    assert(scale != null);
  }

  final ChildViewConnection child;
  final double scale;

  @override
  RenderChildView createRenderObject(BuildContext context) => new RenderChildView(child: child, scale: scale);

  @override
  void updateRenderObject(BuildContext context, RenderChildView renderObject) {
    renderObject
      ..child = child
      ..scale = scale;
  }
}
