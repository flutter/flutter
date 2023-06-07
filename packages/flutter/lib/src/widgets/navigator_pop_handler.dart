// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'framework.dart';
import 'navigator.dart';
import 'notification_listener.dart';
import 'pop_scope.dart';

/// Enables the handling of system back gestures.
///
/// Typically wraps a nested [Navigator] widget and allows it to handle system
/// back gestures in the [onPop] callback.
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
///  * [PopScope], which allows toggling the ability of a [Navigator] to
///    handle pops.
///  * [NavigationNotification], which indicates whether a [Navigator] in a
///    subtree can handle pops.
class NavigatorPopHandler extends StatefulWidget {
  /// Creates an instance of [NavigatorPophandler].
  const NavigatorPopHandler({
    super.key,
    required this.child,
    this.onPop,
  });

  /// The widget to place below this in the widget tree.
  ///
  /// Typically this is a [Navigator] that will handle the pop when [onPop] is
  /// called.
  final Widget child;

  /// Called when a handleable pop event happens.
  ///
  /// A pop is handleable when the most recent [NavigationNotification.canPop]
  /// was true.
  ///
  /// Typically this is used to pop the [Navigator] in [child].  See the sample
  /// code on [Navigator] for a full example of this.
  final VoidCallback? onPop;

  @override
  State<NavigatorPopHandler> createState() => _NavigatorPopHandlerState();
}

class _NavigatorPopHandlerState extends State<NavigatorPopHandler> {
  bool _popEnabled = true;

  @override
  Widget build(BuildContext context) {
    // When the widget subtree indicates it can handle a pop, disable popping
    // here, so that it can be manually handled in canPop.
    return PopScope(
      popEnabled: _popEnabled,
      onPopped: (bool success) {
        if (success) {
          return;
        }
        widget.onPop?.call();
      },
      // Listen to changes in the navigation stack in the widget subtree.
      child: NotificationListener<NavigationNotification>(
        onNotification: (NavigationNotification notification) {
          final bool nextPopEnabled = !notification.canPop;
          if (nextPopEnabled != _popEnabled) {
            setState(() {
              _popEnabled = nextPopEnabled;
            });
          }
          return false;
        },
        child: widget.child,
      ),
    );
  }
}
