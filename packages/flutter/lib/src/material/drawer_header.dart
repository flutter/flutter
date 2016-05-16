// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'debug.dart';
import 'theme.dart';

const double _kDrawerHeaderHeight = 140.0;

/// The top-most region of a material design drawer.
///
/// Part of the material design [Drawer].
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// See also:
///
///  * [Drawer]
///  * [DrawerItem]
///  * <https://www.google.com/design/spec/patterns/navigation-drawer.html>
class DrawerHeader extends StatelessWidget {
  /// Creates a material design drawer header.
  ///
  /// Requires one of its ancestors to be a [Material] widget.
  const DrawerHeader({ Key key, this.child }) : super(key: key);

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    return new Container(
      height: statusBarHeight + _kDrawerHeaderHeight,
      decoration: new BoxDecoration(
        // TODO(jackson): This class should usually render the user's
        // preferred banner image rather than a solid background
        backgroundColor: Theme.of(context).cardColor,
        border: const Border(
          bottom: const BorderSide(
            color: const Color(0xFFD1D9E1),
            width: 1.0
          )
        )
      ),
      padding: const EdgeInsets.only(bottom: 7.0),
      margin: const EdgeInsets.only(bottom: 8.0),
      child: new Column(
        children: <Widget>[
          new Flexible(child: new Container()),
          new Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: new DefaultTextStyle(
              style: Theme.of(context).textTheme.body2,
              child: child
            )
          )
        ]
      )
    );
  }
}
