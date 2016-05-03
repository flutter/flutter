// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
    _StorageEntryIdentifier result = new _StorageEntryIdentifier();
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

  Map<_StorageEntryIdentifier, dynamic> _storage;

  /// Write the given data into this page storage bucket using an identifier
  /// computed from the given context.
  void writeState(BuildContext context, dynamic data) {
    _storage ??= <_StorageEntryIdentifier, dynamic>{};
    _storage[_computeStorageIdentifier(context)] = data;
  }

  /// Read given data from into this page storage bucket using an identifier
  /// computed from the given context.
  dynamic readState(BuildContext context) {
    return _storage != null ? _storage[_computeStorageIdentifier(context)] : null;
  }
}

/// Establishes a page storage bucket for this widget subtree.
class PageStorage extends StatelessWidget {
  PageStorage({
    Key key,
    this.child,
    this.bucket
  }) : super(key: key);

  /// The widget below this widget in the tree.
  final Widget child;

  /// The page storage bucket to use for this subtree.
  final PageStorageBucket bucket;

  /// The bucket from the closest instance of this class that encloses the given context.
  ///
  /// Returns `null` if none exists.
  static PageStorageBucket of(BuildContext context) {
    PageStorage widget = context.ancestorWidgetOfExactType(PageStorage);
    return widget?.bucket;
  }

  @override
  Widget build(BuildContext context) => child;
}
