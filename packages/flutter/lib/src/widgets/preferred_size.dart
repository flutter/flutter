// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';

/// An interface for widgets that can return the size this widget would prefer
/// if it were otherwise unconstrained.
///
/// There are a few cases, notably [AppBar] and [TabBar], where it would be
/// undesirable for the widget to constrain its own size but where the widget
/// needs to expose a preferred or "default" size. For example a primary
/// [Scaffold] sets its app bar height to the app bar's preferred height
/// plus the height of the system status bar.
///
/// Use [PreferredSize] to give a preferred size to an arbitrary widget.
abstract class PreferredSizeWidget implements Widget {

  /// The size this widget would prefer if it were otherwise unconstrained.
  ///
  /// In many cases it's only necessary to define one preferred dimension.
  /// For example the [Scaffold] only depends on its app bar's preferred
  /// height. In that case implementations of this method can just return
  /// `new Size.fromHeight(myAppBarHeight)`.
  Size get preferredSize;
}

/// A widget with a preferred size.
///
/// This widget does not impose any constraints on its child, and it doesn't
/// affect the child's layout in any way. It just advertises a preferred size
/// which can be used by the parent.
///
/// See also:
///
///  * [AppBar.bottom] and [Scaffold.appBar], which require preferred size widgets.
///  * [PreferredSizeWidget], the interface which this widget implements to expose
///    its preferred size.
///  * [AppBar] and [TabBar], which implement PreferredSizeWidget.
class PreferredSize extends StatelessWidget implements PreferredSizeWidget {
  /// Creates a widget that has a preferred size.
  const PreferredSize({
    Key key,
    @required this.child,
    @required this.preferredSize,
  }) : super(key: key);

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  @override
  final Size preferredSize;

  @override
  Widget build(BuildContext context) => child;
}
