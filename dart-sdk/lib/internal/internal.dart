// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart._internal;

import 'dart:collection';

import 'dart:async'
    show
        Future,
        Stream,
        StreamSubscription,
        StreamTransformer,
        StreamTransformerBase,
        Zone;
import 'dart:convert' show Converter;
import 'dart:core' hide Symbol;
import 'dart:core' as core show Symbol;
import 'dart:math' show Random;
import 'dart:typed_data' show Uint8List;

part 'async_cast.dart';
part 'bytes_builder.dart';
part 'cast.dart';
part 'errors.dart';
part 'iterable.dart';
part 'list.dart';
part 'linked_list.dart';
part 'lowering.dart';
part 'patch.dart';
part 'print.dart';
part 'sort.dart';
part 'symbol.dart';

// Returns true iff `null as T` will succeed based on the
// execution mode.
external bool typeAcceptsNull<T>();

/// Unsafely treats [value] as type [T].
///
/// An unsafe cast allows casting any value to any type,
/// without any runtime type checks.
///
/// Can be used internally in platform library implementations of
/// data structures, where a value is known to have a type different
/// from its static type (like knowing that a string is definitely
/// a "_OneByteString" or that the value stored into a heterogeneous
/// list is really a value of the surrounding map).
///
/// Must only be used for casts which would definitely *succeed*
/// as a normal cast.
///
/// Should only be used for performance in performance critical code.
external T unsafeCast<T>(dynamic value);

// Powers of 10 up to 10^22 are representable as doubles.
// Powers of 10 above that are only approximate due to lack of precision.
// Used by double-parsing.
const POWERS_OF_TEN = const [
  1.0, // 0
  10.0,
  100.0,
  1000.0,
  10000.0,
  100000.0, // 5
  1000000.0,
  10000000.0,
  100000000.0,
  1000000000.0,
  10000000000.0, // 10
  100000000000.0,
  1000000000000.0,
  10000000000000.0,
  100000000000000.0,
  1000000000000000.0, // 15
  10000000000000000.0,
  100000000000000000.0,
  1000000000000000000.0,
  10000000000000000000.0,
  100000000000000000000.0, // 20
  1000000000000000000000.0,
  10000000000000000000000.0,
];

/**
 * An [Iterable] of the UTF-16 code units of a [String] in index order.
 */
final class CodeUnits extends UnmodifiableListBase<int> {
  /** The string that this is the code units of. */
  final String _string;

  CodeUnits(this._string);

  int get length => _string.length;
  int operator [](int i) => _string.codeUnitAt(i);

  static String stringOf(CodeUnits u) => u._string;
}

/// Marks a function or library as having an external implementation.
///
/// On a function, this provides a backend-specific String that can be used to
/// identify the function's implementation.
///
/// On a library, it provides a Uri that can be used to locate the native
/// library's implementation.
class ExternalName {
  final String name;
  const ExternalName(this.name);
}

// Shared hex-parsing utilities.

/// Parses a single hex-digit as code unit.
///
/// Returns a negative value if the character is not a valid hex-digit.
int hexDigitValue(int char) {
  assert(char >= 0 && char <= 0xFFFF);
  const int digit0 = 0x30;
  const int a = 0x61;
  const int f = 0x66;
  int digit = char ^ digit0;
  if (digit <= 9) return digit;
  int letter = (char | 0x20);
  if (a <= letter && letter <= f) return letter - (a - 10);
  return -1;
}

/// Parses two hex digits in a string.
///
/// Returns a negative value if either digit isn't valid.
int parseHexByte(String source, int index) {
  assert(index + 2 <= source.length);
  int digit1 = hexDigitValue(source.codeUnitAt(index));
  int digit2 = hexDigitValue(source.codeUnitAt(index + 1));
  return digit1 * 16 + digit2 - (digit2 & 256);
}

/// A reusable `null`-valued future used by `dart:async`.
///
/// **DO NOT USE.**
///
/// This future is used in situations where a future is expected,
/// but no asynchronous computation actually happens,
/// like cancelling a stream from a controller with no `onCancel` callback.
/// *Some code depends on recognizing this future in order to react
/// synchronously.*
/// It does so to avoid changing event interleaving during the null safety
/// migration where, for example, the [StreamSubscription.cancel] method
/// stopped being able to return `null`.
/// The code that would be broken by such a timing change is fragile,
/// but we are not able to simply change it.
/// For better or worse, code depends on the precise timing that our libraries
/// have so far exhibited.
///
/// This future will be removed again if we can ever do so.
/// Do not use it for anything other than preserving timing
/// during the null safety migration.
final Future<Null> nullFuture = Zone.root.run(() => Future<Null>.value(null));

/// A default hash function used by the platform in various places.
///
/// This is currently the [Jenkins hash function][1] but using masking to keep
/// values in SMI range.
///
/// [1]: http://en.wikipedia.org/wiki/Jenkins_hash_function
///
/// Use:
/// Hash each value with the hash of the previous value, then get the final
/// hash by calling finish.
/// ```
/// var hash = 0;
/// for (var value in values) {
///   hash = SystemHash.combine(hash, value.hashCode);
/// }
/// hash = SystemHash.finish(hash);
/// ```
///
/// TODO(lrn): Consider specializing this code per platform,
/// so the VM can use its 64-bit integers directly.
abstract final class SystemHash {
  static int combine(int hash, int value) {
    hash = 0x1fffffff & (hash + value);
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }

  static int hash2(int v1, int v2, int seed) {
    int hash = seed;
    hash = combine(hash, v1);
    hash = combine(hash, v2);
    return finish(hash);
  }

  static int hash3(int v1, int v2, int v3, int seed) {
    int hash = seed;
    hash = combine(hash, v1);
    hash = combine(hash, v2);
    hash = combine(hash, v3);
    return finish(hash);
  }

  static int hash4(int v1, int v2, int v3, int v4, int seed) {
    int hash = seed;
    hash = combine(hash, v1);
    hash = combine(hash, v2);
    hash = combine(hash, v3);
    hash = combine(hash, v4);
    return finish(hash);
  }

  static int hash5(int v1, int v2, int v3, int v4, int v5, int seed) {
    int hash = seed;
    hash = combine(hash, v1);
    hash = combine(hash, v2);
    hash = combine(hash, v3);
    hash = combine(hash, v4);
    hash = combine(hash, v5);
    return finish(hash);
  }

  static int hash6(int v1, int v2, int v3, int v4, int v5, int v6, int seed) {
    int hash = seed;
    hash = combine(hash, v1);
    hash = combine(hash, v2);
    hash = combine(hash, v3);
    hash = combine(hash, v4);
    hash = combine(hash, v5);
    hash = combine(hash, v6);
    return finish(hash);
  }

  static int hash7(
      int v1, int v2, int v3, int v4, int v5, int v6, int v7, int seed) {
    int hash = seed;
    hash = combine(hash, v1);
    hash = combine(hash, v2);
    hash = combine(hash, v3);
    hash = combine(hash, v4);
    hash = combine(hash, v5);
    hash = combine(hash, v6);
    hash = combine(hash, v7);
    return finish(hash);
  }

  static int hash8(int v1, int v2, int v3, int v4, int v5, int v6, int v7,
      int v8, int seed) {
    int hash = seed;
    hash = combine(hash, v1);
    hash = combine(hash, v2);
    hash = combine(hash, v3);
    hash = combine(hash, v4);
    hash = combine(hash, v5);
    hash = combine(hash, v6);
    hash = combine(hash, v7);
    hash = combine(hash, v8);
    return finish(hash);
  }

  static int hash9(int v1, int v2, int v3, int v4, int v5, int v6, int v7,
      int v8, int v9, int seed) {
    int hash = seed;
    hash = combine(hash, v1);
    hash = combine(hash, v2);
    hash = combine(hash, v3);
    hash = combine(hash, v4);
    hash = combine(hash, v5);
    hash = combine(hash, v6);
    hash = combine(hash, v7);
    hash = combine(hash, v8);
    hash = combine(hash, v9);
    return finish(hash);
  }

  static int hash10(int v1, int v2, int v3, int v4, int v5, int v6, int v7,
      int v8, int v9, int v10, int seed) {
    int hash = seed;
    hash = combine(hash, v1);
    hash = combine(hash, v2);
    hash = combine(hash, v3);
    hash = combine(hash, v4);
    hash = combine(hash, v5);
    hash = combine(hash, v6);
    hash = combine(hash, v7);
    hash = combine(hash, v8);
    hash = combine(hash, v9);
    hash = combine(hash, v10);
    return finish(hash);
  }

  static int hash11(int v1, int v2, int v3, int v4, int v5, int v6, int v7,
      int v8, int v9, int v10, int v11, int seed) {
    int hash = seed;
    hash = combine(hash, v1);
    hash = combine(hash, v2);
    hash = combine(hash, v3);
    hash = combine(hash, v4);
    hash = combine(hash, v5);
    hash = combine(hash, v6);
    hash = combine(hash, v7);
    hash = combine(hash, v8);
    hash = combine(hash, v9);
    hash = combine(hash, v10);
    hash = combine(hash, v11);
    return finish(hash);
  }

  static int hash12(int v1, int v2, int v3, int v4, int v5, int v6, int v7,
      int v8, int v9, int v10, int v11, int v12, int seed) {
    int hash = seed;
    hash = combine(hash, v1);
    hash = combine(hash, v2);
    hash = combine(hash, v3);
    hash = combine(hash, v4);
    hash = combine(hash, v5);
    hash = combine(hash, v6);
    hash = combine(hash, v7);
    hash = combine(hash, v8);
    hash = combine(hash, v9);
    hash = combine(hash, v10);
    hash = combine(hash, v11);
    hash = combine(hash, v12);
    return finish(hash);
  }

  static int hash13(int v1, int v2, int v3, int v4, int v5, int v6, int v7,
      int v8, int v9, int v10, int v11, int v12, int v13, int seed) {
    int hash = seed;
    hash = combine(hash, v1);
    hash = combine(hash, v2);
    hash = combine(hash, v3);
    hash = combine(hash, v4);
    hash = combine(hash, v5);
    hash = combine(hash, v6);
    hash = combine(hash, v7);
    hash = combine(hash, v8);
    hash = combine(hash, v9);
    hash = combine(hash, v10);
    hash = combine(hash, v11);
    hash = combine(hash, v12);
    hash = combine(hash, v13);
    return finish(hash);
  }

  static int hash14(int v1, int v2, int v3, int v4, int v5, int v6, int v7,
      int v8, int v9, int v10, int v11, int v12, int v13, int v14, int seed) {
    int hash = seed;
    hash = combine(hash, v1);
    hash = combine(hash, v2);
    hash = combine(hash, v3);
    hash = combine(hash, v4);
    hash = combine(hash, v5);
    hash = combine(hash, v6);
    hash = combine(hash, v7);
    hash = combine(hash, v8);
    hash = combine(hash, v9);
    hash = combine(hash, v10);
    hash = combine(hash, v11);
    hash = combine(hash, v12);
    hash = combine(hash, v13);
    hash = combine(hash, v14);
    return finish(hash);
  }

  static int hash15(
      int v1,
      int v2,
      int v3,
      int v4,
      int v5,
      int v6,
      int v7,
      int v8,
      int v9,
      int v10,
      int v11,
      int v12,
      int v13,
      int v14,
      int v15,
      int seed) {
    int hash = seed;
    hash = combine(hash, v1);
    hash = combine(hash, v2);
    hash = combine(hash, v3);
    hash = combine(hash, v4);
    hash = combine(hash, v5);
    hash = combine(hash, v6);
    hash = combine(hash, v7);
    hash = combine(hash, v8);
    hash = combine(hash, v9);
    hash = combine(hash, v10);
    hash = combine(hash, v11);
    hash = combine(hash, v12);
    hash = combine(hash, v13);
    hash = combine(hash, v14);
    hash = combine(hash, v15);
    return finish(hash);
  }

  static int hash16(
      int v1,
      int v2,
      int v3,
      int v4,
      int v5,
      int v6,
      int v7,
      int v8,
      int v9,
      int v10,
      int v11,
      int v12,
      int v13,
      int v14,
      int v15,
      int v16,
      int seed) {
    int hash = seed;
    hash = combine(hash, v1);
    hash = combine(hash, v2);
    hash = combine(hash, v3);
    hash = combine(hash, v4);
    hash = combine(hash, v5);
    hash = combine(hash, v6);
    hash = combine(hash, v7);
    hash = combine(hash, v8);
    hash = combine(hash, v9);
    hash = combine(hash, v10);
    hash = combine(hash, v11);
    hash = combine(hash, v12);
    hash = combine(hash, v13);
    hash = combine(hash, v14);
    hash = combine(hash, v15);
    hash = combine(hash, v16);
    return finish(hash);
  }

  static int hash17(
      int v1,
      int v2,
      int v3,
      int v4,
      int v5,
      int v6,
      int v7,
      int v8,
      int v9,
      int v10,
      int v11,
      int v12,
      int v13,
      int v14,
      int v15,
      int v16,
      int v17,
      int seed) {
    int hash = seed;
    hash = combine(hash, v1);
    hash = combine(hash, v2);
    hash = combine(hash, v3);
    hash = combine(hash, v4);
    hash = combine(hash, v5);
    hash = combine(hash, v6);
    hash = combine(hash, v7);
    hash = combine(hash, v8);
    hash = combine(hash, v9);
    hash = combine(hash, v10);
    hash = combine(hash, v11);
    hash = combine(hash, v12);
    hash = combine(hash, v13);
    hash = combine(hash, v14);
    hash = combine(hash, v15);
    hash = combine(hash, v16);
    hash = combine(hash, v17);
    return finish(hash);
  }

  static int hash18(
      int v1,
      int v2,
      int v3,
      int v4,
      int v5,
      int v6,
      int v7,
      int v8,
      int v9,
      int v10,
      int v11,
      int v12,
      int v13,
      int v14,
      int v15,
      int v16,
      int v17,
      int v18,
      int seed) {
    int hash = seed;
    hash = combine(hash, v1);
    hash = combine(hash, v2);
    hash = combine(hash, v3);
    hash = combine(hash, v4);
    hash = combine(hash, v5);
    hash = combine(hash, v6);
    hash = combine(hash, v7);
    hash = combine(hash, v8);
    hash = combine(hash, v9);
    hash = combine(hash, v10);
    hash = combine(hash, v11);
    hash = combine(hash, v12);
    hash = combine(hash, v13);
    hash = combine(hash, v14);
    hash = combine(hash, v15);
    hash = combine(hash, v16);
    hash = combine(hash, v17);
    hash = combine(hash, v18);
    return finish(hash);
  }

  static int hash19(
      int v1,
      int v2,
      int v3,
      int v4,
      int v5,
      int v6,
      int v7,
      int v8,
      int v9,
      int v10,
      int v11,
      int v12,
      int v13,
      int v14,
      int v15,
      int v16,
      int v17,
      int v18,
      int v19,
      int seed) {
    int hash = seed;
    hash = combine(hash, v1);
    hash = combine(hash, v2);
    hash = combine(hash, v3);
    hash = combine(hash, v4);
    hash = combine(hash, v5);
    hash = combine(hash, v6);
    hash = combine(hash, v7);
    hash = combine(hash, v8);
    hash = combine(hash, v9);
    hash = combine(hash, v10);
    hash = combine(hash, v11);
    hash = combine(hash, v12);
    hash = combine(hash, v13);
    hash = combine(hash, v14);
    hash = combine(hash, v15);
    hash = combine(hash, v16);
    hash = combine(hash, v17);
    hash = combine(hash, v18);
    hash = combine(hash, v19);
    return finish(hash);
  }

  static int hash20(
      int v1,
      int v2,
      int v3,
      int v4,
      int v5,
      int v6,
      int v7,
      int v8,
      int v9,
      int v10,
      int v11,
      int v12,
      int v13,
      int v14,
      int v15,
      int v16,
      int v17,
      int v18,
      int v19,
      int v20,
      int seed) {
    int hash = seed;
    hash = combine(hash, v1);
    hash = combine(hash, v2);
    hash = combine(hash, v3);
    hash = combine(hash, v4);
    hash = combine(hash, v5);
    hash = combine(hash, v6);
    hash = combine(hash, v7);
    hash = combine(hash, v8);
    hash = combine(hash, v9);
    hash = combine(hash, v10);
    hash = combine(hash, v11);
    hash = combine(hash, v12);
    hash = combine(hash, v13);
    hash = combine(hash, v14);
    hash = combine(hash, v15);
    hash = combine(hash, v16);
    hash = combine(hash, v17);
    hash = combine(hash, v18);
    hash = combine(hash, v19);
    hash = combine(hash, v20);
    return finish(hash);
  }

  /// Bit shuffling operation to improve hash codes.
  ///
  /// Dart integers have very simple hash codes (their value),
  /// which is acceptable for the hash above because it smears the bits
  /// as part of the combination.
  /// However, for the unordered hash, we need to improve
  /// the hash code of, e.g., integers, to avoid collections of small integers
  /// too easily having colliding hash results.
  ///
  /// Assumes the input hash code is an unsigned 32-bit integer.
  /// Found by Christopher Wellons and parameters adjusted by TheIronBorn,
  /// <https://github.com/skeeto/hash-prospector>.
  static int smear(int x) {
    x ^= x >>> 16;
    x = (x * 0x21f0aaad) & 0xFFFFFFFF;
    x ^= x >>> 15;
    x = (x * 0xd35a2d97) & 0xFFFFFFFF;
    x ^= x >>> 15;
    return x;
  }
}

/// Sentinel values that should never be exposed outside of platform libraries.
class SentinelValue {
  final int id;
  const SentinelValue(this.id);
}

/// A default value to use when only one sentinel is needed.
const Object sentinelValue = const SentinelValue(0);

/// Given an [instance] of some generic type [T], and [extract], a first-class
/// generic function that takes the same number of type parameters as [T],
/// invokes the function with the same type arguments that were passed to T
/// when [instance] was constructed.
///
/// Example:
///
/// ```dart template:top
/// class Two<A, B> {}
///
/// print(extractTypeArguments<List>(<int>[], <T>() => new Set<T>()));
/// // Prints: Instance of 'Set<int>'.
///
/// print(extractTypeArguments<Map>(<String, bool>{},
///     <T, S>() => new Two<T, S>));
/// // Prints: Instance of 'Two<String, bool>'.
/// ```
///
/// The type argument T is important to choose which specific type parameter
/// list in [instance]'s type hierarchy is being extracted. Consider:
///
/// ```dart template:top
/// class A<T> {}
/// class B<T> {}
///
/// class C implements A<int>, B<String> {}
///
/// main() {
///   var c = new C();
///   print(extractTypeArguments<A>(c, <T>() => <T>[]));
///   // Prints: Instance of 'List<int>'.
///
///   print(extractTypeArguments<B>(c, <T>() => <T>[]));
///   // Prints: Instance of 'List<String>'.
/// }
/// ```
///
/// A caller must not:
///
/// *   Pass `null` for [instance].
/// *   Use a non-class type (i.e. a function type) for [T].
/// *   Use a non-generic type for [T].
/// *   Pass an instance of a generic type and a function that don't both take
///     the same number of type arguments:
///
///     ```dart
///     extractTypeArguments<List>(<int>[], <T, S>() => null);
///     ```
///
/// See this issue for more context:
/// https://github.com/dart-lang/sdk/issues/31371
external Object? extractTypeArguments<T>(T instance, Function extract);

/// Annotation class marking the version where SDK API was added.
///
/// A `Since` annotation can be applied to a library declaration,
/// any public declaration in a library, or in a class, or to
/// an optional parameter.
///
/// It signifies that the export, member or parameter was *added* in
/// that version.
///
/// When applied to a library declaration, it also a applies to
/// all members declared or exported by that library.
/// If applied to a class, it also applies to all members and constructors
/// of that class.
/// If applied to a class method, or parameter of such,
/// any method implementing that interface method is also annotated.
/// If multiple `Since` annotations apply to the same declaration or
/// parameter, the latest version takes precedence.
///
/// Any use of a marked API may trigger a warning if the using code
/// does not require an SDK version guaranteeing that the API is available,
/// unless the API feature is also provided by something else.
/// It is only a problem if an annotated feature is used, and the annotated
/// API is the *only* thing providing the functionality.
/// For example, using `Future` exported by `dart:core` is not a problem
/// if the same library also imports `dart:async`, and using an optional
/// parameter on an interface is not a problem if the same type also
/// implements another interface providing the same parameter.
///
/// The version must be a semantic version (like `1.4.2` or `0.9.4-rec.4`),
/// or the first two numbers of a semantic version (like `1.0` or `2.2`),
/// representing a stable release, and equivalent to the semantic version
/// you get by appending a `.0`.
@Since("2.2")
class Since {
  final String version;
  const Since(this.version);
}

/// A null-check function for function parameters in Null Safety enabled code.
///
/// Because Dart does not have full null safety
/// until all legacy code has been removed from a program,
/// a non-nullable parameter can still end up with a `null` value.
/// This function can be used to guard those functions against null arguments.
/// It throws a [TypeError] because we are really seeing the failure to
/// assign `null` to a non-nullable type.
///
/// See http://dartbug.com/40614 for context.
T checkNotNullable<T extends Object>(T value, String name) {
  if ((value as dynamic) == null) {
    throw NotNullableError<T>(name);
  }
  return value;
}

/// A [TypeError] thrown by [checkNotNullable].
class NotNullableError<T> extends Error implements TypeError {
  final String _name;
  NotNullableError(this._name);
  String toString() => "Null is not a valid value for '$_name' of type '$T'";
}

/// A function that returns the value or default value (if invoked with `null`
/// value) for non-nullable function parameters in Null safety enabled code.
///
/// Because Dart does not have full null safety
/// until all legacy code has been removed from a program,
/// a non-nullable parameter can still end up with a `null` value.
/// This function can be used to get a default value for a parameter
/// when a `null` value is passed in for a non-nullable parameter.
///
/// TODO(40810) - Remove uses of this function when Dart has full null safety.
T valueOfNonNullableParamWithDefault<T extends Object>(T value, T defaultVal) {
  if ((value as dynamic) == null) {
    return defaultVal;
  } else {
    return value;
  }
}

/**
 * HTTP status codes.  Exported in dart:io and dart:html.
 */
abstract class HttpStatus {
  static const int continue_ = 100;
  static const int switchingProtocols = 101;
  @Since("2.1")
  static const int processing = 102;
  static const int ok = 200;
  static const int created = 201;
  static const int accepted = 202;
  static const int nonAuthoritativeInformation = 203;
  static const int noContent = 204;
  static const int resetContent = 205;
  static const int partialContent = 206;
  @Since("2.1")
  static const int multiStatus = 207;
  @Since("2.1")
  static const int alreadyReported = 208;
  @Since("2.1")
  static const int imUsed = 226;
  static const int multipleChoices = 300;
  static const int movedPermanently = 301;
  static const int found = 302;
  static const int movedTemporarily = 302; // Common alias for found.
  static const int seeOther = 303;
  static const int notModified = 304;
  static const int useProxy = 305;
  static const int temporaryRedirect = 307;
  @Since("2.1")
  static const int permanentRedirect = 308;
  static const int badRequest = 400;
  static const int unauthorized = 401;
  static const int paymentRequired = 402;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int methodNotAllowed = 405;
  static const int notAcceptable = 406;
  static const int proxyAuthenticationRequired = 407;
  static const int requestTimeout = 408;
  static const int conflict = 409;
  static const int gone = 410;
  static const int lengthRequired = 411;
  static const int preconditionFailed = 412;
  static const int requestEntityTooLarge = 413;
  static const int requestUriTooLong = 414;
  static const int unsupportedMediaType = 415;
  static const int requestedRangeNotSatisfiable = 416;
  static const int expectationFailed = 417;
  @Since("2.1")
  static const int misdirectedRequest = 421;
  @Since("2.1")
  static const int unprocessableEntity = 422;
  @Since("2.1")
  static const int locked = 423;
  @Since("2.1")
  static const int failedDependency = 424;
  static const int upgradeRequired = 426;
  @Since("2.1")
  static const int preconditionRequired = 428;
  @Since("2.1")
  static const int tooManyRequests = 429;
  @Since("2.1")
  static const int requestHeaderFieldsTooLarge = 431;
  @Since("2.1")
  static const int connectionClosedWithoutResponse = 444;
  @Since("2.1")
  static const int unavailableForLegalReasons = 451;
  @Since("2.1")
  static const int clientClosedRequest = 499;
  static const int internalServerError = 500;
  static const int notImplemented = 501;
  static const int badGateway = 502;
  static const int serviceUnavailable = 503;
  static const int gatewayTimeout = 504;
  static const int httpVersionNotSupported = 505;
  @Since("2.1")
  static const int variantAlsoNegotiates = 506;
  @Since("2.1")
  static const int insufficientStorage = 507;
  @Since("2.1")
  static const int loopDetected = 508;
  @Since("2.1")
  static const int notExtended = 510;
  @Since("2.1")
  static const int networkAuthenticationRequired = 511;
  // Client generated status code.
  static const int networkConnectTimeoutError = 599;

  @Deprecated("Use continue_ instead")
  static const int CONTINUE = continue_;
  @Deprecated("Use switchingProtocols instead")
  static const int SWITCHING_PROTOCOLS = switchingProtocols;
  @Deprecated("Use ok instead")
  static const int OK = ok;
  @Deprecated("Use created instead")
  static const int CREATED = created;
  @Deprecated("Use accepted instead")
  static const int ACCEPTED = accepted;
  @Deprecated("Use nonAuthoritativeInformation instead")
  static const int NON_AUTHORITATIVE_INFORMATION = nonAuthoritativeInformation;
  @Deprecated("Use noContent instead")
  static const int NO_CONTENT = noContent;
  @Deprecated("Use resetContent instead")
  static const int RESET_CONTENT = resetContent;
  @Deprecated("Use partialContent instead")
  static const int PARTIAL_CONTENT = partialContent;
  @Deprecated("Use multipleChoices instead")
  static const int MULTIPLE_CHOICES = multipleChoices;
  @Deprecated("Use movedPermanently instead")
  static const int MOVED_PERMANENTLY = movedPermanently;
  @Deprecated("Use found instead")
  static const int FOUND = found;
  @Deprecated("Use movedTemporarily instead")
  static const int MOVED_TEMPORARILY = movedTemporarily;
  @Deprecated("Use seeOther instead")
  static const int SEE_OTHER = seeOther;
  @Deprecated("Use notModified instead")
  static const int NOT_MODIFIED = notModified;
  @Deprecated("Use useProxy instead")
  static const int USE_PROXY = useProxy;
  @Deprecated("Use temporaryRedirect instead")
  static const int TEMPORARY_REDIRECT = temporaryRedirect;
  @Deprecated("Use badRequest instead")
  static const int BAD_REQUEST = badRequest;
  @Deprecated("Use unauthorized instead")
  static const int UNAUTHORIZED = unauthorized;
  @Deprecated("Use paymentRequired instead")
  static const int PAYMENT_REQUIRED = paymentRequired;
  @Deprecated("Use forbidden instead")
  static const int FORBIDDEN = forbidden;
  @Deprecated("Use notFound instead")
  static const int NOT_FOUND = notFound;
  @Deprecated("Use methodNotAllowed instead")
  static const int METHOD_NOT_ALLOWED = methodNotAllowed;
  @Deprecated("Use notAcceptable instead")
  static const int NOT_ACCEPTABLE = notAcceptable;
  @Deprecated("Use proxyAuthenticationRequired instead")
  static const int PROXY_AUTHENTICATION_REQUIRED = proxyAuthenticationRequired;
  @Deprecated("Use requestTimeout instead")
  static const int REQUEST_TIMEOUT = requestTimeout;
  @Deprecated("Use conflict instead")
  static const int CONFLICT = conflict;
  @Deprecated("Use gone instead")
  static const int GONE = gone;
  @Deprecated("Use lengthRequired instead")
  static const int LENGTH_REQUIRED = lengthRequired;
  @Deprecated("Use preconditionFailed instead")
  static const int PRECONDITION_FAILED = preconditionFailed;
  @Deprecated("Use requestEntityTooLarge instead")
  static const int REQUEST_ENTITY_TOO_LARGE = requestEntityTooLarge;
  @Deprecated("Use requestUriTooLong instead")
  static const int REQUEST_URI_TOO_LONG = requestUriTooLong;
  @Deprecated("Use unsupportedMediaType instead")
  static const int UNSUPPORTED_MEDIA_TYPE = unsupportedMediaType;
  @Deprecated("Use requestedRangeNotSatisfiable instead")
  static const int REQUESTED_RANGE_NOT_SATISFIABLE =
      requestedRangeNotSatisfiable;
  @Deprecated("Use expectationFailed instead")
  static const int EXPECTATION_FAILED = expectationFailed;
  @Deprecated("Use upgradeRequired instead")
  static const int UPGRADE_REQUIRED = upgradeRequired;
  @Deprecated("Use internalServerError instead")
  static const int INTERNAL_SERVER_ERROR = internalServerError;
  @Deprecated("Use notImplemented instead")
  static const int NOT_IMPLEMENTED = notImplemented;
  @Deprecated("Use badGateway instead")
  static const int BAD_GATEWAY = badGateway;
  @Deprecated("Use serviceUnavailable instead")
  static const int SERVICE_UNAVAILABLE = serviceUnavailable;
  @Deprecated("Use gatewayTimeout instead")
  static const int GATEWAY_TIMEOUT = gatewayTimeout;
  @Deprecated("Use httpVersionNotSupported instead")
  static const int HTTP_VERSION_NOT_SUPPORTED = httpVersionNotSupported;
  @Deprecated("Use networkConnectTimeoutError instead")
  static const int NETWORK_CONNECT_TIMEOUT_ERROR = networkConnectTimeoutError;
}

// Class moved here from dart:collection
// to allow another, more important, class to implement the interface
// without having to match the private members.

/// An entry in a doubly linked list.
///
/// Such an entry contains an element and a link to the previous or next
/// entries, if any.
//
// This class should have been abstract, but originally wasn't.
// It's not used itself to interact with the double linked queue class,
// which uses the `_DoubleLinkedQueueEntry` class and subclasses instead.
// It's only used as an interface for the
// `DoubleLinkedQueue.forEach`, `DoubleLinkedQueue.firstEntry` and
// `DoubleLinkedQueue.lastEntry` members.
// Still, someone might have based their own double-linked list on this
// class, so we keep it functional.
//
// Should really be marked `base`, but the only use in the platform
// libraries is to implement the interface in a class which used to have
// this publicly visible type.
//
// TODO: @Deprecated("Will be removed in a future release")
class DoubleLinkedQueueEntry<E> {
  DoubleLinkedQueueEntry<E>? _previousLink;
  DoubleLinkedQueueEntry<E>? _nextLink;

  /// The element of the entry in the queue.
  E element;

  /// Creates a new entry with the given [element].
  DoubleLinkedQueueEntry(this.element);

  void _link(
      DoubleLinkedQueueEntry<E>? previous, DoubleLinkedQueueEntry<E>? next) {
    _nextLink = next;
    _previousLink = previous;
    previous?._nextLink = this;
    next?._previousLink = this;
  }

  /// Appends the given element [e] as entry just after this entry.
  void append(E e) {
    DoubleLinkedQueueEntry<E>(e)._link(this, _nextLink);
  }

  /// Prepends the given [e] as entry just before this entry.
  void prepend(E e) {
    DoubleLinkedQueueEntry<E>(e)._link(_previousLink, this);
  }

  /// Removes this entry from any chain of entries it is part of.
  ///
  /// Returns its element value.
  E remove() {
    _previousLink?._nextLink = _nextLink;
    _nextLink?._previousLink = _previousLink;
    _nextLink = null;
    _previousLink = null;
    return element;
  }

  /// The previous entry, or `null` if there is none.
  DoubleLinkedQueueEntry<E>? previousEntry() => _previousLink;

  /// The next entry, or `null` if there is none.
  DoubleLinkedQueueEntry<E>? nextEntry() => _nextLink;
}

/// Annotation on a class preventing instances from being sent between isolates.
///
/// Applies to class, mixin or enum declarations, and is inherited by subclasses
/// along extends, with and implements relations.
///
/// An instance of a class with this annotation will be prevented from being
/// part of isolate communication. It cannot be sent through a SendPort,
/// not even if both ends are in the same isolate, and it cannot be part of
/// the initial message of isolate spawn operations.
///
/// The annotation is intended for classes which have a dynamic link
/// to the current isolate, for example being tied to the event loop
/// through scheduled events or timers, which would put the object into
/// an inconsistent state if simply being copied.
const vmIsolateUnsendable = pragma("vm:isolate-unsendable");

// Helpers used to detect cycles in collection `toString`s.

/// A collection used to identify cyclic lists during `toString` calls.
final List<Object> toStringVisiting = [];

/// Check if we are currently visiting [object] in a `toString` call.
bool isToStringVisiting(Object object) {
  for (int i = 0; i < toStringVisiting.length; i++) {
    if (identical(object, toStringVisiting[i])) return true;
  }
  return false;
}
