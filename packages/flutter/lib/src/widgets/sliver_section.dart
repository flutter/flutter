// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A sliver that lays out multiple sliver children along the main axis of the viewport.
class SliverSection extends MultiChildRenderObjectWidget {
  /// Creates a sliver that lays out it children along the main axis of the viewport
  SliverSection({
    Key key,
    Widget header,
    Widget body,
    bool pushPinnedHeaders = true,
  }) : _pushPinnedHeaders = pushPinnedHeaders,
      super(key: key, children: <Widget>[header, body]);

  final bool _pushPinnedHeaders;

  @override
  RenderSliverSection createRenderObject(BuildContext context) {
    return RenderSliverSection(
      key: key,
      pushPinnedHeaders: _pushPinnedHeaders,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderSliverSection renderObject) {
    renderObject.pushPinnedHeaders = _pushPinnedHeaders;
  }
}