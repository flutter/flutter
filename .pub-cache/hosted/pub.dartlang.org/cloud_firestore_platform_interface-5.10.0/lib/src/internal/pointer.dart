// ignore_for_file: require_trailing_commas
// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// A helper class to handle Firestore paths.
///
/// This class is used internally to manage paths which point to a collection
/// or document on Firestore. Since paths can be deeply nested, the class helps
/// to reduce code repetition and improve testability.
@immutable
class Pointer {
  /// Create instance of [Pointer]
  Pointer(String path)
      : components =
            path.split('/').where((element) => element.isNotEmpty).toList();

  /// The Firestore normalized path of the [Pointer].
  String get path {
    return components.join('/');
  }

  /// Pointer components of the path.
  ///
  /// This is used to determine whether a path is a collection or document.
  final List<String> components;

  /// Returns the ID for this pointer.
  ///
  /// The ID is the last component of a given path. For example, the ID of the
  /// document "user/123" is "123".
  String get id {
    return components.last;
  }

  /// Returns whether the given path is a pointer to a Firestore collection.
  ///
  /// Collections are paths whose components are not dividable by 2, for example
  /// "collection/document/sub-collection".
  bool isCollection() {
    return components.length.isOdd;
  }

  /// Returns whether the given path is a pointer to a Firestore document.
  ///
  /// Documents are paths whose components are dividable by 2, for example
  /// "collection/document".
  bool isDocument() {
    return components.length.isEven;
  }

  /// Returns a new collection path from the current document pointer.
  String collectionPath(String collectionPath) {
    assert(isDocument());
    return '$path/$collectionPath';
  }

  /// Returns a new document path from the current collection pointer.
  String documentPath(String documentPath) {
    assert(isCollection());
    return '$path/$documentPath';
  }

  /// Returns a path pointing to the parent of the current path.
  String? parentPath() {
    if (components.length < 2) {
      return null;
    }

    List<String> parentComponents = List<String>.from(components)..removeLast();
    return parentComponents.join('/');
  }

  @override
  bool operator ==(Object other) => other is Pointer && other.path == path;

  @override
  int get hashCode => path.hashCode;
}
