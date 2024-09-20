// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._runtime;

// We need to set these properties while the sdk is only partially initialized
// so we cannot use regular Dart fields.
// The default values for these properties are set when the global_ final field
// in runtime.dart is initialized.

argumentError(value) {
  throw ArgumentError.value(value);
}

throwUnimplementedError(String message) {
  throw UnimplementedError(message);
}

throwDeferredIsLoadedError(
    @notNull String enclosingLibrary, @notNull String importPrefix) {
  throw DeferredNotLoadedError(enclosingLibrary, importPrefix);
}

// TODO(nshahan) Cleanup embedded strings and extract file location at runtime
// from the stacktrace.
assertFailed(String? message,
    [String? fileUri, int? line, int? column, String? conditionSource]) {
  throw AssertionErrorImpl(message, fileUri, line, column, conditionSource);
}

/// Throws if [isModuleSound] does not match the null safety mode of this SDK.
///
/// The call to this method is inserted into every module at compile time when
/// the compile time null safety mode for the module is known.
void _checkModuleNullSafetyMode(@notNull bool isModuleSound) {
  if (isModuleSound != JS_GET_FLAG('SOUND_NULL_SAFETY')) {
    var sdkMode = JS_GET_FLAG('SOUND_NULL_SAFETY') ? 'sound' : 'unsound';
    var moduleMode = isModuleSound ? 'sound' : 'unsound';

    throw AssertionError('The null safety mode of the Dart SDK module '
        '($sdkMode) does not match the null safety mode of this module '
        '($moduleMode).');
  }
}

final _nullFailedSet = JS('!', 'new Set()');

String _nullFailedMessage(variableName) =>
    'A null value was passed into a non-nullable parameter: $variableName.';

// Run-time null safety assertion per:
// https://github.com/dart-lang/language/blob/master/accepted/2.12/nnbd/feature-specification.md#automatic-debug-assertion-insertion
nullFailed(String? fileUri, int? line, int? column, String? variable) {
  if (_nonNullAsserts) {
    throw AssertionErrorImpl(_nullFailedMessage(variable), fileUri, line,
        column, '$variable != null');
  }
  var key = '$fileUri:$line:$column';
  if (!JS('!', '#.has(#)', _nullFailedSet, key)) {
    JS('', '#.add(#)', _nullFailedSet, key);
    _nullWarn(_nullFailedMessage(variable));
  }
}

throwLateInitializationError(String name) {
  throw internal.LateError(name);
}

throwCyclicInitializationError([String? field]) {
  throw _CyclicInitializationError(field);
}

/// Error thrown when a lazily initialized variable cannot be initialized.
///
/// Cyclic dependencies are no longer detected at runtime in null safe code.
/// Such code will fail in other ways instead,
/// possibly with a [StackOverflowError].
///
/// Will be removed when support for non-null-safe code is discontinued.
@Deprecated("Remove when no longer supporting non-null-safe code.")
class _CyclicInitializationError extends Error {
  final String? variableName;
  _CyclicInitializationError([this.variableName]);
  String toString() {
    var variableName = this.variableName;
    return variableName == null
        ? "Reading static variable during its initialization"
        : "Reading static variable '$variableName' during its initialization";
  }
}

throwNullValueError() {
  // TODO(vsm): Per spec, we should throw an NSM here.  Technically, we ought
  // to thread through method info, but that uglifies the code and can't
  // actually be queried ... it only affects how the error is printed.
  throw NoSuchMethodError.withInvocation(
    null,
    Invocation.method(Symbol('<Unexpected Null Value>'), null, null),
  );
}

castError(obj, expectedType) {
  var actualType = getReifiedType(obj);
  var message = _castErrorMessage(actualType, expectedType);
  throw TypeErrorImpl(message);
}

String _castErrorMessage(from, to) {
  // If both types are generic classes, see if we can infer generic type
  // arguments for `from` that would allow the subtype relation to work.
  // TODO(#40326) Fix suggested type or remove this code if no longer needed.
  // var fromClass = getGenericClass(from);
  // if (fromClass != null) {
  //   var fromTypeFormals = getGenericTypeFormals(fromClass);
  //   var fromType = instantiateClass(fromClass, fromTypeFormals);
  //   var inferrer = _TypeInferrer(fromTypeFormals);
  //   if (inferrer.trySubtypeMatch(fromType, to)) {
  //     var inferredTypes = inferrer.getInferredTypes();
  //     if (inferredTypes != null) {
  //       var inferred = instantiateClass(fromClass, inferredTypes);
  //       return "Type '${typeName(from)}' should be '${typeName(inferred)}' "
  //           "to implement expected type '${typeName(to)}'.";
  //     }
  //   }
  // }
  var fromName = "'${typeName(from)}'";
  var toName = "'${typeName(to)}'";
  if (fromName == toName) {
    fromName += ' (in ${getLibraryUri(from)})';
    toName += ' (in ${getLibraryUri(to)})';
  }
  return 'Expected a value of type $toName, but got one of type $fromName';
}

/// The symbol that references the thrown Dart Object (typically but not
/// necessarily an [Error] or [Exception]), used by the [exception] function.
final Object _thrownValue = JS('', 'Symbol("_thrownValue")');

/// For a Dart [Error], this provides access to the JS Error object that
/// contains the stack trace if the error was thrown.
final Object _jsError = JS('', 'Symbol("_jsError")');

/// Gets the thrown Dart Object from an [error] caught by a JS catch.
///
/// If the throw originated in Dart, the result will typically be an [Error]
/// or [Exception], but it could be any Dart object.
///
/// If [error] looks like a stack overflow from JavaScript then a Dart
/// [StackOverflowError] is returned.
///
/// Otherwise, if the throw originated in JavaScript, then there is not a
/// corresponding Dart value, so we just return the [error] object.
Object? getThrown(Object? error) {
  if (error != null) {
    // Get the Dart thrown value, if any.
    var value = JS('', '#[#]', error, _thrownValue);
    if (value != null) return value;
    if (_isStackOverflowError(error)) {
      var dartStackOverflowError = StackOverflowError();
      JS('', '#[#] = #', error, _thrownValue, dartStackOverflowError);
      return dartStackOverflowError;
    }
  }
  // Otherwise return the original object.
  return error;
}

/// Returns `true` when [error] appears to be a stack overflow error from
/// the browser.
bool _isStackOverflowError(Object error) {
  var message = JS('', '#.message', error);
  if (message is! String) return false;
  if (JS<bool>(
          '!',
          'typeof RangeError == "function" && # instanceof RangeError',
          error) &&
      message.contains('call stack')) {
    return true;
  }
  // Firefox stack overflow identification.
  if (JS<bool>(
          '!',
          'typeof InternalError == "function" && # instanceof InternalError',
          error) &&
      message.contains('too much recursion')) {
    return true;
  }
  return false;
}

final _stackTrace = JS('', 'Symbol("_stackTrace")');

/// Returns the stack trace from an [error] caught by a JS catch.
///
/// If the throw originated in Dart, we should always have JS Error
/// (see [throw_]) so we can create a Dart [StackTrace] from that (or return a
/// previously created instance).
///
/// If the throw originated in JavaScript and was an `Error`, then we can get
/// the corresponding stack trace the same way we do for Dart throws. If the
/// throw object was not an Error, then we don't have a JS trace, so we create
/// one here.
StackTrace stackTrace(Object? error) {
  if (JS<bool>('!', '!(# instanceof Error)', error)) {
    // We caught something that isn't a JS Error.
    //
    // We should only hit this path when a non-Error was thrown from JS. In
    // case, there is no stack trace available, so create one here.
    return _StackTrace.missing(error);
  }

  // If we've already created the Dart stack trace object, return it.
  StackTrace? trace = JS('', '#[#]', error, _stackTrace);
  if (trace != null) return trace;

  // Otherwise create the Dart stack trace (by parsing the JS stack), and
  // cache it so we don't repeat the parsing/allocation.
  return JS('', '#[#] = #', error, _stackTrace, _StackTrace(error));
}

StackTrace? stackTraceForError(Error error) {
  var jsError = JS('', '#[#]', error, _jsError);
  if (jsError == null) return null;
  return stackTrace(jsError);
}

/// Implements `rethrow` of [error], allowing rethrow in an expression context.
///
/// Note: [error] must be the raw JS error caught in the JS catch, not the
/// unwrapped value returned by [getThrown].
@JSExportName('rethrow')
void rethrow_(Object error) {
  JS('', 'throw #', error);
}

/// Subclass of JS `Error` that wraps a thrown Dart object, and evaluates the
/// message lazily by calling `toString()` on the wrapped Dart object.
///
/// Also creates a pointer from the thrown Dart object to the JS Error
/// (via [_jsError]). This is used to implement [Error.stackTrace], but also
/// provides a way to recover the stack trace if we lose track of it.
/// [Error] requires preserving the original stack trace if an error is
/// rethrown, so we only update the pointer if it wasn't already set.
///
/// TODO(jmesserly): Dart Errors should simply be JS Errors.
final Object DartError = JS(
    '!',
    '''class DartError extends Error {
      constructor(error) {
        super();
        if (error == null) error = #;
        this[#] = error;
        if (error != null && typeof error == "object" && error[#] == null) {
          error[#] = this;
        }
      }
      get message() {
        return #(this[#]);
      }
    }''',
    TypeErrorImpl('Throw of null.'),
    _thrownValue,
    _jsError,
    _jsError,
    _toString,
    _thrownValue);

/// Subclass of [DartError] for cases where we're rethrowing with a different,
/// original Dart StackTrace object.
///
/// This includes the original stack trace in the JS Error message so it doesn't
/// get lost if the exception reaches JS.
final Object RethrownDartError = JS(
    '!',
    '''class RethrownDartError extends # {
      constructor(error, stackTrace) {
        super(error);
        this[#] = stackTrace;
      }
      get message() {
        return super.message + "\\n    " + #(this[#]) + "\\n";
      }
    }''',
    DartError,
    _stackTrace,
    _toString,
    _stackTrace);

/// Implements `throw` of [exception], allowing for throw in an expression
/// context, and capturing the current stack trace.
@JSExportName('throw')
void throw_(Object? exception) {
  /// Wrap the object so we capture a new stack trace, and so it will print
  /// nicely from JS, as if it were a normal JS error.
  JS('', 'throw new #(#)', DartError, exception);
}

/// Returns a JS error for throwing the Dart [exception] Object and using the
/// provided stack [trace].
///
/// This is used by dart:async to rethrow unhandled errors in [Zone]s, and by
/// `async`/`async*` to rethrow errors from Futures/Streams into the generator
/// (so a try/catch in there can catch it).
///
/// If the exception and trace originated from the same Dart throw, then we can
/// simply return the original JS Error. Otherwise, we have to create a new JS
/// Error. The new error will have the correct Dart trace, but it will not have
/// the correct JS stack trace (visible if JavaScript ends up handling it). To
/// fix that, we use [RethrownDartError] to preserve the Dart trace and make
/// sure it gets displayed in the JS error message.
///
/// If the stack trace is null, this will preserve the original stack trace
/// on the exception, if available, otherwise it will capture the current stack
/// trace.
Object? createErrorWithStack(Object exception, StackTrace? trace) {
  if (trace == null) {
    var error = JS('', '#[#]', exception, _jsError);
    return error != null ? error : JS('', 'new #(#)', DartError, exception);
  }
  if (trace is _StackTrace) {
    /// Optimization: if this stack trace and exception already have a matching
    /// Error, we can just rethrow it.
    var originalError = trace._jsError;
    if (identical(exception, getThrown(originalError))) {
      return originalError;
    }
  }
  return JS('', 'new #(#, #)', RethrownDartError, exception, trace);
}

// This is a utility function: it is only intended to be called from dev
// tools.
void stackPrint(Object error) {
  JS('', 'console.log(#.stack ? #.stack : "No stack trace for: " + #)', error,
      error, error);
}

class _StackTrace implements StackTrace {
  final Object? _jsError;
  final Object? _jsObjectMissingTrace;
  String? _trace;

  _StackTrace(this._jsError) : _jsObjectMissingTrace = null;

  _StackTrace.missing(Object? caughtObj)
      : _jsObjectMissingTrace = caughtObj != null ? caughtObj : 'null',
        _jsError = JS('', 'Error()');

  String toString() {
    if (_trace != null) return _trace!;

    var e = _jsError;
    String trace = '';
    if (e != null && JS<bool>('!', 'typeof # === "object"', e)) {
      trace = e is NativeError ? e.dartStack() : JS<String>('', '#.stack', e);
      var mapper = stackTraceMapper;
      if (trace != null && mapper != null) {
        trace = mapper(trace);
      }
    }
    if (trace.isEmpty || _jsObjectMissingTrace != null) {
      String jsToString;
      try {
        jsToString = JS('', '"" + #', _jsObjectMissingTrace);
      } catch (_) {
        jsToString = '<error converting JS object to string>';
      }
      trace = 'Non-error `$jsToString` thrown by JS does not have stack trace.'
          '\nCaught in Dart at:\n\n$trace';
    }
    return _trace = trace;
  }
}
