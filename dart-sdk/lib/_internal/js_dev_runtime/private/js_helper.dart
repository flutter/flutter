// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart._js_helper;

import 'dart:async' show Zone;
import 'dart:collection';

import 'dart:_foreign_helper' show JS, JS_CLASS_REF, JS_GET_FLAG, JSExportName;

import 'dart:_interceptors';
import 'dart:_internal'
    show
        EfficientLengthIterable,
        HideEfficientLengthIterable,
        MappedIterable,
        IterableElementError,
        SubListIterable,
        patch;

import 'dart:_native_typed_data';
import 'dart:_rti' as rti show pairwiseIsTest, evaluateRtiForRecord, Rti;
import 'dart:_runtime' as dart;

part 'annotations.dart';
part 'linked_hash_map.dart';
part 'identity_hash_map.dart';
part 'custom_hash_map.dart';
part 'native_helper.dart';
part 'regexp_helper.dart';
part 'string_helper.dart';
part 'js_rti.dart';

/// Adapts a JS `[Symbol.iterator]` to a Dart `get iterator`.
///
/// This is the inverse of `JsIterator`, for classes where we can more
/// efficiently obtain a JS iterator instead of a Dart one.
///
// TODO(jmesserly): this adapter is to work around
// https://github.com/dart-lang/sdk/issues/28320
class DartIterator<E> implements Iterator<E> {
  final _jsIterator;
  E? _current;

  DartIterator(this._jsIterator);

  E get current => _current as E;

  bool moveNext() {
    final ret = JS('', '#.next()', _jsIterator);
    _current = JS('', '#.value', ret);
    return JS<bool>('!', '!#.done', ret);
  }
}

/// Used to compile `sync*`.
class SyncIterable<E> extends Iterable<E> {
  final Function() _initGenerator;
  SyncIterable(this._initGenerator);

  @JSExportName('Symbol.iterator')
  _jsIterator() => _initGenerator();

  get iterator => DartIterator(_initGenerator());
}

class Primitives {
  static int? parseInt(@nullCheck String source, int? _radix) {
    var re = JS('', r'/^\s*[+-]?((0x[a-f0-9]+)|(\d+)|([a-z0-9]+))\s*$/i');
    // This isn't reified List<String?>?, but it's safe to use as long as we use
    // it locally and don't expose it to user code.
    var match = JS<List<String?>?>('', '#.exec(#)', re, source);
    int digitsIndex = 1;
    int hexIndex = 2;
    int decimalIndex = 3;
    if (match == null) {
      // TODO(sra): It might be that the match failed due to unrecognized U+0085
      // spaces.  We could replace them with U+0020 spaces and try matching
      // again.
      return null;
    }
    var decimalMatch = match[decimalIndex];
    if (_radix == null) {
      if (decimalMatch != null) {
        // Cannot fail because we know that the digits are all decimal.
        return JS<int>('!', r'parseInt(#, 10)', source);
      }
      if (match[hexIndex] != null) {
        // Cannot fail because we know that the digits are all hex.
        return JS<int>('!', r'parseInt(#, 16)', source);
      }
      return null;
    }
    @notNull
    var radix = _radix;
    if (radix < 2 || radix > 36) {
      throw RangeError.range(radix, 2, 36, 'radix');
    }
    if (radix == 10 && decimalMatch != null) {
      // Cannot fail because we know that the digits are all decimal.
      return JS<int>('!', r'parseInt(#, 10)', source);
    }
    // If radix >= 10 and we have only decimal digits the string is safe.
    // Otherwise we need to check the digits.
    if (radix < 10 || decimalMatch == null) {
      // We know that the characters must be ASCII as otherwise the
      // regexp wouldn't have matched. Lowercasing by doing `| 0x20` is thus
      // guaranteed to be a safe operation, since it preserves digits
      // and lower-cases ASCII letters.
      int maxCharCode;
      if (radix <= 10) {
        // Allow all digits less than the radix. For example 0, 1, 2 for
        // radix 3.
        // "0".codeUnitAt(0) + radix - 1;
        maxCharCode = (0x30 - 1) + radix;
      } else {
        // Letters are located after the digits in ASCII. Therefore we
        // only check for the character code. The regexp above made already
        // sure that the string does not contain anything but digits or
        // letters.
        // "a".codeUnitAt(0) + (radix - 10) - 1;
        maxCharCode = (0x61 - 10 - 1) + radix;
      }
      assert(match[digitsIndex] is String);
      String digitsPart = JS<String>('!', '#[#]', match, digitsIndex);
      for (int i = 0; i < digitsPart.length; i++) {
        int characterCode = digitsPart.codeUnitAt(i) | 0x20;
        if (characterCode > maxCharCode) {
          return null;
        }
      }
    }
    // The above matching and checks ensures the source has at least one digits
    // and all digits are suitable for the radix, so parseInt cannot return NaN.
    return JS<int>('!', r'parseInt(#, #)', source, radix);
  }

  static double? parseDouble(@nullCheck String source) {
    // Notice that JS parseFloat accepts garbage at the end of the string.
    // Accept only:
    // - [+/-]NaN
    // - [+/-]Infinity
    // - a Dart double literal
    // We do allow leading or trailing whitespace.
    if (!JS(
        'bool',
        r'/^\s*[+-]?(?:Infinity|NaN|'
            r'(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(#)',
        source)) {
      return null;
    }
    var result = JS<double>('!', r'parseFloat(#)', source);
    if (result.isNaN) {
      var trimmed = source.trim();
      if (trimmed == 'NaN' || trimmed == '+NaN' || trimmed == '-NaN') {
        return result;
      }
      return null;
    }
    return result;
  }

  static bool? parseBool(
      @nullCheck String source, @nullCheck bool caseSensitive) {
    if (caseSensitive) {
      return JS('bool', r'# == "true" || # != "false" && null', source, source);
    }
    return _compareIgnoreCase(source, "true")
        ? true
        : _compareIgnoreCase(source, "false")
            ? false
            : null;
  }

  /// Compares a string against an ASCII lower-case letter-only string.
  ///
  /// Returns `true` if the [input] has the same length and same letters
  /// as [lowerCaseTarget], `false` if not.
  static bool _compareIgnoreCase(String input, String lowerCaseTarget) {
    if (input.length != lowerCaseTarget.length) return false;
    var delta = 0x20;
    for (var i = 0; i < input.length; i++) {
      delta |= input.codeUnitAt(i) ^ lowerCaseTarget.codeUnitAt(i);
    }
    return delta == 0x20;
  }

  static String stringSafeToString(String str) {
    return JS<String>('!', 'JSON.stringify(#)', str);
  }

  static String safeToString(obj) {
    if (obj == null || obj is num || obj is bool) {
      return obj.toString();
    }
    if (obj is String) {
      return stringSafeToString(obj);
    }
    if (obj is dart.RecordImpl) {
      return dart.recordSafeToString(obj);
    }
    return "Instance of '${dart.typeName(dart.getReifiedType(obj))}'";
  }

  /// `r"$".codeUnitAt(0)`
  static const int DOLLAR_CHAR_VALUE = 36;

  static int dateNow() => JS<int>('!', r'Date.now()');

  static void initTicker() {
    if (timerFrequency != 0) return;
    // Start with low-resolution. We overwrite the fields if we find better.
    timerFrequency = 1000;
    if (JS<bool>('!', 'typeof window == "undefined"')) return;
    var jsWindow = JS('var', 'window');
    if (jsWindow == null) return;
    var performance = JS('var', '#.performance', jsWindow);
    if (performance == null) return;
    if (JS<bool>('!', 'typeof #.now != "function"', performance)) return;
    timerFrequency = 1000000;
    timerTicks = () => (1000 * JS<num>('!', '#.now()', performance)).floor();
  }

  /// 0 frequency indicates the default uninitialized state.
  static int timerFrequency = 0;
  static int Function() timerTicks = dateNow; // Low-resolution version.

  static bool get isD8 {
    return JS(
        'bool',
        'typeof version == "function"'
            ' && typeof os == "object" && "system" in os');
  }

  static bool get isJsshell {
    return JS(
        'bool', 'typeof version == "function" && typeof system == "function"');
  }

  static String currentUri() {
    // In a browser return self.location.href.
    if (JS<bool>('!', '!!#.location', dart.global_)) {
      return JS<String>('!', '#.location.href', dart.global_);
    }

    // TODO(vsm): Consider supporting properly in non-browser settings.
    return '';
  }

  // This is to avoid stack overflows due to very large argument arrays in
  // apply().  It fixes http://dartbug.com/6919
  @notNull
  static String _fromCharCodeApply(List<int> array) {
    const kMaxApply = 500;
    @nullCheck
    int end = array.length;
    if (end <= kMaxApply) {
      return JS<String>('!', r'String.fromCharCode.apply(null, #)', array);
    }
    String result = '';
    for (int i = 0; i < end; i += kMaxApply) {
      int chunkEnd = (i + kMaxApply < end) ? i + kMaxApply : end;
      result = JS(
          'String',
          r'# + String.fromCharCode.apply(null, #.slice(#, #))',
          result,
          array,
          i,
          chunkEnd);
    }
    return result;
  }

  @notNull
  static String stringFromCodePoints(JSArray<int> codePoints) {
    List<int> a = <int>[];
    for (@nullCheck var i in codePoints) {
      if (i <= 0xffff) {
        a.add(i);
      } else if (i <= 0x10ffff) {
        a.add(0xd800 + ((((i - 0x10000) >> 10) & 0x3ff)));
        a.add(0xdc00 + (i & 0x3ff));
      } else {
        throw argumentErrorValue(i);
      }
    }
    return _fromCharCodeApply(a);
  }

  @notNull
  static String stringFromCharCodes(JSArray<int> charCodes) {
    for (@nullCheck var i in charCodes) {
      if (i < 0) throw argumentErrorValue(i);
      if (i > 0xffff) return stringFromCodePoints(charCodes);
    }
    return _fromCharCodeApply(charCodes);
  }

  // [start] and [end] are validated.
  @notNull
  static String stringFromNativeUint8List(
      NativeUint8List charCodes, @nullCheck int start, @nullCheck int end) {
    const kMaxApply = 500;
    if (end <= kMaxApply && start == 0 && end == charCodes.length) {
      return JS<String>('!', r'String.fromCharCode.apply(null, #)', charCodes);
    }
    String result = '';
    for (int i = start; i < end; i += kMaxApply) {
      int chunkEnd = (i + kMaxApply < end) ? i + kMaxApply : end;
      result = JS(
          'String',
          r'# + String.fromCharCode.apply(null, #.subarray(#, #))',
          result,
          charCodes,
          i,
          chunkEnd);
    }
    return result;
  }

  @notNull
  static String stringFromCharCode(@nullCheck int charCode) {
    if (0 <= charCode) {
      if (charCode <= 0xffff) {
        return JS<String>('!', 'String.fromCharCode(#)', charCode);
      }
      if (charCode <= 0x10ffff) {
        var bits = charCode - 0x10000;
        var low = 0xDC00 | (bits & 0x3ff);
        var high = 0xD800 | (bits >> 10);
        return JS<String>('!', 'String.fromCharCode(#, #)', high, low);
      }
    }
    throw RangeError.range(charCode, 0, 0x10ffff);
  }

  static String flattenString(String str) {
    return JS<String>('!', "#.charCodeAt(0) == 0 ? # : #", str, str, str);
  }

  static String getTimeZoneName(DateTime receiver) {
    // Firefox and Chrome emit the timezone in parenthesis.
    // Example: "Wed May 16 2012 21:13:00 GMT+0200 (CEST)".
    // We extract this name using a regexp.
    var d = lazyAsJsDate(receiver);
    // In this method all calls to `exec()` include a single capture group and
    // it is only read if there is a match so a value will be present. To avoid
    // extra null checks or casts from dynamic we type the return type of
    // `exec()` to always contain non-nullable Strings.
    var match = JS<List<String>?>('', r'/\((.*)\)/.exec(#.toString())', d);
    if (match != null) return match[1];

    // Internet Explorer 10+ emits the zone name without parenthesis:
    // Example: Thu Oct 31 14:07:44 PDT 2013
    match = JS<List<String>?>(
        '',
        // Thu followed by a space.
        r'/^[A-Z,a-z]{3}\s'
            // Oct 31 followed by space.
            r'[A-Z,a-z]{3}\s\d+\s'
            // Time followed by a space.
            r'\d{2}:\d{2}:\d{2}\s'
            // The time zone name followed by a space.
            r'([A-Z]{3,5})\s'
            // The year.
            r'\d{4}$/'
            '.exec(#.toString())',
        d);
    if (match != null) return match[1];

    // IE 9 and Opera don't provide the zone name. We fall back to emitting the
    // UTC/GMT offset.
    // Example (IE9): Wed Nov 20 09:51:00 UTC+0100 2013
    //       (Opera): Wed Nov 20 2013 11:03:38 GMT+0100
    match =
        JS<List<String>?>('', r'/(?:GMT|UTC)[+-]\d{4}/.exec(#.toString())', d);
    if (match != null) return match[0];
    return "";
  }

  static int getTimeZoneOffsetInMinutes(DateTime receiver) {
    // Note that JS and Dart disagree on the sign of the offset.
    return -JS<int>('!', r'#.getTimezoneOffset()', lazyAsJsDate(receiver));
  }

  static int? valueFromDecomposedDate(
      @nullCheck int years,
      @nullCheck int month,
      @nullCheck int day,
      @nullCheck int hours,
      @nullCheck int minutes,
      @nullCheck int seconds,
      @nullCheck int milliseconds,
      @nullCheck int microseconds,
      @nullCheck bool isUtc) {
    final int MAX_MILLISECONDS_SINCE_EPOCH = 8640000000000000;
    var jsMonth = month - 1;
    // The JavaScript Date constructor 'corrects' year NN to 19NN. Sidestep that
    // correction by adjusting years out of that range and compensating with an
    // adjustment of months. This hack should not be sensitive to leap years but
    // use 400 just in case.
    if (0 <= years && years < 100) {
      years += 400;
      jsMonth -= 400 * 12;
    }
    // JavaScript `Date` does not handle microseconds, so ensure the provided
    // microseconds is in range [0..999].
    final remainder = microseconds % 1000;
    milliseconds += (microseconds - remainder) ~/ 1000;
    microseconds = remainder;
    int value;
    if (isUtc) {
      value = JS<int>('!', r'Date.UTC(#, #, #, #, #, #, #)', years, jsMonth,
          day, hours, minutes, seconds, milliseconds);
    } else {
      value = JS<int>('!', r'new Date(#, #, #, #, #, #, #).valueOf()', years,
          jsMonth, day, hours, minutes, seconds, milliseconds);
    }
    if (value.isNaN ||
        value < -MAX_MILLISECONDS_SINCE_EPOCH ||
        value > MAX_MILLISECONDS_SINCE_EPOCH ||
        value == MAX_MILLISECONDS_SINCE_EPOCH && microseconds != 0) {
      return null;
    }
    return value;
  }

  // Lazily keep a JS Date stored in the JS object.
  static lazyAsJsDate(DateTime receiver) {
    if (JS<bool>('!', r'#.date === (void 0)', receiver)) {
      JS('void', r'#.date = new Date(#)', receiver,
          receiver.millisecondsSinceEpoch);
    }
    return JS('var', r'#.date', receiver);
  }

  // The getters for date and time parts below add a positive integer to ensure
  // that the result is really an integer, because the JavaScript implementation
  // may return -0.0 instead of 0.

  static int getYear(DateTime receiver) {
    return (receiver.isUtc)
        ? JS<int>('!', r'(#.getUTCFullYear() + 0)', lazyAsJsDate(receiver))
        : JS<int>('!', r'(#.getFullYear() + 0)', lazyAsJsDate(receiver));
  }

  static int getMonth(DateTime receiver) {
    return (receiver.isUtc)
        ? JS<int>('!', r'#.getUTCMonth() + 1', lazyAsJsDate(receiver))
        : JS<int>('!', r'#.getMonth() + 1', lazyAsJsDate(receiver));
  }

  static int getDay(DateTime receiver) {
    return (receiver.isUtc)
        ? JS<int>('!', r'(#.getUTCDate() + 0)', lazyAsJsDate(receiver))
        : JS<int>('!', r'(#.getDate() + 0)', lazyAsJsDate(receiver));
  }

  static int getHours(DateTime receiver) {
    return (receiver.isUtc)
        ? JS<int>('!', r'(#.getUTCHours() + 0)', lazyAsJsDate(receiver))
        : JS<int>('!', r'(#.getHours() + 0)', lazyAsJsDate(receiver));
  }

  static int getMinutes(DateTime receiver) {
    return (receiver.isUtc)
        ? JS<int>('!', r'(#.getUTCMinutes() + 0)', lazyAsJsDate(receiver))
        : JS<int>('!', r'(#.getMinutes() + 0)', lazyAsJsDate(receiver));
  }

  static int getSeconds(DateTime receiver) {
    return (receiver.isUtc)
        ? JS<int>('!', r'(#.getUTCSeconds() + 0)', lazyAsJsDate(receiver))
        : JS<int>('!', r'(#.getSeconds() + 0)', lazyAsJsDate(receiver));
  }

  static int getMilliseconds(DateTime receiver) {
    return (receiver.isUtc)
        ? JS<int>('!', r'(#.getUTCMilliseconds() + 0)', lazyAsJsDate(receiver))
        : JS<int>('!', r'(#.getMilliseconds() + 0)', lazyAsJsDate(receiver));
  }

  static int getWeekday(DateTime receiver) {
    int weekday = (receiver.isUtc)
        ? JS<int>('!', r'#.getUTCDay() + 0', lazyAsJsDate(receiver))
        : JS<int>('!', r'#.getDay() + 0', lazyAsJsDate(receiver));
    // Adjust by one because JS weeks start on Sunday.
    return (weekday + 6) % 7 + 1;
  }

  static Object? getProperty(Object? object, Object key) {
    if (object == null || object is bool || object is num || object is String) {
      throw argumentErrorValue(object);
    }
    return JS('var', '#[#]', object, key);
  }

  static void setProperty(object, key, value) {
    if (object == null || object is bool || object is num || object is String) {
      throw argumentErrorValue(object);
    }
    JS('void', '#[#] = #', object, key, value);
  }
}

/// Diagnoses an indexing error. Returns the ArgumentError or RangeError that
/// describes the problem.
Error diagnoseIndexError(indexable, int index) {
  int length = indexable.length;
  // The following returns the same error that would be thrown by calling
  // [IndexError.check] with no optional parameters
  // provided.
  if (index < 0 || index >= length) {
    return IndexError.withLength(index, length,
        indexable: indexable, name: 'index');
  }
  // The above should always match, but if it does not, use the following.
  return RangeError.value(index, 'index');
}

/// Diagnoses a range error. Returns the ArgumentError or RangeError that
/// describes the problem.
Error diagnoseRangeError(int? start, int? end, int length) {
  if (start == null) {
    return ArgumentError.value(start, 'start');
  }
  if (start < 0 || start > length) {
    return RangeError.range(start, 0, length, 'start');
  }
  if (end != null) {
    if (end < start || end > length) {
      return RangeError.range(end, start, length, 'end');
    }
  }
  // The above should always match, but if it does not, use the following.
  return ArgumentError.value(end, "end");
}

@notNull
int stringLastIndexOfUnchecked(receiver, element, start) =>
    JS<int>('!', r'#.lastIndexOf(#, #)', receiver, element, start);

/// 'factory' for constructing ArgumentError.value to keep the call sites small.
ArgumentError argumentErrorValue(object) {
  return ArgumentError.value(object);
}

void throwArgumentErrorValue(value) {
  throw argumentErrorValue(value);
}

checkInt(value) {
  if (value is! int) throw argumentErrorValue(value);
  return value;
}

throwRuntimeError(message) {
  throw RuntimeError(message);
}

throwConcurrentModificationError(collection) {
  throw ConcurrentModificationError(collection);
}

class JsNoSuchMethodError extends Error implements NoSuchMethodError {
  final String? _message;
  final String? _method;
  final String? _receiver;

  JsNoSuchMethodError(this._message, match)
      : _method = match == null ? null : JS('String|Null', '#.method', match),
        _receiver =
            match == null ? null : JS('String|Null', '#.receiver', match);

  String toString() {
    if (_method == null) return 'NoSuchMethodError: $_message';
    if (_receiver == null) {
      return "NoSuchMethodError: method not found: '$_method' ($_message)";
    }
    return "NoSuchMethodError: "
        "method not found: '$_method' on '$_receiver' ($_message)";
  }
}

class UnknownJsTypeError extends Error {
  final String _message;

  UnknownJsTypeError(this._message);

  String toString() => _message.isEmpty ? 'Error' : 'Error: $_message';
}

/// Called by generated code to build a map literal. [keyValuePairs] is
/// a list of key, value, key, value, ..., etc.
fillLiteralMap(keyValuePairs, Map result) {
  // TODO(johnniwinther): Use JSArray to optimize this code instead of calling
  // [getLength] and [getIndex].
  int index = 0;
  int length = getLength(keyValuePairs);
  while (index < length) {
    var key = getIndex(keyValuePairs, index++);
    var value = getIndex(keyValuePairs, index++);
    result[key] = value;
  }
  return result;
}

bool jsHasOwnProperty(jsObject, String property) {
  return JS<bool>('!', r'#.hasOwnProperty(#)', jsObject, property);
}

jsPropertyAccess(jsObject, String property) {
  return JS('var', r'#[#]', jsObject, property);
}

/// A metadata annotation describing the types instantiated by a native element.
///
/// The annotation is valid on a native method and a field of a native class.
///
/// By default, a field of a native class is seen as an instantiation point for
/// all native classes that are a subtype of the field's type, and a native
/// method is seen as an instantiation point fo all native classes that are a
/// subtype of the method's return type, or the argument types of the declared
/// type of the method's callback parameter.
///
/// An @[Creates] annotation overrides the default set of instantiated types.
/// If one or more @[Creates] annotations are present, the type of the native
/// element is ignored, and the union of @[Creates] annotations is used instead.
/// The names in the strings are resolved and the program will fail to compile
/// with dart2js if they do not name types.
///
/// The argument to [Creates] is a string.  The string is parsed as the names of
/// one or more types, separated by vertical bars `|`.  There are some special
/// names:
///
/// * `=Object`. This means 'exactly Object', which is a plain JavaScript object
///   with properties and none of the subtypes of Object.
///
/// Example: we may know that a method always returns a specific implementation:
///
///     @Creates('_NodeList')
///     List<Node> getElementsByTagName(String tag) native;
///
/// Useful trick: A method can be marked as not instantiating any native classes
/// with the annotation `@Creates('Null')`.  This is useful for fields on native
/// classes that are used only in Dart code.
///
///     @Creates('Null')
///     var _cachedFoo;
class Creates {
  final String types;
  const Creates(this.types);
}

/// A metadata annotation describing the types returned or yielded by a native
/// element.
///
/// The annotation is valid on a native method and a field of a native class.
///
/// By default, a native method or field is seen as returning or yielding all
/// subtypes if the method return type or field type.  This annotation allows a
/// more precise set of types to be specified.
///
/// See [Creates] for the syntax of the argument.
///
/// Example: IndexedDB keys are numbers, strings and JavaScript Arrays of keys.
///
///     @Returns('String|num|JSExtendableArray')
///     dynamic key;
///
///     // Equivalent:
///     @Returns('String') @Returns('num') @Returns('JSExtendableArray')
///     dynamic key;
class Returns {
  final String types;
  const Returns(this.types);
}

/// A metadata annotation placed on native methods and fields of native classes
/// to specify the JavaScript name.
///
/// This example declares a Dart field + getter + setter called `$dom_title`
/// that corresponds to the JavaScript property `title`.
///
///     class Document native "*Foo" {
///       @JSName('title')
///       String $dom_title;
///     }
class JSName {
  final String name;
  const JSName(this.name);
}

/// Special interface recognized by the compiler and implemented by DOM
/// objects that support integer indexing. This interface is not
/// visible to anyone, and is only injected into special libraries.
abstract class JavaScriptIndexingBehavior<E> extends JSMutableIndexable<E> {}

/// Thrown by type assertions that fail.
class TypeErrorImpl extends Error implements TypeError {
  final String _message;

  TypeErrorImpl(this._message);

  String toString() => _message;
}

/// Error thrown when a runtime error occurs.
class RuntimeError extends Error {
  final message;
  RuntimeError(this.message);
  String toString() => "RuntimeError: $message";
}

class DeferredNotLoadedError extends Error implements NoSuchMethodError {
  String enclosingLibrary;
  String importPrefix;

  DeferredNotLoadedError(this.enclosingLibrary, this.importPrefix);

  String toString() {
    return 'Deferred import $importPrefix (from $enclosingLibrary) was not loaded.';
  }
}

/// Error thrown by DDC when an `assert()` fails (with or without a message).
class AssertionErrorImpl extends AssertionError {
  final String? _fileUri;
  final int? _line;
  final int? _column;
  final String? _conditionSource;

  AssertionErrorImpl(Object? message,
      [this._fileUri, this._line, this._column, this._conditionSource])
      : super(message);

  String toString() {
    var failureMessage = "";
    if (_fileUri != null &&
        _line != null &&
        _column != null &&
        _conditionSource != null) {
      failureMessage += "$_fileUri:${_line}:${_column}\n$_conditionSource\n";
    }
    failureMessage +=
        message != null ? Error.safeToString(message) : "is not true";

    return "Assertion failed: $failureMessage";
  }
}

/// Creates a random number with 64 bits of randomness.
///
/// This will be truncated to the 53 bits available in a double.
int random64() {
  // TODO(lrn): Use a secure random source.
  int int32a = JS("int", "(Math.random() * 0x100000000) >>> 0");
  int int32b = JS("int", "(Math.random() * 0x100000000) >>> 0");
  return int32a + int32b * 0x100000000;
}

class BooleanConversionAssertionError extends AssertionError {
  toString() => 'Failed assertion: boolean expression must not be null';
}

// Hook to register new global object.  This is invoked from dart:html
// whenever a new window is accessed for the first time.
void registerGlobalObject(object) {
  try {
    if (dart.polyfill(object)) {
      dart.applyAllExtensions(object);
    }
  } catch (e) {
    // This may fail due to cross-origin errors.  In that case, we shouldn't
    // need to polyfill as we can't get objects from that frame.

    // TODO(vsm): Detect this more robustly - ideally before we try to polyfill.
  }
}

/// Expose browser JS classes.
void applyExtension(name, nativeObject) {
  dart.applyExtension(name, nativeObject);
}

/// Hook to apply extensions on native JS classes defined in a native unit test.
void applyTestExtensions(List<String> names) {
  names.forEach(dart.applyExtensionForTesting);
}

/// Used internally by DDC to map ES6 symbols to Dart.
class PrivateSymbol implements Symbol {
  // TODO(jmesserly): could also get this off the native symbol instead of
  // storing it. Mirrors already does this conversion.
  final String _name;
  final Object _nativeSymbol;

  const PrivateSymbol(this._name, this._nativeSymbol);

  static String getName(Symbol symbol) => (symbol as PrivateSymbol)._name;

  static Object? getNativeSymbol(Symbol symbol) {
    if (symbol is PrivateSymbol) return symbol._nativeSymbol;
    return null;
  }

  bool operator ==(other) =>
      other is PrivateSymbol &&
      _name == other._name &&
      identical(_nativeSymbol, other._nativeSymbol);

  get hashCode => _name.hashCode;

  // TODO(jmesserly): is this equivalent to _nativeSymbol toString?
  toString() => 'Symbol("$_name")';
}

/// Asserts that if [value] is a function, it is a JavaScript function or has
/// been wrapped by [allowInterop].
///
/// This function does not recurse if [value] is a collection.
void assertInterop(Object? value) {
  if (value is Function) dart.assertInterop(value);
}

/// Like [assertInterop], except iterates over a list of arguments
/// non-recursively.
void assertInteropArgs(List<Object?> args) => args.forEach(assertInterop);

/// Wraps the given [callback] within the current Zone.
void Function(T)? wrapZoneUnaryCallback<T>(void Function(T)? callback) {
  // For performance reasons avoid wrapping if we are in the root zone.
  if (Zone.current == Zone.root) return callback;
  if (callback == null) return null;
  return Zone.current.bindUnaryCallbackGuarded(callback);
}

/// Returns a JavaScript predicate that tests if the argument is a record with
/// the given shape and fields types.
///
/// Only called from the `dart:_rti` library but requires specific knowledge of
/// the record representation in DDC. There is a duplicate version of this
/// method in the dart2js version of this library.
///
/// The shape is determined by the number of fields and the [partialShapeTag].
/// [fieldRtis] contains the Rti type objects for each field in order of
/// positionals followed by the sorted named elements.
Object? createRecordTypePredicate(String partialShapeTag, JSArray fieldRtis) {
  var shapeKey =
      JS<String>('!', '#.length + ";" + #', fieldRtis, partialShapeTag);
  return (obj) {
    return JS<bool>(
            '!', '# instanceof #', obj, JS_CLASS_REF(dart.RecordImpl)) &&
        JS<dart.Shape>('!', '#[#]', obj, dart.shapeProperty) ==
            JS<dart.Shape?>('', '#.get(#)', dart.shapes, shapeKey) &&
        rti.pairwiseIsTest(
            fieldRtis, JS<JSArray>('!', '#[#]', obj, dart.valuesProperty));
  };
}

/// Returns the Rti for the provided [record].
///
/// Is called from the `dart:_rti` library but requires specific knowledge of
/// the record representation in DDC. There is a duplicate version of this
/// method in the dart2js version of this library.
///
/// Calls [rti.evaluateRtiForRecord] with components of the [record].
rti.Rti getRtiForRecord(Object? record) {
  var recordObj = JS<dart.RecordImpl>('!', '#', record);
  var recipeBuffer = StringBuffer('+');
  var shape = JS<dart.Shape>('!', '#[#]', recordObj, dart.shapeProperty);
  var values = JS<JSArray>('!', '#[#]', recordObj, dart.valuesProperty);
  var named = shape.named;
  if (named != null) recipeBuffer.writeAll(named, ',');
  recipeBuffer.write('(');
  var elementCount = values.length;
  recipeBuffer.writeAll([for (var i = 1; i <= elementCount; i++) i], ',');
  recipeBuffer.write(')');

  return rti.evaluateRtiForRecord(recipeBuffer.toString(), values);
}

/// A marker interface for classes with 'trustworthy' implementations of `get
/// runtimeType`.
///
/// Generally, overrides of `get runtimeType` are not used in displaying the
/// types of irritants in TypeErrors or computing the structural `runtimeType`
/// of records. Instead the Rti (aka 'true') type is used.
///
/// The 'true' type is sometimes confusing because it shows implementation
/// details, e.g. the true type of `42` is `JSInt` and `2.1` is `JSNumNotInt`.
///
/// For a limited number of implementation classes we tell a 'white lie' that
/// the value is of another type, e.g. that `42` is an `int` and `2.1` is
/// `double`. This is achieved by overriding `get runtimeType` to return the
/// desired type, and marking the implementation class type with `implements
/// [TrustedGetRuntimeType]`.
///
/// [TrustedGetRuntimeType] is not exposed outside the `dart:` libraries so
/// users cannot tell lies.
///
/// The `Type` returned by a trusted `get runtimeType` must be an instance of
/// the system `Type`, which is guaranteed by using a type literal. Type
/// literals can be generic and dependent on type variables, e.g. `List<E>`.
///
/// Care needs to taken to ensure that the runtime does not get caught telling
/// lies. Generally, a class's `runtimeType` lies by returning an abstract
/// supertype of the class.  Since both the the marker interface and `get
/// runtimeType` are inherited, there should be no way in which a user can
/// extend the class or implement interface of the class.
// TODO(48585): Move this class back to the dart:_rti library when old DDC
// runtime type system has been removed.
abstract class TrustedGetRuntimeType {}

/// Wraps the JavaScript `Object.getPrototypeOf()` method returning the
/// `__proto__` of [obj].
///
/// This method is equivalent to:
///
///    JS<Object?>('', 'Object.getPrototypeOf(#)', obj);
///
/// but the code is generated by the compiler directly (a low-tech way of
/// inlining).
///
/// This helper should always be used in place of `JS('', '#.__proto__', obj)`
/// to avoid prototype pollution issues.
/// See: https://github.com/tc39/proposal-symbol-proto
external Object? jsObjectGetPrototypeOf(@notNull Object obj);

/// Wraps the JavaScript `Object.setPrototypeOf()` method setting the
/// `__proto__` of [obj] to [prototype] and returning [obj].
///
/// This method is equivalent to:
///
///    JS<Object>('!', 'Object.setPrototypeOf(#, #)', obj, prototype);
///
/// but the code is generated by the compiler directly (a low-tech way of
/// inlining).
///
/// This helper should always be used in place of
/// `JS('', '#.__proto__ = #', obj, prototype)` to avoid prototype
/// pollution issues.
/// See: https://github.com/tc39/proposal-symbol-proto
@notNull
external Object jsObjectSetPrototypeOf(@notNull Object obj, Object? prototype);

/// The global context that "static interop" members use for namespaces.
///
/// For example, an interop library with no library-level `@JS` annotation and a
/// top-level external member named or renamed to 'foo' will lower a call to
/// that member as `<staticInteropGlobalContext>.foo`. The same applies for any
/// external constructors or class/extension type static members.
///
/// If the library does have a `@JS` annotation with a value, the call then gets
/// lowered to `<staticInteropGlobalContext>.<libraryJSAnnotationValue>.foo`.
///
/// To see which members get lowered with this, see the transformation in
/// `pkg/_js_interop_checks/lib/src/js_util_optimizer.dart`.
///
/// This should match the global context that non-static interop members use.
/// Note that this is external. We could implement it here, but DDC will not
/// inline the call so this will be an extra level of indirection. DDC manually
/// inlines this method in the compiler instead.
external Object get staticInteropGlobalContext;

/// Return a fresh object literal.
T createObjectLiteral<T>() => JS('PlainJavaScriptObject', '{}');
