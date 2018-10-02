// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
/// is recreated, we've specified [PageStorageKey]s whose values are the
/// tabs' string labels.
///
/// ```dart
/// TabBarView(
///   children: myTabs.map((Tab tab) {
///     MyScrollableTabView(
///       key: PageStorageKey<String>(tab.text), // like 'Tab 1'
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
  _StorageEntryIdentifier(this.keys)
    : assert(keys != null);

  final List<PageStorageKey<dynamic>> keys;

  bool get isNotEmpty => keys.isNotEmpty;

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType)
      return false;
    final _StorageEntryIdentifier typedOther = other;
    for (int index = 0; index < keys.length; index += 1) {
      if (keys[index] != typedOther.keys[index])
        return false;
    }
    return true;
  }

  @override
  int get hashCode => hashList(keys);

  @override
  String toString() {
    return 'StorageEntryIdentifier(${keys?.join(":")})';
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
    return _StorageEntryIdentifier(_allKeys(context));
  }

  Map<Object, dynamic> _storage;

  /// Write the given data into this page storage bucket using the
  /// specified identifier or an identifier computed from the given context.
  /// The computed identifier is based on the [PageStorageKey]s
  /// found in the path from context to the [PageStorage] widget that
  /// owns this page storage bucket.
  ///
  /// If an explicit identifier is not provided and no [PageStorageKey]s
  /// are found, then the `data` is not saved.
  void writeState(BuildContext context, dynamic data, { Object identifier }) {
    _storage ??= <Object, dynamic>{};
    if (identifier != null) {
      _storage[identifier] = data;
    } else {
      final _StorageEntryIdentifier contextIdentifier = _computeIdentifier(context);
      if (contextIdentifier.isNotEmpty)
        _storage[contextIdentifier] = data;
    }
  }

  /// Read given data from into this page storage bucket using the specified
  /// identifier or an identifier computed from the given context.
  /// The computed identifier is based on the [PageStorageKey]s
  /// found in the path from context to the [PageStorage] widget that
  /// owns this page storage bucket.
  ///
  /// If an explicit identifier is not provided and no [PageStorageKey]s
  /// are found, then null is returned.
  dynamic readState(BuildContext context, { Object identifier }) {
    if (_storage == null)
      return null;
    if (identifier != null)
      return _storage[identifier];
    final _StorageEntryIdentifier contextIdentifier = _computeIdentifier(context);
    return contextIdentifier.isNotEmpty ? _storage[contextIdentifier] : null;
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
  ///
  /// {@macro flutter.widgets.child}
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
