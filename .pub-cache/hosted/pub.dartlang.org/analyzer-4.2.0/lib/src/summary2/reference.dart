// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';

/// Indirection between a name and the corresponding [Element].
///
/// References are organized in a prefix tree.
/// Each reference knows its parent, children, and the [Element].
///
///      Library:
///         URI of library
///
///      Class:
///         Reference of the enclosing library
///         "@class"
///         Name of the class
///
///      Method:
///         Reference of the enclosing class
///         "@method"
///         Name of the method
///
/// There is only one reference object per [Element].
class Reference {
  /// The parent of this reference, or `null` if the root.
  final Reference? parent;

  /// The simple name of the reference in its [parent].
  final String name;

  /// The corresponding [Element], or `null` if a named container.
  Element? element;

  /// Temporary index used during serialization and linking.
  int? index;

  Map<String, Reference>? _children;

  Reference.root() : this._(null, '');

  Reference._(this.parent, this.name);

  Iterable<Reference> get children {
    return _children?.values ?? const [];
  }

  bool get isLibrary => parent?.isRoot == true;

  bool get isPrefix => parent?.name == '@prefix';

  bool get isRoot => parent == null;

  bool get isSetter => parent?.name == '@setter';

  /// Return the child with the given name, or `null` if does not exist.
  Reference? operator [](String name) {
    name = _rewriteDartUi(name);
    return _children?[name];
  }

  /// Return the child with the given name, create if does not exist yet.
  Reference getChild(String name) {
    name = _rewriteDartUi(name);
    var map = _children ??= <String, Reference>{};
    return map[name] ??= Reference._(this, name);
  }

  Reference? removeChild(String name) {
    name = _rewriteDartUi(name);
    return _children?.remove(name);
  }

  @override
  String toString() => parent == null ? 'root' : '$parent::$name';

  /// TODO(scheglov) Remove it, once when the actual issue is fixed.
  /// https://buganizer.corp.google.com/issues/203423390
  static String _rewriteDartUi(String name) {
    const srcPrefix = 'dart:ui/src/ui/';
    if (name.startsWith(srcPrefix)) {
      return 'dart:ui/${name.substring(srcPrefix.length)}';
    }
    return name;
  }
}
