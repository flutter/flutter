import 'dart:async';

import 'package:flutter/widgets.dart';

import 'provider.dart';

/// A callback used to build a valid value from an error.
///
/// See also:
///
///   * [StreamProvider] and [FutureProvider], which both uses [ErrorBuilder] to
///     handle respectively `Stream.catchError` and [Future.catch].
typedef ErrorBuilder<T> = T Function(BuildContext context, Object? error);

DeferredStartListening<Stream<T>?, T> _streamStartListening<T>({
  required T initialData,
  ErrorBuilder<T>? catchError,
}) {
  return (e, setState, controller, __) {
    if (!e.hasValue) {
      setState(initialData);
    }
    if (controller == null) {
      return () {};
    }
    final sub = controller.listen(
      setState,
      onError: (Object? error) {
        if (catchError != null) {
          setState(catchError(e, error));
        } else {
          FlutterError.reportError(
            FlutterErrorDetails(
              library: 'provider',
              exception: FlutterError('''
An exception was throw by ${controller.runtimeType} listened by
StreamProvider<$T>, but no `catchError` was provided.

Exception:
$error
'''),
            ),
          );
        }
      },
    );

    return sub.cancel;
  };
}

/// Listens to a [Stream] and exposes its content to `child` and descendants.
///
/// Its main use-case is to provide to a large number of a widget the content
/// of a [Stream], without caring about reacting to events.
/// A typical example would be to expose the battery level, or a Firebase query.
///
/// Trying to use [Stream] to replace [ChangeNotifier] is outside of the scope
/// of this class.
///
/// It is considered an error to pass a stream that can emit errors without
/// providing a `catchError` method.
///
/// `initialData` determines the value exposed until the [Stream] emits a value.
///
/// By default, [StreamProvider] considers that the [Stream] listened uses
/// immutable data. As such, it will not rebuild dependents if the previous and
/// the new value are `==`.
/// To change this behavior, pass a custom `updateShouldNotify`.
///
/// See also:
///
///   * [Stream], which is listened by [StreamProvider].
///   * [StreamController], to create a [Stream].
class StreamProvider<T> extends DeferredInheritedProvider<Stream<T>?, T> {
  /// Creates a [Stream] using `create` and subscribes to it.
  ///
  /// The parameter `create` must not be `null`.
  StreamProvider({
    Key? key,
    required Create<Stream<T>?> create,
    required T initialData,
    ErrorBuilder<T>? catchError,
    UpdateShouldNotify<T>? updateShouldNotify,
    bool? lazy,
    TransitionBuilder? builder,
    Widget? child,
  }) : super(
          key: key,
          lazy: lazy,
          builder: builder,
          create: create,
          updateShouldNotify: updateShouldNotify,
          startListening: _streamStartListening(
            catchError: catchError,
            initialData: initialData,
          ),
          child: child,
        );

  /// Listens to `value` and expose it to all of [StreamProvider] descendants.
  StreamProvider.value({
    Key? key,
    required Stream<T>? value,
    required T initialData,
    ErrorBuilder<T>? catchError,
    UpdateShouldNotify<T>? updateShouldNotify,
    bool? lazy,
    TransitionBuilder? builder,
    Widget? child,
  }) : super.value(
          key: key,
          lazy: lazy,
          builder: builder,
          value: value,
          updateShouldNotify: updateShouldNotify,
          startListening: _streamStartListening(
            catchError: catchError,
            initialData: initialData,
          ),
          child: child,
        );
}

DeferredStartListening<Future<T>?, T> _futureStartListening<T>({
  required T initialData,
  ErrorBuilder<T>? catchError,
}) {
  // ignore: void_checks, false positive
  return (e, setState, controller, __) {
    if (!e.hasValue) {
      setState(initialData);
    }

    var canceled = false;
    controller?.then(
      (value) {
        if (canceled) {
          return;
        }
        setState(value);
      },
      onError: (Object? error) {
        if (canceled) {
          return;
        }
        if (catchError != null) {
          setState(catchError(e, error));
        } else {
          FlutterError.reportError(
            FlutterErrorDetails(
              library: 'provider',
              exception: FlutterError('''
An exception was throw by ${controller.runtimeType} listened by
FutureProvider<$T>, but no `catchError` was provided.

Exception:
$error
'''),
            ),
          );
        }
      },
    );

    return () => canceled = true;
  };
}

/// Listens to a [Future] and exposes its result to `child` and its descendants.
///
/// It is considered an error to pass a future that can emit errors without
/// providing a `catchError` method.
///
/// {@macro provider.updateshouldnotify}
///
/// See also:
///
///   * [Future], which is listened by [FutureProvider].
class FutureProvider<T> extends DeferredInheritedProvider<Future<T>?, T> {
  /// Creates a [Future] from `create` and subscribes to it.
  ///
  /// `create` must not be `null`.
  FutureProvider({
    Key? key,
    required Create<Future<T>?> create,
    required T initialData,
    ErrorBuilder<T>? catchError,
    UpdateShouldNotify<T>? updateShouldNotify,
    bool? lazy,
    TransitionBuilder? builder,
    Widget? child,
  }) : super(
          key: key,
          lazy: lazy,
          builder: builder,
          create: create,
          updateShouldNotify: updateShouldNotify,
          startListening: _futureStartListening(
            catchError: catchError,
            initialData: initialData,
          ),
          child: child,
        );

  /// Listens to `value` and expose it to all of [FutureProvider] descendants.
  FutureProvider.value({
    Key? key,
    required Future<T>? value,
    required T initialData,
    ErrorBuilder<T>? catchError,
    UpdateShouldNotify<T>? updateShouldNotify,
    TransitionBuilder? builder,
    Widget? child,
  }) : super.value(
          key: key,
          builder: builder,
          lazy: false,
          value: value,
          updateShouldNotify: updateShouldNotify,
          startListening: _futureStartListening(
            catchError: catchError,
            initialData: initialData,
          ),
          child: child,
        );
}
