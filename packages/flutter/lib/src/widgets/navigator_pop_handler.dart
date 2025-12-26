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
/// back gestures in the [onPopWithResult] callback.
///
/// The type parameter `<T>` indicates the type of the [Route]'s return value,
/// which is passed to [onPopWithResult].
///
/// {@tool dartpad}
/// This sample demonstrates how to use this widget to properly handle system
/// back gestures when using nested [Navigator]s.
///
/// ** See code in examples/api/lib/widgets/navigator_pop_handler/navigator_pop_handler.0.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// This sample demonstrates how to use this widget to properly handle system
/// back gestures with a bottom navigation bar whose tabs each have their own
/// nested [Navigator]s.
///
/// ** See code in examples/api/lib/widgets/navigator_pop_handler/navigator_pop_handler.1.dart **
/// {@end-tool}
///
/// See also:
///
///  * [PopScope], which allows toggling the ability of a [Navigator] to
///    handle pops.
///  * [NavigationNotification], which indicates whether a [Navigator] in a
///    subtree can handle pops.
@optionalTypeArgs
class NavigatorPopHandler<T> extends StatefulWidget {
  /// Creates an instance of [NavigatorPopHandler].
  const NavigatorPopHandler({
    super.key,
    @Deprecated(
      'Use onPopWithResult instead. '
      'This feature was deprecated after v3.26.0-0.1.pre.',
    )
    this.onPop,
    this.onPopWithResult,
    this.enabled = true,
    required this.child,
  }) : assert(onPop == null || onPopWithResult == null);

  /// The widget to place below this in the widget tree.
  ///
  /// Typically this is a [Navigator] that will handle the pop when
  /// [onPopWithResult] is called.
  final Widget child;

  /// Whether this widget's ability to handle system back gestures is enabled or
  /// disabled.
  ///
  /// When false, there will be no effect on system back gestures. If provided,
  /// [onPop] will still be called.
  ///
  /// This can be used, for example, when the nested [Navigator] is no longer
  /// active but remains in the widget tree, such as in an inactive tab.
  ///
  /// Defaults to true.
  final bool enabled;

  /// Called when a handleable pop event happens.
  ///
  /// For example, a pop is handleable when a [Navigator] in [child] has
  /// multiple routes on its stack. It's not handleable when it has only a
  /// single route, and so [onPop] will not be called.
  ///
  /// Typically this is used to pop the [Navigator] in [child]. See the sample
  /// code on [NavigatorPopHandler] for a full example of this.
  @Deprecated(
    'Use onPopWithResult instead. '
    'This feature was deprecated after v3.26.0-0.1.pre.',
  )
  final VoidCallback? onPop;

  /// Called when a handleable pop event happens.
  ///
  /// For example, a pop is handleable when a [Navigator] in [child] has
  /// multiple routes on its stack. It's not handleable when it has only a
  /// single route, and so [onPopWithResult] will not be called.
  ///
  /// Typically this is used to pop the [Navigator] in [child]. See the sample
  /// code on [NavigatorPopHandler] for a full example of this.
  ///
  /// The passed `result` is the result of the popped [Route].
  final PopResultCallback<T>? onPopWithResult;

  @override
  State<NavigatorPopHandler<T>> createState() => _NavigatorPopHandlerState<T>();
}

class _NavigatorPopHandlerState<T> extends State<NavigatorPopHandler<T>> {
  bool _canPop = true;

  @override
  Widget build(BuildContext context) {
    // When the widget subtree indicates it can handle a pop, disable popping
    // here, so that it can be manually handled in canPop.
    return PopScope<T>(
      canPop: !widget.enabled || _canPop,
      onPopInvokedWithResult: (bool didPop, T? result) {
        if (didPop) {
          return;
        }
        widget.onPop?.call();
        widget.onPopWithResult?.call(result);
      },
      // Listen to changes in the navigation stack in the widget subtree.
      child: NotificationListener<NavigationNotification>(
        onNotification: (NavigationNotification notification) {
          // If this subtree cannot handle pop, then set canPop to true so
          // that our PopScope will allow the Navigator higher in the tree to
          // handle the pop instead.
          final bool nextCanPop = !notification.canHandlePop;
          if (nextCanPop != _canPop) {
            setState(() {
              _canPop = nextCanPop;
            });
          }
          return false;
        },
        child: widget.child,
      ),
    );
  }
}

/// A signature for a function that is passed the result of a [Route].
typedef PopResultCallback<T> = void Function(T? result);
