// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'framework.dart';
import 'navigator.dart';
import 'routes.dart';

/// Manages system back gestures.
///
/// The [canPop] parameter can be used to disable system back gestures. Defaults
/// to true, meaning that back gestures happen as usual.
///
/// The [onPopInvoked] parameter reports when system back gestures occur,
/// regardless of whether or not they were successful.
///
/// If [canPop] is false, then a system back gesture will not pop the route off
/// of the enclosing [Navigator]. [onPopInvoked] will still be called, and
/// `didPop` will be `false`.
///
/// If [canPop] is true, then a system back gesture will cause the enclosing
/// [Navigator] to receive a pop as usual. [onPopInvoked] will be called with
/// `didPop` as `true`, unless the pop failed for reasons unrelated to
/// [PopScope], in which case it will be `false`.
///
/// {@tool dartpad}
/// This sample demonstrates how to use this widget to handle nested navigation
/// in a bottom navigation bar.
///
/// ** See code in examples/api/lib/widgets/pop_scope/pop_scope.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [NavigatorPopHandler], which is a less verbose way to handle system back
///    gestures in simple cases of nested [Navigator]s.
///  * [Form.canPop] and [Form.onPopInvoked], which can be used to handle system
///    back gestures in the case of a form with unsaved data.
///  * [ModalRoute.registerPopEntry] and [ModalRoute.unregisterPopEntry],
///    which this widget uses to integrate with Flutter's navigation system.
class PopScope extends StatefulWidget {
  /// Creates a widget that registers a callback to veto attempts by the user to
  /// dismiss the enclosing [ModalRoute].
  const PopScope({
    super.key,
    required this.child,
    this.canPop = true,
    this.onPopInvoked,
  });

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  /// {@template flutter.widgets.PopScope.onPopInvoked}
  /// Called after a route pop was handled.
  /// {@endtemplate}
  ///
  /// It's not possible to prevent the pop from happening at the time that this
  /// method is called; the pop has already happened. Use [canPop] to
  /// disable pops in advance.
  ///
  /// This will still be called even when the pop is canceled. A pop is canceled
  /// when the relevant [Route.popDisposition] returns false, such as when
  /// [canPop] is set to false on a [PopScope]. The `didPop` parameter
  /// indicates whether or not the back navigation actually happened
  /// successfully.
  ///
  /// See also:
  ///
  ///  * [Route.onPopInvoked], which is similar.
  final PopInvokedCallback? onPopInvoked;

  /// {@template flutter.widgets.PopScope.canPop}
  /// When false, blocks the current route from being popped.
  ///
  /// This includes the root route, where upon popping, the Flutter app would
  /// exit.
  ///
  /// If multiple [PopScope] widgets appear in a route's widget subtree, then
  /// each and every `canPop` must be `true` in order for the route to be
  /// able to pop.
  ///
  /// [Android's predictive back](https://developer.android.com/guide/navigation/predictive-back-gesture)
  /// feature will not animate when this boolean is false.
  /// {@endtemplate}
  final bool canPop;

  @override
  State<PopScope> createState() => _PopScopeState();
}

class _PopScopeState extends State<PopScope> implements PopEntry {
  ModalRoute<dynamic>? _route;

  @override
  PopInvokedCallback? get onPopInvoked => widget.onPopInvoked;

  @override
  late final ValueNotifier<bool> canPopNotifier;

  @override
  void initState() {
    super.initState();
    canPopNotifier = ValueNotifier<bool>(widget.canPop);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute<dynamic>? nextRoute = ModalRoute.of(context);
    if (nextRoute != _route) {
      _route?.unregisterPopEntry(this);
      _route = nextRoute;
      _route?.registerPopEntry(this);
    }
  }

  @override
  void didUpdateWidget(PopScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    canPopNotifier.value = widget.canPop;
  }

  @override
  void dispose() {
    _route?.unregisterPopEntry(this);
    canPopNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
