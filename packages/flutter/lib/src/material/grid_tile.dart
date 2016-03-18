// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// Creates a [Stack] with the header anchored across the top or a footer across the
/// bottom. The [GridTileBar] class can be used to create grid tile headers and footers.
class GridTile extends StatelessWidget {
  GridTile({ Key key, this.header, this.footer, this.child }) : super(key: key) {
    assert(child != null);
  }

  /// The widget to show over the top of this grid tile.
  final Widget header;

  /// The widget to show over the bottom of this grid tile.
  final Widget footer;

  /// The widget that fills the tile.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (header == null && footer == null)
      return child;

    final List<Widget> children = <Widget>[
      new Positioned(
        top: 0.0,
        left: 0.0,
        bottom: 0.0,
        right: 0.0,
        child: child
      )
    ];
    if (header != null) {
      children.add(new Positioned(
        top: 0.0,
        left: 0.0,
        right: 0.0,
        child: header
      ));
    }
    if (footer != null) {
      children.add(new Positioned(
        left: 0.0,
        bottom: 0.0,
        right: 0.0,
        child: footer
      ));
    }
    return new Stack(children: children);
  }
}
