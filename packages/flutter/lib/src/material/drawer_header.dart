// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'debug.dart';
import 'theme.dart';

const double _kDrawerHeaderHeight = 140.0;

/// The top-most region of a material design drawer. The header's [background]
/// widget extends behind the system status bar and its [content] widget is
/// stacked on top of the background and below the status bar.
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
  const DrawerHeader({ Key key, this.background, this.content }) : super(key: key);

  /// A widget that extends behind the system status bar and is stacked
  /// behind the [content] widget.
  final Widget background;

  /// A widget that's positioned below the status bar and stacked on top of the
  /// [background] widget. Typically a view of the user's id.
  final Widget content;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    return new Container(
      height: statusBarHeight + _kDrawerHeaderHeight,
      margin: const EdgeInsets.only(bottom: 7.0), // 8 less 1 for the bottom border.
      decoration: new BoxDecoration(
        border: const Border(
          bottom: const BorderSide(
            color: const Color(0xFFD1D9E1),
            width: 1.0
          )
        )
      ),
      child: new Stack(
        children: <Widget>[
          background ?? new Container(),
          new Positioned(
            top: statusBarHeight + 16.0,
            left: 16.0,
            right: 16.0,
            bottom: 8.0,
            child: new DefaultTextStyle(
              style: Theme.of(context).textTheme.body2,
              child: content
            )
          )
        ]
      )
    );
  }
}
