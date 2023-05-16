// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'framework.dart';
import 'navigator.dart';
import 'routes.dart';

// TODO(justinmc): Change name to match popEnabled  more?
// TODO(justinmc): Document that this can't be set at the time of onPopCallback. Too late.
/// Manages system back gestures.
///
/// [popEnabled] can be used to disable system back gestures, while [onPop]
/// reports when they occur.
///
/// {@tool dartpad}
/// This sample demonstrates how to use this widget to properly handle system
/// back gestures when using nested [Navigator]s.
///
/// ** See code in examples/api/lib/widgets/can_pop_scope/nested_navigators.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [ModalRoute.registerCanPopScope] and [ModalRoute.unregisterCanPopScope],
///    which this widget uses to integrate with Flutter's navigation system.
///  * [Form.popEnabled] and [Form.onPop], which use this widget internally.
class CanPopScope extends StatefulWidget {
  /// Creates a widget that registers a callback to veto attempts by the user to
  /// dismiss the enclosing [ModalRoute].
  ///
  /// The [child] argument must not be null.
  const CanPopScope({
    super.key,
    required this.child,
    this.popEnabled = true,
    this.onPop,
  });

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  // TODO(justinmc): Should this be called onPopped?
  // TODO(justinmc): Document exactly when this is called. Currently after pop.
  /// {@template flutter.widgets.CanPopScope.onPop}
  /// Called immediately after a route has been popped from the current
  /// navigation stack.
  /// {@endtemplate}
  final VoidCallback? onPop;

  /// {@template flutter.widgets.CanPopScope.popEnabled}
  /// When false, blocks the current route from being popped.
  ///
  /// This includes the root route, where upon popping, the Flutter app would
  /// exit.
  ///
  /// If multiple CanPopScope widgets appear in a route's widget subtree, then
  /// each and every `popEnabled` must be `true` in order for the route to be
  /// able to pop.
  ///
  /// This may have implications for route transitions that allow some
  /// interaction before committing to popping the route. For example,
  /// [Android's predictive back](https://developer.android.com/guide/navigation/predictive-back-gesture)
  /// feature will not animate at all when this boolean is true.
  /// {@endtemplate}
  final bool popEnabled;

  @override
  State<CanPopScope> createState() => _CanPopScopeState();
}

class _CanPopScopeState extends State<CanPopScope> {
  ModalRoute<dynamic>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
    _route?.registerCanPopScope(widget);
  }

  @override
  void didUpdateWidget(CanPopScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    _route = ModalRoute.of(context);
    _route?.unregisterCanPopScope(oldWidget);
    _route?.registerCanPopScope(widget);
  }

  @override
  void dispose() {
    _route?.unregisterCanPopScope(widget);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
