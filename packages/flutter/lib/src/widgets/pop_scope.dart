// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'framework.dart';
import 'navigator.dart';
import 'routes.dart';

/// A callback type for informing that a navigation pop has happened.
///
/// Accepts a didPop boolean indicating whether or not back navigation
/// succeeded.
typedef OnPoppedCallback = void Function(bool didPop);

/// Manages system back gestures.
///
/// The [popEnabled] parameter can be used to disable system back gestures.
///
/// The [onPopped] parameter reports when system back gestures occur, regardless
/// of whether or not they were successful.
///
/// {@tool dartpad}
/// This sample demonstrates how to use this widget to properly handle system
/// back gestures when using nested [Navigator]s.
///
/// ** See code in examples/api/lib/widgets/pop_scope/pop_scope.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [NavigatorPopHandler], which is a less verbose way to handle system back
///    gestures in the case of nested [Navigator]s.
///  * [Form.popEnabled] and [Form.onPopped], which can be used to handle system
///    back gestures in the case of a form with unsaved data.
///  * [ModalRoute.registerPopScope] and [ModalRoute.unregisterPopScope],
///    which this widget uses to integrate with Flutter's navigation system.
class PopScope extends StatefulWidget {
  /// Creates a widget that registers a callback to veto attempts by the user to
  /// dismiss the enclosing [ModalRoute].
  ///
  /// The [child] argument must not be null.
  const PopScope({
    super.key,
    required this.child,
    this.popEnabled = true,
    this.onPopped,
  });

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  /// Called after a route pop was handled.
  ///
  /// It's not possible to prevent the pop from happening at the time that this
  /// method is called; the pop has already happened. Use [popEnabled] to
  /// disable pops in advance.
  ///
  /// This will still be called even when the pop is canceled. A pop is canceled
  /// when the relevant [Route.popEnabled] returns false, such as when
  /// [popEnabled] is set to false on a [PopScope]. The `didPop` parameter
  /// indicates whether or not the back navigation actually happened
  /// successfully.
  ///
  /// See also:
  ///
  ///  * [Route.onPopped], which is similar.
  final OnPoppedCallback? onPopped;

  /// {@template flutter.widgets.PopScope.popEnabled}
  /// When false, blocks the current route from being popped.
  ///
  /// This includes the root route, where upon popping, the Flutter app would
  /// exit.
  ///
  /// If multiple [PopScope] widgets appear in a route's widget subtree, then
  /// each and every `popEnabled` must be `true` in order for the route to be
  /// able to pop.
  ///
  /// [Android's predictive back](https://developer.android.com/guide/navigation/predictive-back-gesture)
  /// feature will not animate when this boolean is false.
  /// {@endtemplate}
  final bool popEnabled;

  @override
  State<PopScope> createState() => _PopScopeState();
}

class _PopScopeState extends State<PopScope> {
  ModalRoute<dynamic>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
    _route?.registerPopScope(widget);
  }

  @override
  void didUpdateWidget(PopScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    _route = ModalRoute.of(context);
    _route?.unregisterPopScope(oldWidget);
    _route?.registerPopScope(widget);
  }

  @override
  void dispose() {
    _route?.unregisterPopScope(widget);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
