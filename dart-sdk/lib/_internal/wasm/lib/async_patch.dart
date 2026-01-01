import 'dart:_internal' show _AsyncCompleter, patch, exportWasmFunction;

import 'dart:_js_helper' show JS;

import 'dart:_wasm';

part 'timer_patch.dart';

// Modular kernel transformer will make calls to this method be re-directed to
// call dart:core:Error._trySetStackTrace instead.
@patch
external void _trySetStackTrace(Object error, StackTrace stackTrace);

typedef _AsyncResumeFun =
    WasmFunction<
      void Function(
        _AsyncSuspendState,
        // Value of the last `await`
        Object?,
        // If the last `await` threw an error, the error value
        Object?,
        // If the last `await` threw an error, the stack trace
        StackTrace?,
      )
    >;

@pragma("wasm:entry-point")
class _AsyncSuspendState {
  // The inner function.
  //
  // Note: this function never throws. Any uncaught exceptions are passed to
  // `_completer.completeError`.
  @pragma("wasm:entry-point")
  final _AsyncResumeFun _resume;

  // Context containing the local variables of the function.
  @pragma("wasm:entry-point")
  WasmStructRef? _context;

  // CFG target index for the next resumption.
  @pragma("wasm:entry-point")
  WasmI32 _targetIndex;

  // The future that will be completed.
  @pragma("wasm:entry-point")
  final _Future _future;

  // When a called function throws this stores the thrown exception. Used when
  // performing type tests in catch blocks.
  @pragma("wasm:entry-point")
  Object? _currentException;

  // When a called function throws this stores the stack trace.
  @pragma("wasm:entry-point")
  StackTrace? _currentExceptionStackTrace;

  // When running finalizers and the continuation is "return", the value to
  // return after the last finalizer.
  //
  // Used in finalizer blocks.
  @pragma("wasm:entry-point")
  Object? _currentReturnValue;

  @pragma("wasm:entry-point")
  _AsyncSuspendState(this._resume, this._context, this._future)
    : _targetIndex = WasmI32.fromInt(0),
      _currentException = null,
      _currentExceptionStackTrace = null,
      _currentReturnValue = null;

  @pragma("wasm:entry-point")
  void _complete(FutureOr value) {
    _future._asyncComplete(value == null ? value as dynamic : value);
  }

  @pragma("wasm:entry-point")
  void _completeError(Object error, StackTrace stackTrace) {
    _future._asyncCompleteError(error, stackTrace);
  }

  @pragma("wasm:entry-point")
  void _completeErrorWithCurrentStack(Object error) {
    _future._asyncCompleteError(error, StackTrace.current);
  }
}

// Note: [_AsyncCompleter] is taken as an argument to be able to pass the type
// parameter to [_AsyncCompleter] without having to add a type parameter to
// [_AsyncSuspendState]. Completer type parameter is passed to the completer's
// future, which the outer function returns to the caller.
@pragma("wasm:entry-point")
_AsyncSuspendState _newAsyncSuspendState(
  _AsyncResumeFun resume,
  WasmStructRef? context,
  _Future future,
) => _AsyncSuspendState(resume, context, future);

@pragma("wasm:entry-point")
_Future<T> _makeFuture<T>() => _Future<T>();

@pragma("wasm:entry-point")
void _awaitHelper(_AsyncSuspendState suspendState, Future operand) {
  operand.then(
    (value) {
      suspendState._resume.call(suspendState, value, null, null);
    },
    onError: (exception, stackTrace) {
      suspendState._resume.call(suspendState, null, exception, stackTrace);
    },
  );
}

@pragma("wasm:entry-point")
void _awaitHelperWithTypeCheck<T>(
  _AsyncSuspendState suspendState,
  Object? operand,
) {
  if (operand is! Future<T>) {
    return scheduleMicrotask(
      () => suspendState._resume.call(suspendState, operand, null, null),
    );
  }
  operand.then(
    (Object? value) {
      suspendState._resume.call(suspendState, value, null, null);
    },
    onError: (exception, stackTrace) {
      suspendState._resume.call(suspendState, null, exception, stackTrace);
    },
  );
}
