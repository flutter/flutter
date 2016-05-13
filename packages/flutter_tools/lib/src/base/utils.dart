// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

bool get isRunningOnBot {
  // https://docs.travis-ci.com/user/environment-variables/#Default-Environment-Variables
  return
    Platform.environment['TRAVIS'] == 'true' ||
    Platform.environment['CONTINUOUS_INTEGRATION'] == 'true';
}

String hex(List<int> bytes) {
  StringBuffer result = new StringBuffer();
  for (int part in bytes)
    result.write('${part < 16 ? '0' : ''}${part.toRadixString(16)}');
  return result.toString();
}

String calculateSha(File file) {
  return hex(sha1.convert(file.readAsBytesSync()).bytes);
}

/// Convert `foo_bar` to `fooBar`.
String camelCase(String str) {
  int index = str.indexOf('_');
  while (index != -1 && index < str.length - 2) {
    str = str.substring(0, index) +
      str.substring(index + 1, index + 2).toUpperCase() +
      str.substring(index + 2);
    index = str.indexOf('_');
  }
  return str;
}

/// Return the plural of the given word (`cat(s)`).
String pluralize(String word, int count) => count == 1 ? word : word + 's';

/// Return the name of an enum item.
String getEnumName(dynamic enumItem) {
  String name = '$enumItem';
  int index = name.indexOf('.');
  return index == -1 ? name : name.substring(index + 1);
}

File getUniqueFile(Directory dir, String baseName, String ext) {
  int i = 1;

  while (true) {
    String name = '${baseName}_${i.toString().padLeft(2, '0')}.$ext';
    File file = new File(path.join(dir.path, name));
    if (!file.existsSync())
      return file;
    i++;
  }
}

String toPrettyJson(Object jsonable) {
  return new JsonEncoder.withIndent('  ').convert(jsonable) + '\n';
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
