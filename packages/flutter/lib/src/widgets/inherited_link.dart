// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'framework.dart';


/// Defines a location in the widget tree that an [InheritedWidgetLinkChild] can
/// link to. The descendants of the link child inherit from the link parent's
/// [InheritedWidget] ancestors instead of the link child's inherited widget
/// ancestors.
///
/// This widget must be given its own [GlobalKey] and the value of its [link] must
/// be a GlobalKey given to its link child. If the link is null then this widget
/// has no effect on inherited values.
class InheritedWidgetLinkParent extends ProxyWidget {
  const InheritedWidgetLinkParent({ GlobalKey key, Widget child, this.link })
    : super(key: key, child: child);

  /// The value of an [InheritedWidgetLinkChild]'s key or null. The link child's
  /// descendants will inherit from this widget's  [InheritedWidget] ancestors.
  /// If [key] or link is null then this link child will have no effect on inheritance.
  final GlobalKey link;

  @override
  InheritedElementLinkParent createElement() => new InheritedElementLinkParent(this);

  bool updateShouldNotify(InheritedWidgetLinkParent oldWidget) => link != oldWidget.link;
}

/// This widget's child inherits values from the [InheritedWidget] ancestors of the
/// [InheritedWidgetLinkParent] that it's linked to.
///
/// This widget must be given its own [GlobalKey] and the value of its [link] must
/// be a GlobalKey given to its link parent. If the link is null then this widget
/// has no effect on inherited values.
class InheritedWidgetLinkChild extends ProxyWidget {
  const InheritedWidgetLinkChild({ GlobalKey key, Widget child, this.link })
    : super(key: key, child: child);

  /// The value of an [InheritedWidgetLinkParent]'s key or null. This widget will
  /// inherit from the link parent's [InheritedWidget] ancestors. If [key] or link
  /// is null then this link child will have no effect on inheritance.
  final GlobalKey link;

  @override
  InheritedElementLinkChild createElement() => new InheritedElementLinkChild(this);

  bool updateShouldNotify(InheritedWidgetLinkChild oldWidget) => link != oldWidget.link;
}
