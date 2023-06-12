part of 'provider.dart';

/// A callback used to handle the subscription of `controller`.
///
/// It is expected to start the listening process and return a callback
/// that will later be used to stop that listening.
///
/// See also:
///
/// - [DeferredInheritedProvider]
/// - [StartListening], a simpler version of this typedef.
typedef DeferredStartListening<T, R> = VoidCallback Function(
  InheritedContext<R?> context,
  void Function(R value) setState,
  T controller,
  R? value,
);

/// An [InheritedProvider] where the object listened is _not_ the object
/// emitted.
///
/// For example, for a stream provider, we'll want to listen to `Stream<T>`,
/// but expose `T` not the [Stream].
///
/// See also:
///
///  - [InheritedProvider], a variant of this object where the provider object and
///    the created object are the same.
class DeferredInheritedProvider<T, R> extends InheritedProvider<R> {
  /// Lazily create an object automatically disposed when
  /// [DeferredInheritedProvider] is removed from the tree.
  ///
  /// The object create will be listened using `startListening`, and its content
  /// will be exposed to `child` and its descendants.
  DeferredInheritedProvider({
    Key? key,
    required Create<T> create,
    Dispose<T>? dispose,
    required DeferredStartListening<T, R> startListening,
    UpdateShouldNotify<R>? updateShouldNotify,
    bool? lazy,
    TransitionBuilder? builder,
    Widget? child,
  }) : super._constructor(
          key: key,
          child: child,
          lazy: lazy,
          builder: builder,
          delegate: _CreateDeferredInheritedProvider(
            create: create,
            dispose: dispose,
            updateShouldNotify: updateShouldNotify,
            startListening: startListening,
          ),
        );

  /// Listens to `value` and expose its content to `child` and its descendants.
  DeferredInheritedProvider.value({
    Key? key,
    required T value,
    required DeferredStartListening<T, R> startListening,
    UpdateShouldNotify<R>? updateShouldNotify,
    bool? lazy,
    TransitionBuilder? builder,
    Widget? child,
  }) : super._constructor(
          key: key,
          lazy: lazy,
          builder: builder,
          delegate: _ValueDeferredInheritedProvider<T, R>(
            value,
            updateShouldNotify,
            startListening,
          ),
          child: child,
        );
}

abstract class _DeferredDelegate<T, R> extends _Delegate<R> {
  _DeferredDelegate(this.updateShouldNotify, this.startListening);

  final UpdateShouldNotify<R>? updateShouldNotify;
  final DeferredStartListening<T, R> startListening;

  @override
  _DeferredDelegateState<T, R, _DeferredDelegate<T, R>> createState();
}

abstract class _DeferredDelegateState<T, R, W extends _DeferredDelegate<T, R>>
    extends _DelegateState<R, W> {
  VoidCallback? _removeListener;

  T get controller;

  R? _value;

  @override
  R get value {
    // setState should be no-op inside startListening, as it's lazy-loaded
    // otherwise Flutter will throw an exception for no reason.
    element!._isNotifyDependentsEnabled = false;
    _removeListener ??= delegate.startListening(
      element!,
      setState,
      controller,
      _value,
    );
    element!._isNotifyDependentsEnabled = true;
    assert(element!.hasValue, '''
The callback "startListening" was called, but it left DeferredInhertitedProviderElement<$T, $R>
in an uninitialized state.

It is necessary for "startListening" to call "setState" at least once the very
first time "value" is requested.

To fix, consider:

DeferredInheritedProvider(
  ...,
  startListening: (element, setState, controller, value) {
    if (!element.hasValue) {
      setState(myInitialValue); // TODO replace myInitialValue with your own
    }
    ...
  }
)
    ''');
    assert(_removeListener != null);
    return _value as R;
  }

  @override
  void dispose() {
    super.dispose();
    _removeListener?.call();
  }

  bool get isLoaded => _removeListener != null;

  bool _hasValue = false;

  @override
  bool get hasValue => _hasValue;

  void setState(R value) {
    if (_hasValue) {
      final shouldNotify = delegate.updateShouldNotify != null
          ? delegate.updateShouldNotify!(_value as R, value)
          : _value != value;
      if (shouldNotify) {
        element!.markNeedsNotifyDependents();
      }
    }
    _hasValue = true;
    _value = value;
  }
}

class _CreateDeferredInheritedProvider<T, R> extends _DeferredDelegate<T, R> {
  _CreateDeferredInheritedProvider({
    required this.create,
    this.dispose,
    UpdateShouldNotify<R>? updateShouldNotify,
    required DeferredStartListening<T, R> startListening,
  }) : super(updateShouldNotify, startListening);

  final Create<T> create;
  final Dispose<T>? dispose;

  @override
  _CreateDeferredInheritedProviderElement<T, R> createState() {
    return _CreateDeferredInheritedProviderElement<T, R>();
  }
}

class _CreateDeferredInheritedProviderElement<T, R>
    extends _DeferredDelegateState<T, R,
        _CreateDeferredInheritedProvider<T, R>> {
  bool _didBuild = false;

  T? _controller;

  @override
  T get controller {
    if (!_didBuild) {
      assert(debugSetInheritedLock(true));
      bool? _debugPreviousIsInInheritedProviderCreate;
      bool? _debugPreviousIsInInheritedProviderUpdate;

      assert(() {
        _debugPreviousIsInInheritedProviderCreate =
            debugIsInInheritedProviderCreate;
        _debugPreviousIsInInheritedProviderUpdate =
            debugIsInInheritedProviderUpdate;
        return true;
      }());

      try {
        assert(() {
          debugIsInInheritedProviderCreate = true;
          debugIsInInheritedProviderUpdate = false;
          return true;
        }());
        _controller = delegate.create(element!);
      } finally {
        assert(() {
          debugIsInInheritedProviderCreate =
              _debugPreviousIsInInheritedProviderCreate!;
          debugIsInInheritedProviderUpdate =
              _debugPreviousIsInInheritedProviderUpdate!;
          return true;
        }());
      }
      _didBuild = true;
    }
    return _controller as T;
  }

  @override
  void dispose() {
    super.dispose();
    if (_didBuild) {
      delegate.dispose?.call(element!, _controller as T);
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    if (isLoaded) {
      properties
        ..add(DiagnosticsProperty('controller', controller))
        ..add(DiagnosticsProperty('value', value));
    } else {
      properties
        ..add(
          FlagProperty(
            'controller',
            value: true,
            showName: true,
            ifTrue: '<not yet loaded>',
          ),
        )
        ..add(
          FlagProperty(
            'value',
            value: true,
            showName: true,
            ifTrue: '<not yet loaded>',
          ),
        );
    }
  }
}

class _ValueDeferredInheritedProvider<T, R> extends _DeferredDelegate<T, R> {
  _ValueDeferredInheritedProvider(
    this.value,
    UpdateShouldNotify<R>? updateShouldNotify,
    DeferredStartListening<T, R> startListening,
  ) : super(updateShouldNotify, startListening);

  final T value;

  @override
  _ValueDeferredInheritedProviderState<T, R> createState() {
    return _ValueDeferredInheritedProviderState();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('controller', value));
  }
}

class _ValueDeferredInheritedProviderState<T, R> extends _DeferredDelegateState<
    T, R, _ValueDeferredInheritedProvider<T, R>> {
  @override
  bool willUpdateDelegate(_ValueDeferredInheritedProvider<T, R> oldDelegate) {
    if (delegate.value != oldDelegate.value) {
      if (_removeListener != null) {
        _removeListener!();
        _removeListener = null;
      }
      return true;
    }
    return false;
  }

  @override
  T get controller => delegate.value;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    if (_removeListener != null) {
      properties.add(DiagnosticsProperty('value', value));
    } else {
      properties.add(
        FlagProperty(
          'value',
          value: true,
          showName: true,
          ifTrue: '<not yet loaded>',
        ),
      );
    }
  }
}
