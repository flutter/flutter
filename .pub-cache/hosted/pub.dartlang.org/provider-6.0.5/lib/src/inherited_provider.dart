part of 'provider.dart';

/// A function that returns true when the update from [previous] to [current]
/// should notify listeners, if any.
///
/// See also:
///
///   * [InheritedWidget.updateShouldNotify]
typedef UpdateShouldNotify<T> = bool Function(T previous, T current);

/// A function that creates an object of type [T].
///
/// See also:
///
///  * [Dispose], to free the resources associated to the value created.
typedef Create<T> = T Function(BuildContext context);

/// A function that disposes an object of type [T].
///
/// See also:
///
///  * [Create], to create a value that will later be disposed of.
typedef Dispose<T> = void Function(BuildContext context, T value);

/// A callback used to start the listening of an object and return a function
/// that cancels the subscription.
///
/// It is called the first time the value is obtained (through
/// [InheritedContext.value]). And the returned callback will be called
/// when [InheritedProvider] is unmounted or when the it is rebuilt with a new
/// value.
///
/// See also:
///
/// - [InheritedProvider]
/// - [DeferredStartListening], a variant of this typedef for more advanced
///   listening.
typedef StartListening<T> = VoidCallback Function(
  InheritedContext<T?> element,
  T value,
);

/// A generic implementation of an [InheritedWidget].
///
/// Any descendant of this widget can obtain `value` using [Provider.of].
///
/// Do not use this class directly unless you are creating a custom "Provider".
/// Instead use [Provider] class, which wraps [InheritedProvider].
///
/// See also:
///
///  - [DeferredInheritedProvider], a variant of this object where the provided
///    object and the created object are two different entity.
class InheritedProvider<T> extends SingleChildStatelessWidget {
  /// Creates a value, then expose it to its descendants.
  ///
  /// The value will be disposed of when [InheritedProvider] is removed from
  /// the widget tree.
  InheritedProvider({
    Key? key,
    Create<T>? create,
    T Function(BuildContext context, T? value)? update,
    UpdateShouldNotify<T>? updateShouldNotify,
    void Function(T value)? debugCheckInvalidValueType,
    StartListening<T>? startListening,
    Dispose<T>? dispose,
    this.builder,
    bool? lazy,
    Widget? child,
  })  : _lazy = lazy,
        _delegate = _CreateInheritedProvider(
          create: create,
          update: update,
          updateShouldNotify: updateShouldNotify,
          debugCheckInvalidValueType: debugCheckInvalidValueType,
          startListening: startListening,
          dispose: dispose,
        ),
        super(key: key, child: child);

  /// Expose to its descendants an existing value,
  InheritedProvider.value({
    Key? key,
    required T value,
    UpdateShouldNotify<T>? updateShouldNotify,
    StartListening<T>? startListening,
    bool? lazy,
    this.builder,
    Widget? child,
  })  : _lazy = lazy,
        _delegate = _ValueInheritedProvider(
          value: value,
          updateShouldNotify: updateShouldNotify,
          startListening: startListening,
        ),
        super(key: key, child: child);

  InheritedProvider._constructor({
    Key? key,
    required _Delegate<T> delegate,
    bool? lazy,
    this.builder,
    Widget? child,
  })  : _lazy = lazy,
        _delegate = delegate,
        super(key: key, child: child);

  final _Delegate<T> _delegate;
  final bool? _lazy;

  /// Syntax sugar for obtaining a [BuildContext] that can read the provider
  /// created.
  ///
  /// This code:
  ///
  /// ```dart
  /// Provider<int>(
  ///   create: (context) => 42,
  ///   builder: (context, child) {
  ///     final value = context.watch<int>();
  ///     return Text('$value');
  ///   }
  /// )
  /// ```
  ///
  /// is strictly equivalent to:
  ///
  /// ```dart
  /// Provider<int>(
  ///   create: (context) => 42,
  ///   child: Builder(
  ///     builder: (context) {
  ///       final value = context.watch<int>();
  ///       return Text('$value');
  ///     },
  ///   ),
  /// )
  /// ```
  ///
  /// For an explanation on the `child` parameter that `builder` receives,
  /// see the "Performance optimizations" section of [AnimatedBuilder].
  final TransitionBuilder? builder;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    _delegate.debugFillProperties(properties);
  }

  @override
  _InheritedProviderElement<T> createElement() {
    return _InheritedProviderElement<T>(this);
  }

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    assert(
      builder != null || child != null,
      '$runtimeType used outside of MultiProvider must specify a child',
    );
    return _InheritedProviderScope<T?>(
      owner: this,
      // ignore: no_runtimetype_tostring
      debugType: kDebugMode ? '$runtimeType' : '',
      child: builder != null
          ? Builder(
              builder: (context) => builder!(context, child),
            )
          : child!,
    );
  }
}

class _InheritedProviderElement<T> extends SingleChildStatelessElement {
  _InheritedProviderElement(InheritedProvider<T> widget) : super(widget);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    visitChildren((e) => e.debugFillProperties(properties));
  }
}

bool _debugIsSelecting = false;

/// Adds a `select` method on [BuildContext].
extension SelectContext on BuildContext {
  /// Watch a value of type [T] exposed from a provider, and mark this widget for rebuild
  /// on changes of that value.
  ///
  /// If [T] is nullable and no matching providers are found, [watch] will
  /// return `null`. Otherwise if [T] is non-nullable, will throw [ProviderNotFoundException].
  /// If [T] is non-nullable and the provider obtained returned `null`, will
  /// throw [ProviderNullException].
  ///
  /// This allows widgets to optionally depend on a provider:
  ///
  /// ```dart
  /// runApp(
  ///   Builder(builder: (context) {
  ///     final title = context.select<Movie?, String>((movie) => movie?.title);
  ///
  ///     if (title == null) Text('no Movie found');
  ///     return Text(title);
  ///   }),
  /// );
  /// ```
  ///
  /// [select] must be used only inside the `build` method of a widget.
  /// It will not work inside other life-cycles, including [State.didChangeDependencies].
  ///
  /// By using [select], instead of watching the entire object, the listener will
  /// rebuild only if the value returned by `selector` changes.
  ///
  /// When a provider emits an update, it will call synchronously all `selector`.
  ///
  /// Then, if they return a value different from the previously returned value,
  /// the dependent will be marked as needing to rebuild.
  ///
  /// For example, consider the following object:
  ///
  /// ```dart
  /// class Person with ChangeNotifier {
  ///   String name;
  ///   int age;
  ///
  ///   // Add some logic that may update `name` and `age`
  /// }
  /// ```
  ///
  /// Then a widget may want to listen to a person's `name` without listening
  /// to its `age`.
  ///
  /// This cannot be done using `context.watch`/[Provider.of]. Instead, we
  /// can use [select], by writing the following:
  ///
  /// ```dart
  /// Widget build(BuildContext context) {
  ///   final name = context.select((Person p) => p.name);
  ///
  ///   return Text(name);
  /// }
  /// ```
  ///
  /// It is fine to call `select` multiple times.
  R select<T, R>(R Function(T value) selector) {
    assert(widget is! SliverWithKeepAliveWidget, '''
    Tried to use context.select inside a SliverList/SliderGridView.

    This is likely a mistake, as instead of rebuilding only the item that cares
    about the selected value, this would rebuild the entire list/grid.

    To fix, add a `Builder` or extract the content of `itemBuilder` in a separate widget:

    ```dart
    ListView.builder(
      itemBuilder: (context, index) {
        return Builder(builder: (context) {
          final todo = context.select((TodoList list) => list[index]);
          return Text(todo.name);
        });
      },
    );
    ```
    ''');
    assert(widget is LayoutBuilder || debugDoingBuild, '''
Tried to use `context.select` outside of the `build` method of a widget.

Any usage other than inside the `build` method of a widget are not supported.
''');

    final inheritedElement = Provider._inheritedElementOf<T>(this);
    try {
      final value = inheritedElement?.value;
      if (value is! T) {
        throw ProviderNullException(T, widget.runtimeType);
      }

      assert(() {
        _debugIsSelecting = true;
        return true;
      }());
      final selected = selector(value);

      if (inheritedElement != null) {
        dependOnInheritedElement(
          inheritedElement,
          aspect: (T? newValue) {
            if (newValue is! T) {
              throw ProviderNullException(T, widget.runtimeType);
            }

            return !const DeepCollectionEquality()
                .equals(selector(newValue), selected);
          },
        );
      } else {
        // tell Flutter to rebuild the widget when relocated using GlobalKey
        // if no provider were found before.
        dependOnInheritedWidgetOfExactType<_InheritedProviderScope<T?>>();
      }
      return selected;
    } finally {
      assert(() {
        _debugIsSelecting = false;
        return true;
      }());
    }
  }
}

/// A [BuildContext] associated to an [InheritedProvider].
///
/// It an extra [markNeedsNotifyDependents] method and the exposed value.
abstract class InheritedContext<T> extends BuildContext {
  /// The current value exposed by [InheritedProvider].
  ///
  /// This property is lazy loaded, and reading it the first time may trigger
  /// some side-effects such as creating a [T] instance or starting
  /// a subscription.
  T get value;

  /// Marks the [InheritedProvider] as needing to update dependents.
  ///
  /// This bypass [InheritedWidget.updateShouldNotify] and will force widgets
  /// that depends on [T] to rebuild.
  void markNeedsNotifyDependents();

  /// Whether `setState` was called at least once or not.
  ///
  /// It can be used by [DeferredStartListening] to differentiate between the
  /// very first listening, and a rebuild after `controller` changed.
  bool get hasValue;
}

class _InheritedProviderScope<T> extends InheritedWidget {
  const _InheritedProviderScope({
    required this.owner,
    required this.debugType,
    required Widget child,
  })  : assert(null is T),
        super(child: child);

  final InheritedProvider<T> owner;
  final String debugType;

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return false;
  }

  @override
  _InheritedProviderScopeElement<T> createElement() {
    return _InheritedProviderScopeElement<T>(this);
  }
}

class _Dependency<T> {
  bool shouldClearSelectors = false;
  bool shouldClearMutationScheduled = false;
  final selectors = <_SelectorAspect<T>>[];
}

class _InheritedProviderScopeElement<T> extends InheritedElement
    implements InheritedContext<T> {
  _InheritedProviderScopeElement(_InheritedProviderScope<T> widget)
      : super(widget);

  static int _nextProviderId = 0;

  bool _shouldNotifyDependents = false;
  bool _debugInheritLocked = false;
  bool _isNotifyDependentsEnabled = true;
  bool _updatedShouldNotify = false;
  bool _isBuildFromExternalSources = false;
  late final _DelegateState<T, _Delegate<T>> _delegateState =
      widget.owner._delegate.createState()..element = this;
  late String _debugId;

  @override
  InheritedElement? getElementForInheritedWidgetOfExactType<
      InheritedWidgetType extends InheritedWidget>() {
    InheritedElement? inheritedElement;

    // An InheritedProvider<T>'s update tries to obtain a parent provider of
    // the same type.
    visitAncestorElements((parent) {
      inheritedElement =
          parent.getElementForInheritedWidgetOfExactType<InheritedWidgetType>();
      return false;
    });
    return inheritedElement;
  }

  @override
  void mount(Element? parent, dynamic newSlot) {
    if (kDebugMode) {
      _debugId = '${_nextProviderId++}';
      ProviderBinding.debugInstance.providerDetails = {
        ...ProviderBinding.debugInstance.providerDetails,
        _debugId: ProviderNode(
          id: _debugId,
          childrenNodeIds: const [],
          // ignore: no_runtimetype_tostring
          type: widget.debugType,
          element: this,
        )
      };
    }

    super.mount(parent, newSlot);
  }

  @override
  _InheritedProviderScope<T> get widget =>
      super.widget as _InheritedProviderScope<T>;

  @override
  void reassemble() {
    super.reassemble();

    final value = _delegateState.hasValue ? _delegateState.value : null;
    if (value is ReassembleHandler) {
      value.reassemble();
    }
  }

  @override
  void updateDependencies(Element dependent, Object? aspect) {
    final dependencies = getDependencies(dependent);
    // once subscribed to everything once, it always stays subscribed to everything
    if (dependencies != null && dependencies is! _Dependency<T>) {
      return;
    }

    if (aspect is _SelectorAspect<T>) {
      final selectorDependency =
          (dependencies ?? _Dependency<T>()) as _Dependency<T>;

      if (selectorDependency.shouldClearSelectors) {
        selectorDependency.shouldClearSelectors = false;
        selectorDependency.selectors.clear();
      }
      if (selectorDependency.shouldClearMutationScheduled == false) {
        selectorDependency.shouldClearMutationScheduled = true;
        Future.microtask(() {
          selectorDependency
            ..shouldClearMutationScheduled = false
            ..shouldClearSelectors = true;
        });
      }
      selectorDependency.selectors.add(aspect);
      setDependencies(dependent, selectorDependency);
    } else {
      // subscribes to everything
      setDependencies(dependent, const Object());
    }
  }

  @override
  void notifyDependent(InheritedWidget oldWidget, Element dependent) {
    final dependencies = getDependencies(dependent);

    if (kDebugMode) {
      ProviderBinding.debugInstance.providerDidChange(_debugId);
    }

    var shouldNotify = false;
    if (dependencies != null) {
      if (dependencies is _Dependency<T>) {
        // select can never be used inside `didChangeDependencies`, so if the
        // dependent is already marked as needed build, there is no point
        // in executing the selectors.
        if (dependent.dirty) {
          return;
        }

        for (final updateShouldNotify in dependencies.selectors) {
          try {
            assert(() {
              _debugIsSelecting = true;
              return true;
            }());
            shouldNotify = updateShouldNotify(value);
          } finally {
            assert(() {
              _debugIsSelecting = false;
              return true;
            }());
          }
          if (shouldNotify) {
            break;
          }
        }
      } else {
        shouldNotify = true;
      }
    }

    if (shouldNotify) {
      dependent.didChangeDependencies();
    }
  }

  @override
  void update(_InheritedProviderScope<T> newWidget) {
    assert(() {
      if (widget.owner._delegate.runtimeType !=
          newWidget.owner._delegate.runtimeType) {
        throw StateError('''
Rebuilt $widget using a different constructor.
      
This is likely a mistake and is unsupported.
If you're in this situation, consider passing a `key` unique to each individual constructor.
''');
      }
      return true;
    }());

    _isBuildFromExternalSources = true;
    _updatedShouldNotify =
        _delegateState.willUpdateDelegate(newWidget.owner._delegate);
    super.update(newWidget);
    _updatedShouldNotify = false;
  }

  @override
  void updated(InheritedWidget oldWidget) {
    super.updated(oldWidget);
    if (_updatedShouldNotify) {
      notifyClients(oldWidget);
    }
  }

  @override
  void didChangeDependencies() {
    _isBuildFromExternalSources = true;
    super.didChangeDependencies();
  }

  @override
  Widget build() {
    if (widget.owner._lazy == false) {
      value; // this will force the value to be computed.
    }
    _delegateState.build(
      isBuildFromExternalSources: _isBuildFromExternalSources,
    );
    _isBuildFromExternalSources = false;
    if (_shouldNotifyDependents) {
      _shouldNotifyDependents = false;
      notifyClients(widget);
    }
    return super.build();
  }

  @override
  void unmount() {
    _delegateState.dispose();
    if (kDebugMode) {
      ProviderBinding.debugInstance.providerDetails = {
        ...ProviderBinding.debugInstance.providerDetails,
      }..remove(_debugId);
    }
    super.unmount();
  }

  @override
  bool get hasValue => _delegateState.hasValue;

  @override
  void markNeedsNotifyDependents() {
    if (!_isNotifyDependentsEnabled) {
      return;
    }

    markNeedsBuild();
    _shouldNotifyDependents = true;
  }

  bool _debugSetInheritedLock(bool value) {
    assert(() {
      _debugInheritLocked = value;
      return true;
    }());
    return true;
  }

  @override
  T get value => _delegateState.value;

  @override
  InheritedWidget dependOnInheritedElement(
    InheritedElement ancestor, {
    Object? aspect,
  }) {
    assert(() {
      if (_debugInheritLocked) {
        throw FlutterError.fromParts(
          <DiagnosticsNode>[
            ErrorSummary(
              'Tried to listen to an InheritedWidget '
              'in a life-cycle that will never be called again.',
            ),
            ErrorDescription('''
This error typically happens when calling Provider.of with `listen` to `true`,
in a situation where listening to the provider doesn't make sense, such as:
- initState of a StatefulWidget
- the "create" callback of a provider

This is undesired because these life-cycles are called only once in the
lifetime of a widget. As such, while `listen` is `true`, the widget has
no mean to handle the update scenario.

To fix, consider:
- passing `listen: false` to `Provider.of`
- use a life-cycle that handles updates (like didChangeDependencies)
- use a provider that handles updates (like ProxyProvider).
'''),
          ],
        );
      }
      return true;
    }());
    return super.dependOnInheritedElement(ancestor, aspect: aspect);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    _delegateState.debugFillProperties(properties);
  }
}

typedef _SelectorAspect<T> = bool Function(T value);

@immutable
abstract class _Delegate<T> {
  _DelegateState<T, _Delegate<T>> createState();

  void debugFillProperties(DiagnosticPropertiesBuilder properties) {}
}

abstract class _DelegateState<T, D extends _Delegate<T>> {
  _InheritedProviderScopeElement<T?>? element;

  T get value;

  D get delegate => element!.widget.owner._delegate as D;

  bool get hasValue;

  bool debugSetInheritedLock(bool value) {
    return element!._debugSetInheritedLock(value);
  }

  bool willUpdateDelegate(D newDelegate) => false;

  void dispose() {}

  void debugFillProperties(DiagnosticPropertiesBuilder properties) {}

  void build({required bool isBuildFromExternalSources}) {}
}

class _CreateInheritedProvider<T> extends _Delegate<T> {
  _CreateInheritedProvider({
    this.create,
    this.update,
    UpdateShouldNotify<T>? updateShouldNotify,
    this.debugCheckInvalidValueType,
    this.startListening,
    this.dispose,
  })  : assert(create != null || update != null),
        _updateShouldNotify = updateShouldNotify;

  final Create<T>? create;
  final T Function(BuildContext context, T? value)? update;
  final UpdateShouldNotify<T>? _updateShouldNotify;
  final void Function(T value)? debugCheckInvalidValueType;
  final StartListening<T>? startListening;
  final Dispose<T>? dispose;

  @override
  _CreateInheritedProviderState<T> createState() =>
      _CreateInheritedProviderState();
}

@visibleForTesting
// ignore: public_member_api_docs
bool debugIsInInheritedProviderUpdate = false;

@visibleForTesting
// ignore: public_member_api_docs
bool debugIsInInheritedProviderCreate = false;

class _CreateInheritedProviderState<T>
    extends _DelegateState<T, _CreateInheritedProvider<T>> {
  VoidCallback? _removeListener;
  bool _didInitValue = false;
  T? _value;
  _CreateInheritedProvider<T>? _previousWidget;
  FlutterErrorDetails? _initError;

  @override
  T get value {
    if (_didInitValue && _initError != null) {
      // TODO(rrousselGit) update to use Error.throwWithStacktTrace when it reaches stable
      throw StateError(
        'Tried to read a provider that threw during the creation of its value.\n'
        'The exception occurred during the creation of type $T.\n\n'
        '${_initError?.toString()}',
      );
    }
    bool? _debugPreviousIsInInheritedProviderCreate;
    bool? _debugPreviousIsInInheritedProviderUpdate;

    assert(() {
      _debugPreviousIsInInheritedProviderCreate =
          debugIsInInheritedProviderCreate;
      _debugPreviousIsInInheritedProviderUpdate =
          debugIsInInheritedProviderUpdate;
      return true;
    }());

    if (!_didInitValue) {
      _didInitValue = true;
      if (delegate.create != null) {
        assert(debugSetInheritedLock(true));
        try {
          assert(() {
            debugIsInInheritedProviderCreate = true;
            debugIsInInheritedProviderUpdate = false;
            return true;
          }());
          _value = delegate.create!(element!);
        } catch (e, stackTrace) {
          _initError = FlutterErrorDetails(
            library: 'provider',
            exception: e,
            stack: stackTrace,
          );
          rethrow;
        } finally {
          assert(() {
            debugIsInInheritedProviderCreate =
                _debugPreviousIsInInheritedProviderCreate!;
            debugIsInInheritedProviderUpdate =
                _debugPreviousIsInInheritedProviderUpdate!;
            return true;
          }());
        }
        assert(debugSetInheritedLock(false));

        assert(() {
          delegate.debugCheckInvalidValueType?.call(_value as T);
          return true;
        }());
      }
      if (delegate.update != null) {
        try {
          assert(() {
            debugIsInInheritedProviderCreate = false;
            debugIsInInheritedProviderUpdate = true;
            return true;
          }());
          _value = delegate.update!(element!, _value);
        } finally {
          assert(() {
            debugIsInInheritedProviderCreate =
                _debugPreviousIsInInheritedProviderCreate!;
            debugIsInInheritedProviderUpdate =
                _debugPreviousIsInInheritedProviderUpdate!;
            return true;
          }());
        }

        assert(() {
          delegate.debugCheckInvalidValueType?.call(_value as T);
          return true;
        }());
      }
    }

    element!._isNotifyDependentsEnabled = false;
    _removeListener ??= delegate.startListening?.call(element!, _value as T);
    element!._isNotifyDependentsEnabled = true;
    assert(delegate.startListening == null || _removeListener != null);
    return _value as T;
  }

  @override
  void dispose() {
    super.dispose();
    _removeListener?.call();
    if (_didInitValue) {
      delegate.dispose?.call(element!, _value as T);
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    if (_didInitValue) {
      properties
        ..add(DiagnosticsProperty('value', value))
        ..add(
          FlagProperty(
            '',
            value: _removeListener != null,
            defaultValue: false,
            ifTrue: 'listening to value',
          ),
        );
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

  @override
  void build({required bool isBuildFromExternalSources}) {
    var shouldNotify = false;
    // Don't call `update` unless the build was triggered from `updated`/`didChangeDependencies`
    // otherwise `markNeedsNotifyDependents` will trigger unnecessary `update` calls
    if (isBuildFromExternalSources &&
        _didInitValue &&
        delegate.update != null) {
      final previousValue = _value;

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
          debugIsInInheritedProviderCreate = false;
          debugIsInInheritedProviderUpdate = true;
          return true;
        }());
        _value = delegate.update!(element!, _value as T);
      } finally {
        assert(() {
          debugIsInInheritedProviderCreate =
              _debugPreviousIsInInheritedProviderCreate!;
          debugIsInInheritedProviderUpdate =
              _debugPreviousIsInInheritedProviderUpdate!;
          return true;
        }());
      }

      if (delegate._updateShouldNotify != null) {
        shouldNotify = delegate._updateShouldNotify!(
          previousValue as T,
          _value as T,
        );
      } else {
        shouldNotify = _value != previousValue;
      }

      if (shouldNotify) {
        assert(() {
          delegate.debugCheckInvalidValueType?.call(_value as T);
          return true;
        }());
        if (_removeListener != null) {
          _removeListener!();
          _removeListener = null;
        }
        _previousWidget?.dispose?.call(element!, previousValue as T);
      }
    }

    if (shouldNotify) {
      element!._shouldNotifyDependents = true;
    }
    _previousWidget = delegate;
    return super.build(isBuildFromExternalSources: isBuildFromExternalSources);
  }

  @override
  bool get hasValue => _didInitValue;
}

class _ValueInheritedProvider<T> extends _Delegate<T> {
  _ValueInheritedProvider({
    required this.value,
    UpdateShouldNotify<T>? updateShouldNotify,
    this.startListening,
  }) : _updateShouldNotify = updateShouldNotify;

  final T value;
  final UpdateShouldNotify<T>? _updateShouldNotify;
  final StartListening<T>? startListening;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('value', value));
  }

  @override
  _ValueInheritedProviderState<T> createState() {
    return _ValueInheritedProviderState<T>();
  }
}

class _ValueInheritedProviderState<T>
    extends _DelegateState<T, _ValueInheritedProvider<T>> {
  VoidCallback? _removeListener;

  @override
  T get value {
    element!._isNotifyDependentsEnabled = false;
    _removeListener ??= delegate.startListening?.call(element!, delegate.value);
    element!._isNotifyDependentsEnabled = true;
    assert(delegate.startListening == null || _removeListener != null);
    return delegate.value;
  }

  @override
  bool willUpdateDelegate(_ValueInheritedProvider<T> newDelegate) {
    bool shouldNotify;
    if (delegate._updateShouldNotify != null) {
      shouldNotify = delegate._updateShouldNotify!(
        delegate.value,
        newDelegate.value,
      );
    } else {
      shouldNotify = newDelegate.value != delegate.value;
    }

    if (shouldNotify && _removeListener != null) {
      _removeListener!();
      _removeListener = null;
    }
    return shouldNotify;
  }

  @override
  void dispose() {
    super.dispose();
    _removeListener?.call();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      FlagProperty(
        '',
        value: _removeListener != null,
        defaultValue: false,
        ifTrue: 'listening to value',
      ),
    );
  }

  @override
  bool get hasValue => true;
}
