// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'debug.dart';
import 'theme.dart';

const double _kDrawerHeaderHeight = 160.0 + 1.0; // bottom edge

/// The top-most region of a material design drawer. The header's [child]
/// widget is placed inside of a [Container] whose [decoration] can be passed as
/// an argument.
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
  const DrawerHeader({
    Key key,
    this.decoration,
    this.child
  }) : super(key: key);

  /// Decoration for the main drawer header [Container]; useful for applying
  /// backgrounds.
  final BoxDecoration decoration;

  /// A widget that extends behind the system status bar and is placed inside a
  /// [Container].
  final Widget child;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    return new Container(
      height: statusBarHeight + _kDrawerHeaderHeight,
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: new BoxDecoration(
        border: const Border(
          bottom: const BorderSide(
            color: const Color(0xFFD1D9E1),
            width: 1.0
          )
        )
      ),
      child: new Container(
        padding: new EdgeInsets.only(
          top: 16.0 + statusBarHeight,
          left: 16.0,
          right: 16.0,
          bottom: 8.0
        ),
        decoration: decoration,
        child: new DefaultTextStyle(
          style: Theme.of(context).textTheme.body2,
          child: child
        )
      )
    );
  }
}
