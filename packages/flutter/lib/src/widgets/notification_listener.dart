// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/foundation.dart';

import 'framework.dart';

/// Signature for [Notification] listeners.
///
/// Return true to cancel the notification bubbling. Return false to allow the
/// notification to continue to be dispatched to further ancestors.
///
/// Used by [NotificationListener.onNotification].
typedef NotificationListenerCallback<T extends Notification> = bool Function(T notification);

/// A notification that can bubble up the widget tree.
///
/// You can determine the type of a notification using the `is` operator to
/// check the [runtimeType] of the notification.
///
/// To listen for notifications in a subtree, use a [NotificationListener].
///
/// To send a notification, call [dispatch] on the notification you wish to
/// send. The notification will be delivered to any [NotificationListener]
/// widgets with the appropriate type parameters that are ancestors of the given
/// [BuildContext].
abstract class Notification {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const Notification();

  /// Applied to each ancestor of the [dispatch] target.
  ///
  /// The [Notification] class implementation of this method dispatches the
  /// given [Notification] to each ancestor [NotificationListener] widget.
  ///
  /// Subclasses can override this to apply additional filtering or to update
  /// the notification as it is bubbled (for example, increasing a `depth` field
  /// for each ancestor of a particular type).
  @protected
  @mustCallSuper
  bool visitAncestor(Element element) {
    if (element is StatelessElement) {
      final StatelessWidget widget = element.widget;
      if (widget is NotificationListener<Notification>) {
        if (widget._dispatch(this, element)) // that function checks the type dynamically
          return false;
      }
    }
    return true;
  }

  /// Start bubbling this notification at the given build context.
  ///
  /// The notification will be delivered to any [NotificationListener] widgets
  /// with the appropriate type parameters that are ancestors of the given
  /// [BuildContext]. If the [BuildContext] is null, the notification is not
  /// dispatched.
  void dispatch(BuildContext target) {
    // The `target` may be null if the subtree the notification is supposed to be
    // dispatched in is in the process of being disposed.
    target?.visitAncestorElements(visitAncestor);
  }

  @override
  String toString() {
    final List<String> description = <String>[];
    debugFillDescription(description);
    return '${objectRuntimeType(this, 'Notification')}(${description.join(", ")})';
  }

  /// Add additional information to the given description for use by [toString].
  ///
  /// This method makes it easier for subclasses to coordinate to provide a
  /// high-quality [toString] implementation. The [toString] implementation on
  /// the [Notification] base class calls [debugFillDescription] to collect
  /// useful information from subclasses to incorporate into its return value.
  ///
  /// If you override this, make sure to start your method with a call to
  /// `super.debugFillDescription(description)`.
  @protected
  @mustCallSuper
  void debugFillDescription(List<String> description) { }
}

/// A widget that listens for [Notification]s bubbling up the tree.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=cAnFbFoGM50}
///
/// Notifications will trigger the [onNotification] callback only if their
/// [runtimeType] is a subtype of `T`.
///
/// To dispatch notifications, use the [Notification.dispatch] method.
class NotificationListener<T extends Notification> extends StatelessWidget {
  /// Creates a widget that listens for notifications.
  const NotificationListener({
    Key key,
    @required this.child,
    this.onNotification,
  }) : super(key: key);

  /// The widget directly below this widget in the tree.
  ///
  /// This is not necessarily the widget that dispatched the notification.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// Called when a notification of the appropriate type arrives at this
  /// location in the tree.
  ///
  /// Return true to cancel the notification bubbling. Return false (or null) to
  /// allow the notification to continue to be dispatched to further ancestors.
  ///
  /// The notification's [Notification.visitAncestor] method is called for each
  /// ancestor, and invokes this callback as appropriate.
  ///
  /// Notifications vary in terms of when they are dispatched. There are two
  /// main possibilities: dispatch between frames, and dispatch during layout.
  ///
  /// For notifications that dispatch during layout, such as those that inherit
  /// from [LayoutChangedNotification], it is too late to call [State.setState]
  /// in response to the notification (as layout is currently happening in a
  /// descendant, by definition, since notifications bubble up the tree). For
  /// widgets that depend on layout, consider a [LayoutBuilder] instead.
  final NotificationListenerCallback<T> onNotification;

  bool _dispatch(Notification notification, Element element) {
    if (onNotification != null && notification is T) {
      final bool result = onNotification(notification);
      return result == true; // so that null and false have the same effect
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => child;
}

/// Indicates that the layout of one of the descendants of the object receiving
/// this notification has changed in some way, and that therefore any
/// assumptions about that layout are no longer valid.
///
/// Useful if, for instance, you're trying to align multiple descendants.
///
/// To listen for notifications in a subtree, use a
/// [NotificationListener<LayoutChangedNotification>].
///
/// To send a notification, call [dispatch] on the notification you wish to
/// send. The notification will be delivered to any [NotificationListener]
/// widgets with the appropriate type parameters that are ancestors of the given
/// [BuildContext].
///
/// In the widgets library, only the [SizeChangedLayoutNotifier] class and
/// [Scrollable] classes dispatch this notification (specifically, they dispatch
/// [SizeChangedLayoutNotification]s and [ScrollNotification]s respectively).
/// Transitions, in particular, do not. Changing one's layout in one's build
/// function does not cause this notification to be dispatched automatically. If
/// an ancestor expects to be notified for any layout change, make sure you
/// either only use widgets that never change layout, or that notify their
/// ancestors when appropriate, or alternatively, dispatch the notifications
/// yourself when appropriate.
///
/// Also, since this notification is sent when the layout is changed, it is only
/// useful for paint effects that depend on the layout. If you were to use this
/// notification to change the build, for instance, you would always be one
/// frame behind, which would look really ugly and laggy.
class LayoutChangedNotification extends Notification { }
