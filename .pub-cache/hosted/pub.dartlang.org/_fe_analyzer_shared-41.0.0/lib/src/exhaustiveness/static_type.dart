// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(paulberry,rnystrom): Generics.

/// A static type in the type system.
class StaticType {
  /// Built-in top type that all types are a subtype of.
  static final StaticType top = new StaticType('top', inherits: []);

  static final StaticType nullType = new StaticType('Null');

  final String name;

  late final StaticType nullable = new StaticType._nullable(this);

  /// If this type is a nullable type, then this is the underlying type.
  ///
  /// Otherwise `null`.
  final StaticType? _underlying;

  /// Whether this type is sealed. A sealed type is implicitly abstract and has
  /// a closed set of known subtypes. This means that every instance of the
  /// type must be an instance of one of those subtypes. Conversely, if an
  /// instance is *not* an instance of one of those subtypes, that it must not
  /// be an instance of this type.
  ///
  /// Note that subtypes of a sealed type do not themselves have to be sealed.
  /// Consider:
  ///
  ///      (A)
  ///      / \
  ///     B   C
  ///
  /// Here, A is sealed and B and C are not. There may be many unknown
  /// subclasses of B and C, or classes implementing their interfaces. That
  /// doesn't interfere with exhaustiveness checking because it's still the
  /// case that any instance of A must be either a B or C *or some subtype of
  /// one of those two types*.
  final bool isSealed;

  final Map<String, StaticType> _fields;

  final List<StaticType> _supertypes = [];

  final List<StaticType> _subtypes = [];

  StaticType(this.name,
      {this.isSealed = false,
      List<StaticType>? inherits,
      Map<String, StaticType> fields = const {}})
      : _underlying = null,
        _fields = fields {
    if (inherits != null) {
      for (StaticType type in inherits) {
        _supertypes.add(type);
        type._subtypes.add(this);
      }
    } else {
      _supertypes.add(top);
    }

    int sealed = 0;
    for (StaticType supertype in _supertypes) {
      if (supertype.isSealed) sealed++;
    }

    // We don't allow a sealed type's subtypes to be shared with some other
    // sibling supertype, as in D here:
    //
    //   (A) (B)
    //   / \ / \
    //  C   D   E
    //
    // We could remove this restriction but doing so will require
    // expandTypes() to be more complex. In the example here, if we subtract
    // E from A, the result should be C|D. That requires knowing that B should
    // be expanded, which expandTypes() doesn't currently handle.
    if (sealed > 1) {
      throw new ArgumentError('Can only have one sealed supertype.');
    }
  }

  StaticType._nullable(StaticType underlying)
      : name = '${underlying.name}?',
        _underlying = underlying,
        isSealed = true,
        // No fields because it may match null which doesn't have them.
        _fields = {} {}

  /// The static types of the fields this type exposes for record destructuring.
  ///
  /// Includes inherited fields.
  Map<String, StaticType> get fields {
    return {
      for (StaticType supertype in _supertypes) ...supertype.fields,
      ..._fields
    };
  }

  bool get isNullable => _underlying != null;

  /// The immediate subtypes of this type.
  Iterable<StaticType> get subtypes => _subtypes;

  /// The underlying type of this nullable type. It's an error to call this on
  /// a non-nullable type.
  StaticType get underlying => _underlying!;

  bool isSubtypeOf(StaticType other) {
    if (this == other) return true;

    // Null is a subtype of all nullable types.
    if (this == nullType && other._underlying != null) return true;

    // A nullable type is a subtype if the underlying type and Null both are.
    StaticType? underlying = _underlying;
    if (underlying != null) {
      return underlying.isSubtypeOf(other) && nullType.isSubtypeOf(other);
    }

    // A non-nullable type is a subtype of the underlying type of a nullable
    // type.
    StaticType? otherUnderlying = other._underlying;
    if (otherUnderlying != null) {
      return isSubtypeOf(otherUnderlying);
    }

    for (StaticType supertype in _supertypes) {
      if (supertype.isSubtypeOf(other)) return true;
    }

    return false;
  }

  @override
  String toString() => name;
}
