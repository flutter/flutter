// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'window_size_class.dart';

/// Signature for a function that creates a widget, e.g. [StatelessWidget.build]
/// or [State.build] based on the [WindowSizeClass].
///
/// Used by [ResponsiveBuilder.builder].
///
/// See also:
///
///  * [WidgetBuilder], which is similar but only takes the context.
///  * [IndexedWidgetBuilder], which is similar but takes an index.
///  * [TransitionBuilder], which is similar but takes a child.
///  * [ValueWidgetBuilder], which is similar but takes a value and a child.
typedef ResponsiveWidgetBuilder = Widget Function(BuildContext context, WindowSizeClass windowSizeClass);

/// A [StatelessWidget] that can be used to build a responsive layout based on
/// the [WindowSizeClass].
///
/// See also:
///
///  * [LayoutBuilder], a widget that builds a widget tree that can depend on the parent widget's size.
class ResponsiveBuilder extends StatelessWidget {
  /// Creates a widget that build a responsive layout based on the [WindowSizeClass].
  const ResponsiveBuilder({super.key, required this.builder});

  /// Called to obtain the child widget.
  ///
  /// This function is called whenever this widget is included in its parent's
  /// build and either the old widget (if any) that it synchronizes with has a
  /// distinct object identity or the [WindowSizeClass] might have changed.
  final ResponsiveWidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final WindowSizeClass windowSizeClass = WindowSizeClass.fromSize(MediaQuery.of(context).size);

    return builder(context, windowSizeClass);
  }
}
