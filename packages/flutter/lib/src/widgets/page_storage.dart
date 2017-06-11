// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'framework.dart';

/// A [ValueKey] that defines where [PageStorage] values will be saved.
///
/// [Scrollable]s ([ScrollPosition]s really) use [PageStorage] to save their
/// scroll offset. Each time a scroll completes, the scrollable's page
/// storage is updated.
///
/// [PageStorage] is used to save and restore values that can outlive the widget.
/// The values are stored in a per-route [Map] whose keys are defined by the
/// [PageStorageKey]s for the widget and its ancestors. To make it possible
/// for a saved value to be found when a widget is recreated, the key's values
/// must not be objects whose identity will change each time the widget is created.
///
/// For example, to ensure that the scroll offsets for the scrollable within
/// each `MyScrollableTabView` below are restored when the [TabBarView]
/// is recreated, we've specified [PageStorageKey]s whose values are the the
/// tabs' string labels.
///
/// ```dart
/// new TabBarView(
///   children: myTabs.map((Tab tab) {
///     new MyScrollableTabView(
///       key: new PageStorageKey<String>(tab.text), // like 'Tab 1'
///       tab: tab,
///    ),
///  }),
///)
/// ```
class PageStorageKey<T> extends ValueKey<T> {
  /// Creates a [ValueKey] that defines where [PageStorage] values will be saved.
  const PageStorageKey(T value) : super(value);
}

class _StorageEntryIdentifier {
  _StorageEntryIdentifier(this.clientType, this.keys) {
    assert(clientType != null);
    assert(keys != null);
  }

  final Type clientType;
  final List<PageStorageKey<dynamic>> keys;

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType)
      return false;
    final _StorageEntryIdentifier typedOther = other;
    if (clientType != typedOther.clientType || keys.length != typedOther.keys.length)
      return false;
    for (int index = 0; index < keys.length; index += 1) {
      if (keys[index] != typedOther.keys[index])
        return false;
    }
    return true;
  }

  @override
  int get hashCode => hashValues(clientType, hashList(keys));

  @override
  String toString() {
    return 'StorageEntryIdentifier($clientType, ${keys?.join(":")})';
  }
}

/// A storage bucket associated with a page in an app.
///
/// Useful for storing per-page state that persists across navigations from one
/// page to another.
class PageStorageBucket {
  static bool _maybeAddKey(BuildContext context, List<PageStorageKey<dynamic>> keys) {
    final Widget widget = context.widget;
    final Key key = widget.key;
    if (key is PageStorageKey)
      keys.add(key);
    return widget is! PageStorage;
  }

  List<PageStorageKey<dynamic>> _allKeys(BuildContext context) {
    final List<PageStorageKey<dynamic>> keys = <PageStorageKey<dynamic>>[];
    if (_maybeAddKey(context, keys)) {
      context.visitAncestorElements((Element element) {
        return _maybeAddKey(element, keys);
      });
    }
    return keys;
  }

  _StorageEntryIdentifier _computeIdentifier(BuildContext context) {
    return new _StorageEntryIdentifier(context.widget.runtimeType, _allKeys(context));
  }

  Map<Object, dynamic> _storage;

  /// Write the given data into this page storage bucket using an identifier
  /// computed from the given context. The identifier is based on the keys
  /// found in the path from context to the root of the widget tree for this
  /// page. Keys are collected until the widget tree's root is reached or
  /// a GlobalKey is found.
  ///
  /// An explicit identifier can be used in cases where the list of keys
  /// is not stable. For example if the path concludes with a GlobalKey
  /// that's created by a stateful widget, if the stateful widget is
  /// recreated when it's exposed by [Navigator.pop], then its storage
  /// identifier will change.
  void writeState(BuildContext context, dynamic data, { Object identifier }) {
    _storage ??= <Object, dynamic>{};
    _storage[identifier ?? _computeIdentifier(context)] = data;
  }

  /// Read given data from into this page storage bucket using an identifier
  /// computed from the given context. More about [identifier] in [writeState].
  dynamic readState(BuildContext context, { Object identifier }) {
    return _storage != null ? _storage[identifier ?? _computeIdentifier(context)] : null;
  }
}

/// A widget that establishes a page storage bucket for this widget subtree.
class PageStorage extends StatelessWidget {
  /// Creates a widget that provides a storage bucket for its descendants.
  ///
  /// The [bucket] argument must not be null.
  const PageStorage({
    Key key,
    @required this.bucket,
    @required this.child
  }) : assert(bucket != null),
       super(key: key);

  /// The widget below this widget in the tree.
  final Widget child;

  /// The page storage bucket to use for this subtree.
  final PageStorageBucket bucket;

  /// The bucket from the closest instance of this class that encloses the given context.
  ///
  /// Returns null if none exists.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// PageStorageBucket bucket = PageStorage.of(context);
  /// ```
  static PageStorageBucket of(BuildContext context) {
    final PageStorage widget = context.ancestorWidgetOfExactType(PageStorage);
    return widget?.bucket;
  }

  @override
  Widget build(BuildContext context) => child;
}
