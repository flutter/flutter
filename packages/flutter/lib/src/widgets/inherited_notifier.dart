// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'framework.dart';

/// An inherited widget for a [Listenable] [notifier], which updates its
/// dependencies when the [notifier] is triggered.
///
/// This is a variant of [InheritedWidget], specialised for subclasses of
/// [Listenable], such as [ChangeNotifier] or [ValueNotifier].
///
/// Dependents are notified whenever the [notifier] sends notifications, or
/// whenever the identity of the [notifier] changes.
///
/// Multiple notifications are coalesced, so that dependents only rebuild once
/// even if the [notifier] fires multiple times between two frames.
///
/// Typically this class is subclassed with a class that provides an `of` static
/// method that calls [BuildContext.inheritFromWidgetOfExactType] with that
/// class.
///
/// The [updateShouldNotify] method may also be overridden, to change the logic
/// in the cases where [notifier] itself is changed. The [updateShouldNotify]
/// method is called with the old [notifier] in the case of the [notifier] being
/// changed. When it returns true, the dependents are marked as needing to be
/// rebuilt this frame.
///
/// See also:
///
///  * [Animation], an implementation of [Listenable] that ticks each frame to
///    update a value.
///  * [ViewportOffset] or its subclass [ScrollPosition], implementations of
///    [Listenable] that trigger when a view is scrolled.
///  * [InheritedWidget], an inherited widget that only notifies dependents
///    when its value is different.
///  * [InheritedModel], an inherited widget that allows clients to subscribe
///    to changes for subparts of the value.
abstract class InheritedNotifier<T extends Listenable> extends InheritedWidget {
  /// Create an inherited widget that updates its dependents when [notifier]
  /// sends notifications.
  ///
  /// The [child] argument must not be null.
  const InheritedNotifier({
    Key key,
    this.notifier,
    @required Widget child,
  }) : assert(child != null),
       super(key: key, child: child);

  /// The [Listenable] object to which to listen.
  ///
  /// Whenever this object sends change notifications, the dependents of this
  /// widget are triggered.
  ///
  /// By default, whenever the [notifier] is changed (including when changing to
  /// or from null), if the old notifier is not equal to the new notifier (as
  /// determined by the `==` operator), notifications are sent. This behavior
  /// can be overridden by overriding [updateShouldNotify].
  ///
  /// While the [notifier] is null, no notifications are sent, since the null
  /// object cannot itself send notifications.
  final T notifier;

  @override
  bool updateShouldNotify(InheritedNotifier<T> oldWidget) {
    return oldWidget.notifier != notifier;
  }

  @override
  _InheritedNotifierElement<T> createElement() => _InheritedNotifierElement<T>(this);
}

class _InheritedNotifierElement<T extends Listenable> extends InheritedElement {
  _InheritedNotifierElement(InheritedNotifier<T> widget) : super(widget) {
    widget.notifier?.addListener(_handleUpdate);
  }

  @override
  InheritedNotifier<T> get widget => super.widget;

  bool _dirty = false;

  @override
  void update(InheritedNotifier<T> newWidget) {
    final T oldNotifier = widget.notifier;
    final T newNotifier = newWidget.notifier;
    if (oldNotifier != newNotifier) {
      oldNotifier?.removeListener(_handleUpdate);
      newNotifier?.addListener(_handleUpdate);
    }
    super.update(newWidget);
  }

  @override
  Widget build() {
    if (_dirty)
      notifyClients(widget);
    return super.build();
  }

  void _handleUpdate() {
    _dirty = true;
    markNeedsBuild();
  }

  @override
  void notifyClients(InheritedNotifier<T> oldWidget) {
    super.notifyClients(oldWidget);
    _dirty = false;
  }

  @override
  void unmount() {
    widget.notifier?.removeListener(_handleUpdate);
    super.unmount();
  }
}
