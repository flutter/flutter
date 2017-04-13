// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';

/// Return the size this widget would prefer if it were otherwise unconstrained.
///
/// There are a few cases, notably [AppBar] and [TabBar], where it would be
/// undesirable for the widget to constrain its own size but where the widget
/// needs to expose a preferred or "default" size. For example a primary
/// [Scaffold] sets its app bar height to the app bar's preferred height
/// plus the height of the system status bar.
///
/// Use [PreferredSize] to give a preferred size to an arbitrary widget.
abstract class PreferredSizeWidget extends Widget {
  Size get preferredSize;
}

/// Give an arbitrary widget a preferred size.
///
/// This class does not impose any constraints on its child, it doesn't affect
/// the child's layout in any way. It just advertises a default size which
/// can be used by the parent.
///
/// See also:
///
///  * [AppBar.bottom] and [Scaffold.appBar], which require preferred size widgets.
class PreferredSize extends StatelessWidget implements PreferredSizeWidget {
  const PreferredSize({
    Key key,
    @required this.child,
    @required this.preferredSize,
  }) : super(key: key);

  final Widget child;

  @override
  final Size preferredSize;

  @override
  Widget build(BuildContext context) => child;
}
