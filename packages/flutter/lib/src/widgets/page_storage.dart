// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'framework.dart';

class _StorageEntryIdentifier {
  Type clientType;
  List<Key> keys;

  void addKey(Key key) {
    assert(key != null);
    assert(key is! GlobalKey);
    keys ??= <Key>[];
    keys.add(key);
  }

  GlobalKey scopeKey;

  @override
  bool operator ==(dynamic other) {
    if (other is! _StorageEntryIdentifier)
      return false;
    final _StorageEntryIdentifier typedOther = other;
    if (clientType != typedOther.clientType ||
        scopeKey != typedOther.scopeKey ||
        keys?.length != typedOther.keys?.length)
      return false;
    if (keys != null) {
      for (int index = 0; index < keys.length; index += 1) {
        if (keys[index] != typedOther.keys[index])
          return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => hashValues(clientType, scopeKey, hashList(keys));

  @override
  String toString() {
    return 'StorageEntryIdentifier($clientType, $scopeKey, ${keys?.join(":")})';
  }
}

/// A storage bucket associated with a page in an app.
///
/// Useful for storing per-page state that persists across navigations from one
/// page to another.
class PageStorageBucket {
  _StorageEntryIdentifier _computeStorageIdentifier(BuildContext context) {
    final _StorageEntryIdentifier result = new _StorageEntryIdentifier();
    result.clientType = context.widget.runtimeType;
    Key lastKey = context.widget.key;
    if (lastKey is! GlobalKey) {
      if (lastKey != null)
        result.addKey(lastKey);
      context.visitAncestorElements((Element element) {
        if (element.widget.key is GlobalKey) {
          lastKey = element.widget.key;
          return false;
        } else if (element.widget.key != null) {
          result.addKey(element.widget.key);
        }
        return true;
      });
      return result;
    }
    assert(lastKey is GlobalKey);
    result.scopeKey = lastKey;
    return result;
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
    _storage[identifier ?? _computeStorageIdentifier(context)] = data;
  }

  /// Read given data from into this page storage bucket using an identifier
  /// computed from the given context. More about [identifier] in [writeState].
  dynamic readState(BuildContext context, { Object identifier }) {
    return _storage != null ? _storage[identifier ?? _computeStorageIdentifier(context)] : null;
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
  /// Returns `null` if none exists.
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
