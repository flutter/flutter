// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/// Error objects thrown in the case of a program failure.
///
/// An `Error` object represents a program failure that the programmer
/// should have avoided.
///
/// Examples include calling a function with invalid arguments,
/// or even with the wrong number of arguments,
/// or calling it at a time when it is not allowed.
///
/// These are not errors that a caller should expect or catch &mdash;
/// if they occur, the program is erroneous,
/// and terminating the program may be the safest response.
///
/// When deciding that a function should throw an error,
/// the conditions where it happens should be clearly described,
/// and they should be detectable and predictable,
/// so the programmer using the function can avoid triggering the error.
///
/// Such descriptions often uses words like
/// "must" or "must not" to describe the condition,
/// and if you see words like that in a function's documentation,
/// then not satisfying the requirement
/// is very likely to cause an error to be thrown.
///
/// Example (from [String.contains]):
/// ```plaintext
/// `startIndex` must not be negative or greater than `length`.
/// ```
/// In this case, an error will be thrown if `startIndex` is negative
/// or too large.
///
/// If the conditions are not detectable before calling a function,
/// the called function should not throw an `Error`.
/// It may still throw,
/// but the caller will have to catch the thrown value,
/// effectively making it an alternative result rather than an error.
/// If so, we consider the thrown object an *exception* rather than an error.
/// The thrown object can choose to implement [Exception]
/// to document that it represents an exceptional, but not erroneous,
/// occurrence, but being an [Exception] has no other effect
/// than documentation.
///
/// All non-`null` values can be thrown in Dart.
/// Objects *extending* the `Error` class are handled specially:
/// The first time they are thrown,
/// the stack trace at the throw point is recorded
/// and stored in the error object.
/// It can be retrieved using the [stackTrace] getter.
/// An error object that merely implements `Error`, and doesn't extend it,
/// will not store the stack trace automatically.
///
/// Error objects are also used for system wide failures
/// like stack overflow or an out-of-memory situation,
/// which the user is also not expected to catch or handle.
///
/// Since errors are not created to be caught,
/// there is no need for subclasses to distinguish the errors.
/// Instead subclasses have been created in order to make groups
/// of related errors easy to create with consistent error messages.
/// For example, the [String.contains] method will use a [RangeError]
/// if its `startIndex` isn't in the range `0..length`,
/// which is easily created by `RangeError.range(startIndex, 0, length)`.
/// Catching specific subclasses of [Error] is not intended,
/// and shouldn't happen outside of testing your own code.
@pragma('flutter:keep-to-string-in-subtypes')
class Error {
  Error(); // Prevent use as mixin.

  /// Safely convert a value to a [String] description.
  ///
  /// The conversion is guaranteed to not throw, so it won't use the object's
  /// toString method except for specific known and trusted types.
  static String safeToString(Object? object) {
    if (object is num || object is bool || null == object) {
      return object.toString();
    }
    if (object is String) {
      return _stringToSafeString(object);
    }
    return _objectToString(object);
  }

  /// Convert string to a valid string literal with no control characters.
  external static String _stringToSafeString(String string);

  external static String _objectToString(Object object);

  /// The stack trace at the point where this error was first thrown.
  ///
  /// Classes which *extend* `Error` will automatically have a stack
  /// trace filled in the first time they are thrown by a `throw`
  /// expression.
  external StackTrace? get stackTrace;

  /// Throws [error] with associated stack trace [stackTrace].
  ///
  /// Behaves like `throw error` would
  /// if the [current stack trace][StackTrace.current] was [stackTrace]
  /// at the time of the `throw`.
  ///
  /// Like for a `throw`, if [error] extends [Error], and it has not been
  /// thrown before, its [Error.stackTrace] property will be set to
  /// the [stackTrace].
  ///
  /// This function does not guarantee to preserve the identity of [stackTrace].
  /// The [StackTrace] object that is caught by a `try`/`catch` of
  /// this error, or which is set as the [Error.stackTrace] of an [error],
  /// may not be the same [stackTrace] object provided as argument,
  /// but it will have the same contents according to [StackTrace.toString].
  @Since("2.16")
  static Never throwWithStackTrace(Object error, StackTrace stackTrace) {
    checkNotNullable(error, "error");
    checkNotNullable(stackTrace, "stackTrace");
    _throw(error, stackTrace);
  }

  @pragma("wasm:entry-point")
  external static Never _throw(Object error, StackTrace stackTrace);
}

/// Error thrown by the runtime system when an assert statement fails.
class AssertionError extends Error {
  /// Message describing the assertion error.
  final Object? message;

  /// Creates an assertion error with the provided [message].
  AssertionError([this.message]);

  String toString() {
    if (message != null) {
      return "Assertion failed: ${Error.safeToString(message)}";
    }
    return "Assertion failed";
  }
}

/// Error thrown by the runtime system when a dynamic type error happens.
class TypeError extends Error {}

/// Error thrown when a function is passed an unacceptable argument.
///
/// The method should document restrictions on the arguments it accepts,
/// for example if an integer argument must be non-nullable,
/// a string argument must be non-empty,
/// or a `dynamic`-typed argument must actually have one of a few accepted
/// types.
///
/// The user should be able to predict which arguments will cause an
/// error to be throw, and avoid calling with those.
///
/// It's almost always a good idea to provide the unacceptable value
/// as part of the error, to help the user figure out what vent wrong,
/// so the [ArgumentError.value] constructor is the preferred constructor.
/// Use [ArgumentError.new] only when the value cannot be provided for some
/// reason.
class ArgumentError extends Error {
  /// Whether value was provided.
  final bool _hasValue;

  /// The invalid value.
  final dynamic invalidValue;

  /// Name of the invalid argument, if available.
  final String? name;

  /// Message describing the problem.
  final dynamic message;

  /// Creates an error with [message] describing the problem with an argument.
  ///
  /// Existing code may be using `message` to hold the invalid value.
  /// If the `message` is not a [String], it is assumed to be a value instead
  /// of a message.
  ///
  /// If [name] is provided, it should be the name of the parameter
  /// which received an invalid argument.
  ///
  /// Prefer using [ArgumentError.value] instead to retain and document the
  /// invalid value as well.
  @pragma("vm:entry-point")
  ArgumentError([this.message, @Since("2.14") this.name])
      : invalidValue = null,
        _hasValue = false;

  /// Creates error containing the invalid [value].
  ///
  /// A message is built by suffixing the [message] argument with
  /// the [name] argument (if provided) and the value. Example:
  /// ```plaintext
  /// Invalid argument (foo): null
  /// ```
  /// The `name` should match the argument name of the function, but if
  /// the function is a method implementing an interface, and its argument
  /// names differ from the interface, it might be more useful to use the
  /// interface method's argument name (or just rename arguments to match).
  @pragma("vm:entry-point")
  ArgumentError.value(value, [this.name, this.message])
      : invalidValue = value,
        _hasValue = true;

  /// Creates an argument error for a `null` argument that must not be `null`.
  ArgumentError.notNull([this.name])
      : _hasValue = false,
        message = "Must not be null",
        invalidValue = null;

  /// Throws if [argument] is `null`.
  ///
  /// If [name] is supplied, it is used as the parameter name
  /// in the error message.
  ///
  /// Returns the [argument] if it is not null.
  @Since("2.1")
  static T checkNotNull<@Since("2.8") T>(T? argument, [String? name]) =>
      argument ?? (throw ArgumentError.notNull(name));

  // Helper functions for toString overridden in subclasses.
  String get _errorName => "Invalid argument${!_hasValue ? "(s)" : ""}";
  String get _errorExplanation => "";

  String toString() {
    String? name = this.name;
    String nameString = (name == null) ? "" : " ($name)";
    Object? message = this.message;
    var messageString = (message == null) ? "" : ": ${message}";
    String prefix = "$_errorName$nameString$messageString";
    if (!_hasValue) return prefix;
    // If we know the invalid value, we can try to describe the problem.
    String explanation = _errorExplanation;
    String errorValue = Error.safeToString(invalidValue);
    return "$prefix$explanation: $errorValue";
  }
}

/// Error thrown due to an argument value being outside an accepted range.
class RangeError extends ArgumentError {
  /// The minimum value that [value] is allowed to assume.
  final num? start;

  /// The maximum value that [value] is allowed to assume.
  final num? end;

  num? get invalidValue => super.invalidValue;

  // TODO(lrn): This constructor should be called only with string values.
  // It currently isn't in all cases.
  /// Create a new [RangeError] with the given [message].
  @pragma("vm:entry-point")
  RangeError(var message)
      : start = null,
        end = null,
        super(message);

  /// Create a new [RangeError] with a message for the given [value].
  ///
  /// An optional [name] can specify the argument name that has the
  /// invalid value, and the [message] can override the default error
  /// description.
  RangeError.value(num value, [String? name, String? message])
      : start = null,
        end = null,
        super.value(value, name, message ?? "Value not in range");

  /// Create a new [RangeError] for a value being outside the valid range.
  ///
  /// The allowed range is from [minValue] to [maxValue], inclusive.
  /// If `minValue` or `maxValue` are `null`, the range is infinite in
  /// that direction.
  ///
  /// For a range from 0 to the length of something, end exclusive, use
  /// [RangeError.index].
  ///
  /// An optional [name] can specify the argument name that has the
  /// invalid value, and the [message] can override the default error
  /// description.
  @pragma("vm:entry-point")
  RangeError.range(num invalidValue, int? minValue, int? maxValue,
      [String? name, String? message])
      : start = minValue,
        end = maxValue,
        super.value(invalidValue, name, message ?? "Invalid value");

  /// Creates a new [RangeError] stating that [index] is not a valid index
  /// into [indexable].
  ///
  /// An optional [name] can specify the argument name that has the
  /// invalid value, and the [message] can override the default error
  /// description.
  ///
  /// The [length] is the length of [indexable] at the time of the error.
  /// If `length` is omitted, it defaults to `indexable.length`.
  factory RangeError.index(int index, dynamic indexable,
      [String? name, String? message, int? length]) = IndexError;

  /// Check that an integer [value] lies in a specific interval.
  ///
  /// Throws if [value] is not in the interval.
  /// The interval is from [minValue] to [maxValue], both inclusive.
  ///
  /// If [name] or [message] are provided, they are used as the parameter
  /// name and message text of the thrown error.
  ///
  /// Returns [value] if it is in the interval.
  static int checkValueInInterval(int value, int minValue, int maxValue,
      [String? name, String? message]) {
    if (value < minValue || value > maxValue) {
      throw RangeError.range(value, minValue, maxValue, name, message);
    }
    return value;
  }

  /// Check that [index] is a valid index into an indexable object.
  ///
  /// Throws if [index] is not a valid index into [indexable].
  ///
  /// An indexable object is one that has a `length` and an index-operator
  /// `[]` that accepts an index if `0 <= index < length`.
  ///
  /// If [name] or [message] are provided, they are used as the parameter
  /// name and message text of the thrown error. If [name] is omitted, it
  /// defaults to `"index"`.
  ///
  /// If [length] is provided, it is used as the length of the indexable object,
  /// otherwise the length is found as `indexable.length`.
  ///
  /// Returns [index] if it is a valid index.
  static int checkValidIndex(int index, dynamic indexable,
      [String? name, int? length, String? message]) {
    length ??= (indexable.length as int);
    return IndexError.check(index, length,
        indexable: indexable, name: name, message: message);
  }

  /// Check that a range represents a slice of an indexable object.
  ///
  /// Throws if the range is not valid for an indexable object with
  /// the given [length].
  /// A range is valid for an indexable object with a given [length]
  ///
  /// if `0 <= [start] <= [end] <= [length]`.
  /// An `end` of `null` is considered equivalent to `length`.
  ///
  /// The [startName] and [endName] defaults to `"start"` and `"end"`,
  /// respectively.
  ///
  /// Returns the actual `end` value, which is `length` if `end` is `null`,
  /// and `end` otherwise.
  static int checkValidRange(int start, int? end, int length,
      [String? startName, String? endName, String? message]) {
    // Comparing with `0` as receiver produces better dart2js type inference.
    // Ditto `start > end` below.
    if (0 > start || start > length) {
      startName ??= "start";
      throw RangeError.range(start, 0, length, startName, message);
    }
    if (end != null) {
      if (start > end || end > length) {
        endName ??= "end";
        throw RangeError.range(end, start, length, endName, message);
      }
      return end;
    }
    return length;
  }

  /// Check that an integer value is non-negative.
  ///
  /// Throws if the value is negative.
  ///
  /// If [name] or [message] are provided, they are used as the parameter
  /// name and message text of the thrown error. If [name] is omitted, it
  /// defaults to `index`.
  ///
  /// Returns [value] if it is not negative.
  static int checkNotNegative(int value, [String? name, String? message]) {
    if (value < 0) {
      throw RangeError.range(value, 0, null, name ?? "index", message);
    }
    return value;
  }

  String get _errorName => "RangeError";
  String get _errorExplanation {
    assert(_hasValue);
    String explanation = "";
    num? start = this.start;
    num? end = this.end;
    if (start == null) {
      if (end != null) {
        explanation = ": Not less than or equal to $end";
      }
      // If both are null, we don't add a description of the limits.
    } else if (end == null) {
      explanation = ": Not greater than or equal to $start";
    } else if (end > start) {
      explanation = ": Not in inclusive range $start..$end";
    } else if (end < start) {
      explanation = ": Valid value range is empty";
    } else {
      // end == start.
      explanation = ": Only valid value is $start";
    }
    return explanation;
  }
}

/// A specialized [RangeError] used when an index is not in the range
/// `0..indexable.length-1`.
///
/// Also contains the indexable object, its length at the time of the error,
/// and the invalid index itself.
class IndexError extends ArgumentError implements RangeError {
  /// The indexable object that [invalidValue] was not a valid index into.
  ///
  /// Can be, for example, a [List] or [String],
  /// which both have index based operations.
  final Object? indexable;

  /// The length of [indexable] at the time of the error.
  final int length;

  int get invalidValue => super.invalidValue;

  /// Creates a new [IndexError] stating that [invalidValue] is not a valid index
  /// into [indexable].
  ///
  /// The [length] is the length of [indexable] at the time of the error.
  /// If `length` is omitted, it defaults to `indexable.length`.
  ///
  /// The message is used as part of the string representation of the error.
  @Deprecated("Use IndexError.withLength instead.")
  IndexError(int invalidValue, dynamic indexable,
      [String? name, String? message, int? length])
      : this.indexable = indexable,
        // ignore: avoid_dynamic_calls
        this.length = length ?? indexable.length,
        super.value(invalidValue, name, message ?? "Index out of range");

  /// Creates a new [IndexError] stating that [invalidValue] is not a valid index
  /// into [indexable].
  ///
  /// The [length] is the length of [indexable] at the time of the error.
  ///
  /// The message is used as part of the string representation of the error.
  @Since("2.19")
  IndexError.withLength(int invalidValue, this.length,
      {this.indexable, String? name, String? message})
      : super.value(invalidValue, name, message ?? "Index out of range");

  /// Check that [index] is a valid index into an indexable object.
  ///
  /// Throws if [index] is not a valid index.
  ///
  /// An indexable object is one that has a `length` and an index-operator
  /// `[]` that accepts an index if `0 <= index < length`.
  ///
  /// The [length] is the length of the indexable object.
  ///
  /// The [indexable], if provided, is the indexable object.
  ///
  /// The [name] is the parameter name of the index value. Defaults to "index",
  /// and can be set to null to omit a name from the error string,
  /// if the invalid index was not a parameter.
  ///
  /// The [message], if provided, is included in the error string.
  ///
  /// Returns [index] if it is a valid index.
  @Since("2.19")
  static int check(int index, int length,
      {Object? indexable, String? name, String? message}) {
    // Comparing with `0` as receiver produces better dart2js type inference.
    if (0 > index || index >= length) {
      name ??= "index";
      throw IndexError.withLength(index, length,
          indexable: indexable, name: name, message: message);
    }
    return index;
  }

  // Getters inherited from RangeError.
  int get start => 0;
  int get end => length - 1;

  String get _errorName => "RangeError";
  String get _errorExplanation {
    assert(_hasValue);
    int invalidValue = this.invalidValue;
    if (invalidValue < 0) {
      return ": index must not be negative";
    }
    if (length == 0) {
      return ": no indices are valid";
    }
    return ": index should be less than $length";
  }
}

/// Error thrown on an invalid function or method invocation.
///
/// Thrown when a dynamic function or method call provides an invalid
/// type argument or argument list to the function being called.
/// For non-dynamic invocations, static type checking prevents
/// such invalid arguments.
///
/// Also thrown by the default implementation of [Object.noSuchMethod].
class NoSuchMethodError extends Error {
  /// Creates a [NoSuchMethodError] corresponding to a failed method call.
  ///
  /// The [receiver] is the receiver of the method call.
  /// That is, the object on which the method was attempted called.
  ///
  /// The [invocation] represents the method call that failed. It
  /// should not be `null`.
  external factory NoSuchMethodError.withInvocation(
      Object? receiver, Invocation invocation);

  external String toString();
}

/// The operation was not allowed by the object.
///
/// This [Error] is thrown when an instance cannot implement one of the methods
/// in its signature.
/// For example, it's used by unmodifiable versions of collections,
/// when someone calls a modifying method.
@pragma("vm:entry-point")
class UnsupportedError extends Error {
  final String? message;
  @pragma("vm:entry-point")
  UnsupportedError(String this.message);
  String toString() => "Unsupported operation: $message";
}

/// Thrown by operations that have not been implemented yet.
///
/// This [Error] is thrown by unfinished code that hasn't yet implemented
/// all the features it needs.
///
/// If the class does not intend to implement the feature, it should throw
/// an [UnsupportedError] instead. This error is only intended for
/// use during development.
class UnimplementedError extends Error implements UnsupportedError {
  final String? message;
  UnimplementedError([this.message]);
  String toString() {
    var message = this.message;
    return (message != null)
        ? "UnimplementedError: $message"
        : "UnimplementedError";
  }
}

/// The operation was not allowed by the current state of the object.
///
/// Should be used when this particular object is currently in a state
/// which doesn't support the requested operation, but other similar
/// objects might, or the object itself can later change its state
/// to one which supports the operation.
///
/// Example: Asking for `list.first` on a currently empty list.
/// If the operation is never supported by this object or class,
/// consider using [UnsupportedError] instead.
///
/// This is a generic error used for a variety of different erroneous
/// actions. The message should be descriptive.
class StateError extends Error {
  final String message;
  @pragma("vm:entry-point")
  StateError(this.message);
  String toString() => "Bad state: $message";
}

/// Error occurring when a collection is modified during iteration.
///
/// Some modifications may be allowed for some collections, so each collection
/// ([Iterable] or similar collection of values) should declare which operations
/// are allowed during an iteration.
class ConcurrentModificationError extends Error {
  /// The object that was modified in an incompatible way.
  final Object? modifiedObject;

  ConcurrentModificationError([this.modifiedObject]);

  String toString() {
    if (modifiedObject == null) {
      return "Concurrent modification during iteration.";
    }
    return "Concurrent modification during iteration: "
        "${Error.safeToString(modifiedObject)}.";
  }
}

/// Error that the platform can use in case of memory shortage.
final class OutOfMemoryError implements Error {
  @pragma("vm:entry-point")
  const OutOfMemoryError();
  String toString() => "Out of Memory";

  StackTrace? get stackTrace => null;
}

/// Error that the platform can use in case of stack overflow.
final class StackOverflowError implements Error {
  @pragma("vm:entry-point")
  const StackOverflowError();
  String toString() => "Stack Overflow";

  StackTrace? get stackTrace => null;
}
