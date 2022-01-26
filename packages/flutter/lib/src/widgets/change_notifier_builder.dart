// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'basic.dart';
import 'framework.dart';

/// Builds a [Widget] when given a concrete value of a [ChangeNotifier].
///
/// If the `child` parameter provided to the [ChangeNotifierBuilder] is not
/// null, the same `child` widget is passed back to this
/// [ChangeNotifierWidgetBuilder] and should typically be incorporated in the
/// returned widget tree.
///
/// See also:
///
///  * [ChangeNotifierBuilder], a widget which invokes this builder each time
///    a [ChangeNotifier] changes value.
typedef ChangeNotifierWidgetBuilder<T> = Widget Function(BuildContext context, Widget? child);

/// A widget whose content stays synced with a [ChangeNotifier].
///
/// Given a [ChangeNotifier] and a [builder] which builds widgets from
/// subtypes of `ChangeNotifier`, this class will automatically register itself
/// as a listener of the [ChangeNotifier] and call the [builder] whenever
/// listeners are notified.
///
/// An [AnimatedBuilder] could be used instead of this widget but it doesn't
/// have a [listenCondition] callback and it's not specialized to only listen to
/// [ChangeNotifier]s.
///
/// ## Performance optimizations
///
/// If your [builder] function contains a subtree that does not depend on the
/// value of the [ChangeNotifier], it's more efficient to build that subtree
/// once instead of rebuilding it on every listener notification.
///
/// If you pass the pre-built subtree as the [child] parameter, the
/// [ChangeNotifierBuilder] will pass it back to your [builder] function so
/// that you can incorporate it into your build.
///
/// Using this pre-built child is entirely optional, but can improve
/// performance significantly in some cases and is therefore a good practice.
///
/// See also:
///
///  * [AnimatedBuilder], which can trigger rebuilds from a [Listenable].
///  * [NotificationListener], which lets you rebuild based on [Notification]
///    coming from its descendant widgets rather than a [ValueListenable] that
///    you have a direct reference to.
///  * [ValueListenableBuilder], which can trigger rebuilds from a
///  [ValueNotifier].
class ChangeNotifierBuilder<T extends ChangeNotifier> extends StatefulWidget {
  /// Creates a widget that rebuilds whenever the given change notifier notifies
  /// its listeners.
  ///
  /// The [changeNotifier] and [builder] arguments are required.
  ///
  /// The [child] is optional but is good practice to use if part of the widget
  /// subtree does not depend on the value of the [changeNotifier].
  ///
  /// The [listenCondition] is also optional and it can be used to control when
  /// the [builder] should be called.
  const ChangeNotifierBuilder({
    Key? key,
    required this.changeNotifier,
    required this.builder,
    this.listenCondition,
    this.child,
  }) : super(key: key);

  /// The [ChangeNotifier] whose value you depend on in order to build.
  final T changeNotifier;

  /// A [ChangeNotifierWidgetBuilder] which builds a widget depending on the
  /// [changeNotifier]'s status.
  ///
  /// Can incorporate a [changeNotifier]-independent widget subtree
  /// from the [child] parameter into the returned widget tree.
  final ChangeNotifierWidgetBuilder<T> builder;

  /// The listening condition for the [builder].
  ///
  /// This callback can be used to determine under which conditions the
  /// [builder] function has to be invoked. For example, if this callback
  /// returned false, the [builder] would never be called.
  ///
  /// By default, this is null so the [builder] il always called whenever the
  /// [changeNotifier] notifies its listeners.
  final bool Function()? listenCondition;

  /// The child widget to pass to the [builder].
  ///
  /// If a [builder] callback's return value contains a subtree that does not
  /// depend on [changeNotifier], it's more efficient to build that subtree once
  /// instead of rebuilding it on every animation tick.
  ///
  /// If the pre-built subtree is passed as the [child] parameter, the
  /// [ChangeNotifierBuilder] will pass it back to the [builder] function so
  /// that it can be incorporated into the build.
  ///
  /// Using this pre-built child is entirely optional, but can improve
  /// performance significantly in some cases and is therefore a good practice.
  final Widget? child;

  @override
  State<ChangeNotifierBuilder<T>> createState() => _ChangeNotifierBuilderState<T>();
}

class _ChangeNotifierBuilderState<T extends ChangeNotifier> extends State<ChangeNotifierBuilder<T>> {
  @override
  void initState() {
    super.initState();
    widget.changeNotifier.addListener(_handleChange);
  }

  @override
  void didUpdateWidget(covariant ChangeNotifierBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.changeNotifier != oldWidget.changeNotifier) {
      oldWidget.changeNotifier.removeListener(_handleChange);
      widget.changeNotifier.addListener(_handleChange);
    }
  }

  @override
  void dispose() {
    widget.changeNotifier.removeListener(_handleChange);
    super.dispose();
  }

  void _handleChange() {
    if (widget.listenCondition != null) {
      // Rebuilding only if the listening condition evaluates to true
      if (widget.listenCondition!()) {
        setState(() {
          // The listenable's state is our build state, and it changed already.
        });
      }
    } else {
      setState(() {
        // The listenable's state is our build state, and it changed already.
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.child);
  }
}
