// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/semantics.dart';
/// @docImport 'package:flutter/widgets.dart';
library;

import 'package:meta/meta.dart';

import 'diagnostics.dart';

/// A [Key] is an identifier for [Widget]s, [Element]s and [SemanticsNode]s.
///
/// A new widget will only be used to update an existing element if its key is
/// the same as the key of the current widget associated with the element.
///
/// Typically, if no key is provided, the default value is null, meaning the
/// widget is considered unkeyed. In this case, Flutter matches widgets based
/// on their [Widget.runtimeType] and position in the tree during rebuilds.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=kn0EOS-ZiIc}
///
/// Keys must be unique amongst the [Element]s with the same parent.
///
/// Subclasses of [Key] should either subclass [LocalKey] or [GlobalKey].
///
/// A common mistake is to rebuild the widget tree in such a way that Flutter
/// attaches the incorrect State object to an unkeyed StatefulWidget. This can
/// often be solved by using an appropriate [Key] on the [StatefulWidget].
///
/// See [ValueKey], which explains how that class can be used as a solution to a
/// common case of this problem.
///
/// See also:
///
///  * [Widget.key], which discusses how widgets use keys.
@immutable
@pragma('flutter:keep-to-string-in-subtypes')
abstract class Key {
  /// Construct a [ValueKey<String>] with the given [String].
  ///
  /// This is the simplest way to create keys.
  const factory Key(String value) = ValueKey<String>;

  /// Default constructor, used by subclasses.
  ///
  /// Useful so that subclasses can call us, because the [Key.new] factory
  /// constructor shadows the implicit constructor.
  @protected
  const Key.empty();
}

/// A key that is not a [GlobalKey].
///
/// Keys must be unique amongst the [Element]s with the same parent. By
/// contrast, [GlobalKey]s must be unique across the entire app.
///
/// See also:
///
///  * [Widget.key], which discusses how widgets use keys.
abstract class LocalKey extends Key {
  /// This constructor enables subclasses to provide const constructors so that
  /// they can be used in const expressions.
  const LocalKey() : super.empty();
}

/// A key that is only equal to itself.
///
/// This cannot be created with a const constructor because that implies that
/// all instantiated keys would be the same instance and therefore not be unique.
class UniqueKey extends LocalKey {
  /// Creates a key that is equal only to itself.
  ///
  /// The key cannot be created with a const constructor because that implies
  /// that all instantiated keys would be the same instance and therefore not
  /// be unique.
  // ignore: prefer_const_constructors_in_immutables , never use const for this class
  UniqueKey();

  @override
  String toString() => '[#${shortHash(this)}]';
}

/// A key that uses a value of a particular type to identify itself.
///
/// A [ValueKey] is equal to another [ValueKey] if, and only if, their values
/// are equal (using [operator==]).
///
/// This class can be subclassed to create value keys that will not be equal to
/// other value keys that happen to use the same value. If the subclass is
/// private, this results in a value key type that cannot collide with keys from
/// other sources. This is useful when keys are used as fallbacks in the same
/// scope as keys supplied from another widget.
///
/// When building widgets from a collection of data, especially when that
/// collection can change over time (e.g., items being inserted, removed, or
/// reordered), keys are used to preserve the association between a widget and
/// the underlying data.
///
/// Without keys, the framework may have no way to distinguish between a change
/// in the data of an existing widget and a structural change in the list. As a
/// result, widgets may be incorrectly updated, and state held by
/// [StatefulWidget]s can be reused for a different piece of data.
///
/// Assigning a key ties the widget subtree to a specific piece of data,
/// allowing the framework to correctly match old and new widgets and preserve
/// state as expected.
///
/// In such cases, a [ValueKey] is typically appropriate, using a value that is
/// stable and unique for each item, such as an identifier from the data model.
///
/// {@tool dartpad}
/// The following example demonstrates the importance of using [ValueKey]s when reordering
/// a list of [StatefulWidget]s.
///
/// ### The Key Difference
/// * **Without Keys**: When the list is reversed, Flutter matches widgets by
/// position. The [State] (the counter) stays in its original spot while the
/// widget's configuration (the color) is swapped. This results in the counter
/// appearing to stay "stationary" while the colors move behind it.
/// * **With Keys**: By providing a [ValueKey], Flutter matches the [State]
/// to the [Widget] via the key rather than the index. When the list is
/// reversed, the [State] moves with the color.
///
/// To see the difference, find the `ColoredWidgetsList` widget inside the `map`
/// function and comment/uncomment the `key: ValueKey(color)` line.
///
/// ** See code in examples/api/lib/foundation/key/value_key.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [Widget.key], which discusses how widgets use keys.
///  * [ObjectKey], which uses the identity of an object as the key.
///  * [UniqueKey], which is a key that is only equal to itself.
class ValueKey<T> extends LocalKey {
  /// Creates a key that delegates its [operator==] to the given value.
  const ValueKey(this.value);

  /// The value to which this key delegates its [operator==].
  final T value;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is ValueKey<T> && other.value == value;
  }

  @override
  int get hashCode => Object.hash(runtimeType, value);

  @override
  String toString() {
    final valueString = T == String ? "<'$value'>" : '<$value>';
    if (runtimeType == ValueKey<T>) {
      return '[$valueString]';
    }
    return '[$T $valueString]';
  }
}
