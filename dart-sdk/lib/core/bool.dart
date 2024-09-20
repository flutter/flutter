// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

// Examples can assume:
// class Logger { const Logger({String id}); }

/// The reserved words `true` and `false` denote objects that are the only two
/// instances of this class.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// bool.
@pragma("vm:entry-point")
final class bool {
  /// Boolean value for [name] in the compilation configuration environment.
  ///
  /// The compilation configuration environment is provided by the
  /// surrounding tools which are compiling or running the Dart program.
  /// The environment is a mapping from a set of string keys to their associated
  /// string value.
  /// The string value, or lack of a value, associated with a [name]
  /// must be consistent across all calls to [String.fromEnvironment],
  /// [int.fromEnvironment], `bool.fromEnvironment` and [bool.hasEnvironment]
  /// in a single program.
  /// The string values can be directly accessed using [String.fromEnvironment].
  ///
  /// This constructor parses the string value associated with [name] as
  /// a boolean, as if by [`bool.tryParse(value)`][bool.tryParse],
  /// meaning that it accepts only the strings `"true"` and `"false"`.
  ///
  /// If there is no value associated with [name] in the compilation
  /// configuration environment, or if the associated string value is not one
  /// of `"true"` or `"false"`, the value of the constructor invocation
  /// is the [defaultValue] boolean, which defaults to the boolean value
  /// `false`.
  ///
  /// The result is the same as that of:
  /// ```dart template:expression
  /// (const String.fromEnvironment(name) == "true")
  ///     || ((const String.fromEnvironment(name) != "false") && defaultValue)
  /// ```
  ///
  /// Example:
  /// ```dart
  /// const bool loggingEnabled = bool.fromEnvironment("logging");
  /// ```
  /// In order to check whether a value is there at all, use
  /// [bool.hasEnvironment]. Example:
  /// ```dart
  /// const bool? yesNoMaybe = bool.hasEnvironment("optionalFlag")
  ///     ? bool.fromEnvironment("optionalFlag")
  ///     : null;
  /// ```
  ///
  /// To accept other strings than `"true"` or `"false"`, use the
  /// [String.fromEnvironment] constructor directly. Example:
  /// ```dart
  /// const isLoggingOn = (const String.fromEnvironment("logging") == "on");
  /// ```
  ///
  /// This constructor is only guaranteed to work when invoked as `const`.
  /// It may work as a non-constant invocation on some platforms which
  /// have access to compiler options at run-time, but most ahead-of-time
  /// compiled platforms will not have this information.
  external const factory bool.fromEnvironment(String name,
      {bool defaultValue = false});

  /// Whether [name] is declared in the compilation configuration environment.
  ///
  /// The compilation configuration environment is provided by the
  /// surrounding tools which are compiling or running the Dart program.
  /// The environment is a mapping from a set of string keys to their associated
  /// string value.
  /// The string value, or lack of a value, associated with a [name]
  /// must be consistent across all calls to [String.fromEnvironment],
  /// [int.fromEnvironment], `bool.fromEnvironment` and [bool.hasEnvironment]
  /// in a single program.
  ///
  /// This constructor evaluates to `true` if [name] has an associated value
  /// in the compilation configuration environment, and to `false` if not.
  /// If there is an associated value, then the value can be accessed using
  /// `const String.fromEnvironment(name)`. Otherwise,
  /// `String.fromEnvironment(name, defaultValue: someString)`
  /// is known to evaluate to the given `defaultValue`.
  ///
  /// The [String.fromEnvironment], [int.fromEnvironment] and
  /// [bool.fromEnvironment] constructors always produce a [String], [int],
  /// or [bool], as required for a constructor.
  /// In most cases, the absence of a configuration environment association
  /// for a [name] simply means that the code should fall back on a default
  /// behavior, and a default value of the same type typically represents that
  /// perfectly.
  ///
  /// In some cases, a value of different type, mostly `null`, may better
  /// represent the absence of a choice. In that case, this constructor can
  /// be used to first check whether there is a value, and only then use the
  /// other `fromEnvironment` constructors.
  /// Example:
  /// ```dart
  /// const int? indentOverride = bool.hasEnvironment("indent-override")
  ///     ? int.fromEnvironment("indent-override")
  ///     : null;
  /// void indentLines(List<String> lines, int indentation) {
  ///   int actualIndentation = indentOverride ?? indentation;
  ///   // ... Do something to lines.
  /// }
  /// ```
  /// This pattern allows a compilation configuration to provide an override
  /// value to the program, but also to not do so, and the program can tell the
  /// difference between an explicitly provided value and the absence of one.
  ///
  /// Another use case is to only do something extra when a needed value is
  /// available. Example:
  /// ```dart
  /// const Logger? logger = bool.hasEnvironment("logging-id")
  ///     ? Logger(id: String.fromEnvironment("logging-id"))
  ///     : null;
  /// ```
  ///
  /// This constructor is only guaranteed to work when invoked as `const`.
  /// It may work as a non-constant invocation on some platforms which
  /// have access to compiler options at run-time, but most ahead-of-time
  /// compiled platforms will not have this information.
  external const factory bool.hasEnvironment(String name);

  /// Parses [source] as an, optionally case-insensitive, boolean literal.
  ///
  /// If [caseSensitive] is `true`, which is the default,
  /// the only accepted inputs are the strings `"true"` and `"false"`,
  /// which returns the results `true` and `false` respectively.
  ///
  /// If [caseSensitive] is `false`, any combination of upper and lower case
  /// ASCII letters in the words `"true"` and `"false"` are accepted,
  /// as if the input was first lower-cased.
  ///
  /// Throws a [FormatException] if the [source] string does not contain
  /// a valid boolean literal.
  ///
  /// Rather than throwing and immediately catching the [FormatException],
  /// instead use [tryParse] to handle a potential parsing error.
  ///
  /// Example:
  /// ```dart
  /// print(bool.parse('true')); // true
  /// print(bool.parse('false')); // false
  /// print(bool.parse('TRUE')); // throws FormatException
  /// print(bool.parse('TRUE', caseSensitive: false)); // true
  /// print(bool.parse('FALSE', caseSensitive: false)); // false
  /// print(bool.parse('NO')); // throws FormatException
  /// print(bool.parse('YES')); // throws FormatException
  /// print(bool.parse('0')); // throws FormatException
  /// print(bool.parse('1')); // throws FormatException
  /// ```
  @Since("3.0")
  external static bool parse(String source, {bool caseSensitive = true});

  /// Parses [source] as an, optionally case-insensitive, boolean literal.
  ///
  /// If [caseSensitive] is `true`, which is the default,
  /// the only accepted inputs are the strings `"true"` and `"false"`,
  /// which returns the results `true` and `false` respectively.
  ///
  /// If [caseSensitive] is `false`, any combination of upper and lower case
  /// ASCII letters in the words `"true"` and `"false"` are accepted,
  /// as if the input was first lower-cased.
  ///
  /// Returns `null` if the [source] string does not contain a valid
  /// boolean literal.
  ///
  /// If the input can be assumed to be valid, use [bool.parse] to avoid
  /// having to deal with a possible `null` result.
  ///
  /// Example:
  /// ```dart
  /// print(bool.tryParse('true')); // true
  /// print(bool.tryParse('false')); // false
  /// print(bool.tryParse('TRUE')); // null
  /// print(bool.tryParse('TRUE', caseSensitive: false)); // true
  /// print(bool.tryParse('FALSE', caseSensitive: false)); // false
  /// print(bool.tryParse('NO')); // null
  /// print(bool.tryParse('YES')); // null
  /// print(bool.tryParse('0')); // null
  /// print(bool.tryParse('1')); // null
  /// ```
  @Since("3.0")
  external static bool? tryParse(String source, {bool caseSensitive = true});

  external int get hashCode;

  /// The logical conjunction ("and") of this and [other].
  ///
  /// Returns `true` if both this and [other] are `true`, and `false` otherwise.
  @Since("2.1")
  bool operator &(bool other) => other && this;

  /// The logical disjunction ("inclusive or") of this and [other].
  ///
  /// Returns `true` if either this or [other] is `true`, and `false` otherwise.
  @Since("2.1")
  bool operator |(bool other) => other || this;

  /// The logical exclusive disjunction ("exclusive or") of this and [other].
  ///
  /// Returns whether this and [other] are neither both `true` nor both `false`.
  @Since("2.1")
  bool operator ^(bool other) => !other == this;

  /// Returns either `"true"` for `true` and `"false"` for `false`.
  String toString() {
    return this ? "true" : "false";
  }
}
