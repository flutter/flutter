// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jmesserly): everything in this file is copied straight from "dart:html".
library html.dom.src;

import 'dart:collection';

import 'package:html/dom.dart';

class ElementCssClassSet extends _CssClassSetImpl {
  final Element _element;

  ElementCssClassSet(this._element);

  @override
  Set<String> readClasses() {
    final s = LinkedHashSet<String>();
    final classname = _element.className;

    for (var name in classname.split(' ')) {
      final trimmed = name.trim();
      if (trimmed.isNotEmpty) {
        s.add(trimmed);
      }
    }
    return s;
  }

  @override
  void writeClasses(Set<String> s) {
    _element.className = s.join(' ');
  }
}

/// A Set that stores the CSS class names for an element.
abstract class CssClassSet implements Set<String> {
  /// Adds the class [value] to the element if it is not on it, removes it if it
  /// is.
  ///
  /// If [shouldAdd] is true, then we always add that [value] to the element. If
  /// [shouldAdd] is false then we always remove [value] from the element.
  bool toggle(String value, [bool? shouldAdd]);

  /// Returns [:true:] if classes cannot be added or removed from this
  /// [:CssClassSet:].
  bool get frozen;

  /// Determine if this element contains the class [value].
  ///
  /// This is the Dart equivalent of jQuery's
  /// [hasClass](http://api.jquery.com/hasClass/).
  @override
  bool contains(Object? value);

  /// Add the class [value] to element.
  ///
  /// This is the Dart equivalent of jQuery's
  /// [addClass](http://api.jquery.com/addClass/).
  ///
  /// If this corresponds to one element. Returns true if [value] was added to
  /// the set, otherwise false.
  ///
  /// If this corresponds to many elements, null is always returned.
  @override
  bool add(String value);

  /// Remove the class [value] from element, and return true on successful
  /// removal.
  ///
  /// This is the Dart equivalent of jQuery's
  /// [removeClass](http://api.jquery.com/removeClass/).
  @override
  bool remove(Object? value);

  /// Add all classes specified in [iterable] to element.
  ///
  /// This is the Dart equivalent of jQuery's
  /// [addClass](http://api.jquery.com/addClass/).
  @override
  void addAll(Iterable<String> iterable);

  /// Remove all classes specified in [iterable] from element.
  ///
  /// This is the Dart equivalent of jQuery's
  /// [removeClass](http://api.jquery.com/removeClass/).
  @override
  void removeAll(Iterable<Object?> iterable);

  /// Toggles all classes specified in [iterable] on element.
  ///
  /// Iterate through [iterable]'s items, and add it if it is not on it, or
  /// remove it if it is. This is the Dart equivalent of jQuery's
  /// [toggleClass](http://api.jquery.com/toggleClass/).
  /// If [shouldAdd] is true, then we always add all the classes in [iterable]
  /// element. If [shouldAdd] is false then we always remove all the classes in
  /// [iterable] from the element.
  void toggleAll(Iterable<String> iterable, [bool? shouldAdd]);
}

abstract class _CssClassSetImpl extends SetBase<String> implements CssClassSet {
  @override
  String toString() {
    return readClasses().join(' ');
  }

  /// Adds the class [value] to the element if it is not on it, removes it if it
  /// is.
  ///
  /// If [shouldAdd] is true, then we always add that [value] to the element. If
  /// [shouldAdd] is false then we always remove [value] from the element.
  @override
  bool toggle(String value, [bool? shouldAdd]) {
    final s = readClasses();
    var result = false;
    shouldAdd ??= !s.contains(value);
    if (shouldAdd) {
      s.add(value);
      result = true;
    } else {
      s.remove(value);
    }
    writeClasses(s);
    return result;
  }

  /// Returns [:true:] if classes cannot be added or removed from this
  /// [:CssClassSet:].
  @override
  bool get frozen => false;

  @override
  Iterator<String> get iterator => readClasses().iterator;

  @override
  int get length => readClasses().length;

  // interface Set - BEGIN
  /// Determine if this element contains the class [value].
  ///
  /// This is the Dart equivalent of jQuery's
  /// [hasClass](http://api.jquery.com/hasClass/).
  @override
  bool contains(Object? value) => readClasses().contains(value);

  /// Lookup from the Set interface. Not interesting for a String set.
  @override
  String? lookup(Object? value) => contains(value) ? value as String? : null;

  @override
  Set<String> toSet() => readClasses().toSet();

  /// Add the class [value] to element.
  ///
  /// This is the Dart equivalent of jQuery's
  /// [addClass](http://api.jquery.com/addClass/).
  @override
  bool add(String value) {
    // TODO - figure out if we need to do any validation here
    // or if the browser natively does enough.
    return _modify((s) => s.add(value));
  }

  /// Remove the class [value] from element, and return true on successful
  /// removal.
  ///
  /// This is the Dart equivalent of jQuery's
  /// [removeClass](http://api.jquery.com/removeClass/).
  @override
  bool remove(Object? value) {
    if (value is! String) return false;
    final s = readClasses();
    final result = s.remove(value);
    writeClasses(s);
    return result;
  }

  /// Toggles all classes specified in [iterable] on element.
  ///
  /// Iterate through [iterable]'s items, and add it if it is not on it, or
  /// remove it if it is. This is the Dart equivalent of jQuery's
  /// [toggleClass](http://api.jquery.com/toggleClass/).
  /// If [shouldAdd] is true, then we always add all the classes in [iterable]
  /// element. If [shouldAdd] is false then we always remove all the classes in
  /// [iterable] from the element.
  @override
  void toggleAll(Iterable<String> iterable, [bool? shouldAdd]) {
    for (var e in iterable) {
      toggle(e, shouldAdd);
    }
  }

  /// Helper method used to modify the set of css classes on this element.
  ///
  ///   f - callback with:
  ///   s - a Set of all the css class name currently on this element.
  ///
  ///   After f returns, the modified set is written to the
  ///       className property of this element.
  bool _modify(bool Function(Set<String>) f) {
    final s = readClasses();
    final ret = f(s);
    writeClasses(s);
    return ret;
  }

  /// Read the class names from the Element class property,
  /// and put them into a set (duplicates are discarded).
  /// This is intended to be overridden by specific implementations.
  Set<String> readClasses();

  /// Join all the elements of a set into one string and write
  /// back to the element.
  /// This is intended to be overridden by specific implementations.
  void writeClasses(Set<String> s);
}
