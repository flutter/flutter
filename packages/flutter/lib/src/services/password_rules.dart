// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'autofill.dart';
library;

import 'package:flutter/foundation.dart';

/// A class of characters that can be used in a password, used by
/// [PasswordRules].
///
/// Use one of the predefined classes, such as [upper] or [digit], or
/// [PasswordCharacterClass.custom] for a specific set of characters.
///
/// Instances are compared by identity, so that they can be used in constant
/// sets. [PasswordRules] compares its character classes by value, so rules
/// that use equivalent custom character classes are equal.
@immutable
final class PasswordCharacterClass {
  const PasswordCharacterClass._(this._name) : characters = null;

  /// Creates a character class that contains the given [characters], for
  /// example `'-_'`.
  ///
  /// The [characters] must not be empty. Only ASCII printable characters are
  /// supported; other characters are ignored.
  const PasswordCharacterClass.custom(String this.characters)
    : assert(characters != ''),
      _name = null;

  /// Upper case letters, A-Z.
  static const PasswordCharacterClass upper = PasswordCharacterClass._('upper');

  /// Lower case letters, a-z.
  static const PasswordCharacterClass lower = PasswordCharacterClass._('lower');

  /// Digits, 0-9.
  static const PasswordCharacterClass digit = PasswordCharacterClass._('digit');

  /// ASCII printable characters that are not letters or digits, including
  /// space.
  static const PasswordCharacterClass special = PasswordCharacterClass._('special');

  /// All ASCII printable characters, including space.
  static const PasswordCharacterClass asciiPrintable = PasswordCharacterClass._('asciiPrintable');

  /// All Unicode characters.
  static const PasswordCharacterClass unicode = PasswordCharacterClass._('unicode');

  final String? _name;

  /// The characters in this class if it was created with
  /// [PasswordCharacterClass.custom], or null for a predefined class.
  final String? characters;

  Object _toJson() => _name ?? <String, String>{'custom': characters!};

  // A value that is equal for equivalent character classes.
  (String?, String?) get _key => (_name, characters);

  @override
  String toString() {
    return _name != null
        ? 'PasswordCharacterClass.$_name'
        : "PasswordCharacterClass.custom('$characters')";
  }
}

/// The requirements a password must satisfy, used by the platform's password
/// manager when it suggests a strong password.
///
/// {@tool snippet}
///
/// This example describes a password of at least 12 characters, with at
/// least one upper case letter and at least one digit.
///
/// ```dart
/// const PasswordRules rules = PasswordRules(
///   required: <Set<PasswordCharacterClass>>[
///     <PasswordCharacterClass>{PasswordCharacterClass.upper},
///     <PasswordCharacterClass>{PasswordCharacterClass.digit},
///   ],
///   minLength: 12,
/// );
/// ```
/// {@end-tool}
///
/// Only supported on iOS, where it is translated to
/// [UITextInputPasswordRules](https://developer.apple.com/documentation/uikit/uitextinputpasswordrules).
/// Other platforms ignore it.
///
/// See also:
///
///  * [AutofillConfiguration.passwordRules], which sends these rules to the
///    platform.
///  * Apple's [password rules documentation](https://developer.apple.com/documentation/security/customizing-password-autofill-rules).
@immutable
class PasswordRules {
  /// Creates the requirements a password must satisfy.
  ///
  /// The lengths and [maxConsecutive] must be positive, and [minLength] must
  /// not be greater than [maxLength].
  const PasswordRules({
    this.required = const <Set<PasswordCharacterClass>>[],
    this.allowed = const <PasswordCharacterClass>{},
    this.minLength,
    this.maxLength,
    this.maxConsecutive,
  }) : assert(minLength == null || minLength > 0),
       assert(maxLength == null || maxLength > 0),
       assert(minLength == null || maxLength == null || minLength <= maxLength),
       assert(maxConsecutive == null || maxConsecutive > 0);

  /// The character sets that the password must use.
  ///
  /// The password must contain at least one character from each set. A set
  /// with more than one class is satisfied by a character from any of them.
  /// Empty sets are ignored.
  final List<Set<PasswordCharacterClass>> required;

  /// The characters that may appear in the password, in addition to the
  /// [required] ones.
  final Set<PasswordCharacterClass> allowed;

  /// The minimum length of the password, or null for the platform default.
  final int? minLength;

  /// The maximum length of the password, or null for the platform default.
  final int? maxLength;

  /// The maximum number of identical consecutive characters, or null for no
  /// limit.
  final int? maxConsecutive;

  /// Returns a representation of this object as a JSON object.
  Map<String, Object> toJson() {
    return <String, Object>{
      if (required.isNotEmpty)
        'required': <List<Object>>[
          for (final Set<PasswordCharacterClass> classes in required)
            <Object>[for (final PasswordCharacterClass c in classes) c._toJson()],
        ],
      if (allowed.isNotEmpty)
        'allowed': <Object>[for (final PasswordCharacterClass c in allowed) c._toJson()],
      'minLength': ?minLength,
      'maxLength': ?maxLength,
      'maxConsecutive': ?maxConsecutive,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is PasswordRules &&
        _requiredEquals(other.required, required) &&
        setEquals(_keys(other.allowed), _keys(allowed)) &&
        other.minLength == minLength &&
        other.maxLength == maxLength &&
        other.maxConsecutive == maxConsecutive;
  }

  static bool _requiredEquals(
    List<Set<PasswordCharacterClass>> a,
    List<Set<PasswordCharacterClass>> b,
  ) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i += 1) {
      if (!setEquals(_keys(a[i]), _keys(b[i]))) {
        return false;
      }
    }
    return true;
  }

  // Character classes are compared by value instead of identity.
  static Set<(String?, String?)> _keys(Set<PasswordCharacterClass> classes) {
    return <(String?, String?)>{for (final PasswordCharacterClass c in classes) c._key};
  }

  @override
  int get hashCode {
    return Object.hash(
      Object.hashAll(
        required.map((Set<PasswordCharacterClass> classes) {
          return Object.hashAllUnordered(_keys(classes));
        }),
      ),
      Object.hashAllUnordered(_keys(allowed)),
      minLength,
      maxLength,
      maxConsecutive,
    );
  }

  @override
  String toString() {
    final description = <String>[
      if (required.isNotEmpty) 'required: $required',
      if (allowed.isNotEmpty) 'allowed: $allowed',
      if (minLength != null) 'minLength: $minLength',
      if (maxLength != null) 'maxLength: $maxLength',
      if (maxConsecutive != null) 'maxConsecutive: $maxConsecutive',
    ];
    return 'PasswordRules(${description.join(', ')})';
  }
}
