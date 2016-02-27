// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';

String calculateSha(File file) {
  SHA1 sha1 = new SHA1();
  sha1.add(file.readAsBytesSync());
  return CryptoUtils.bytesToHex(sha1.close());
}

/// A class to maintain a list of items, fire events when items are added or
/// removed, and calculate a diff of changes when a new list of items is
/// available.
class ItemListNotifier<T> {
  ItemListNotifier() {
    _items = new Set<T>();
  }

  ItemListNotifier.from(List<T> items) {
    _items = new Set<T>.from(items);
  }

  Set<T> _items;

  StreamController<T> _addedController = new StreamController<T>.broadcast();
  StreamController<T> _removedController = new StreamController<T>.broadcast();

  Stream<T> get onAdded => _addedController.stream;
  Stream<T> get onRemoved => _removedController.stream;

  List<T> get items => _items.toList();

  void updateWithNewList(List<T> updatedList) {
    Set<T> updatedSet = new Set<T>.from(updatedList);

    Set<T> addedItems = updatedSet.difference(_items);
    Set<T> removedItems = _items.difference(updatedSet);

    _items = updatedSet;

    for (T item in addedItems)
      _addedController.add(item);
    for (T item in removedItems)
      _removedController.add(item);
  }

  /// Close the streams.
  void dispose() {
    _addedController.close();
    _removedController.close();
  }
}
