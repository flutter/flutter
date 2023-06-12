// /!\ DO NOT MOVE THIS FILE /!\
//
// Flutter's devtool rely on the path to this file to be able to communicate with `provider`.

import 'dart:developer' as developer;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:nested/nested.dart';

import 'reassemble_handler.dart';

part 'deferred_inherited_provider.dart';
part 'devtool.dart';
part 'inherited_provider.dart';

/// Whether the runtime has null safe sound mode enabled.
///
/// In sound mode, all code is null safe and null safety is enforced everywhere.
/// Nullability in generics is also enforced, which is how this code detects
/// sound mode.
///
/// In unsound mode, there can be a mix of null safe and legacy code. Some null
/// checks are not done, and generics are not compared for null safety.
final bool _isSoundMode = <int?>[] is! List<int>;

/// A provider that merges multiple providers into a single linear widget tree.
/// It is used to improve readability and reduce boilerplate code of having to
/// nest multiple layers of providers.
///
/// As such, we're going from:
///
/// ```dart
/// Provider<Something>(
///   create: (_) => Something(),
///   child: Provider<SomethingElse>(
///     create: (_) => SomethingElse(),
///     child: Provider<AnotherThing>(
///       create: (_) => AnotherThing(),
///       child: someWidget,
///     ),
///   ),
/// ),
/// ```
///
/// To:
///
/// ```dart
/// MultiProvider(
///   providers: [
///     Provider<Something>(create: (_) => Something()),
///     Provider<SomethingElse>(create: (_) => SomethingElse()),
///     Provider<AnotherThing>(create: (_) => AnotherThing()),
///   ],
///   child: someWidget,
/// )
/// ```
///
/// The widget tree representation of the two approaches are identical.
class MultiProvider extends Nested {
  /// Build a tree of providers from a list of [SingleChildWidget].
  ///
  /// The parameter `builder` is syntactic sugar for obtaining a [BuildContext] that can
  /// read the providers created.
  ///
  /// This code:
  ///
  /// ```dart
  /// MultiProvider(
  ///   providers: [
  ///     Provider<Something>(create: (_) => Something()),
  ///     Provider<SomethingElse>(create: (_) => SomethingElse()),
  ///     Provider<AnotherThing>(create: (_) => AnotherThing()),
  ///   ],
  ///   builder: (context, child) {
  ///     final something = context.watch<Something>();
  ///     return Text('$something');
  ///   },
  /// )
  /// ```
  ///
  /// is strictly equivalent to:
  ///
  /// ```dart
  /// MultiProvider(
  ///   providers: [
  ///     Provider<Something>(create: (_) => Something()),
  ///     Provider<SomethingElse>(create: (_) => SomethingElse()),
  ///     Provider<AnotherThing>(create: (_) => AnotherThing()),
  ///   ],
  ///   child: Builder(
  ///     builder: (context) {
  ///       final something = context.watch<Something>();
  ///       return Text('$something');
  ///     },
  ///   ),
  /// )
  /// ```
  ///
  /// If the some provider in `providers` has a child, this will be ignored.
  ///
  /// This code:
  /// ```dart
  /// MultiProvider(
  ///   providers: [
  ///     Provider<Something>(create: (_) => Something(), child: SomeWidget()),
  ///   ],
  ///   child: Text('Something'),
  /// )
  /// ```
  /// is equivalent to:
  ///
  /// ```dart
  /// MultiProvider(
  ///   providers: [
  ///     Provider<Something>(create: (_) => Something()),
  ///   ],
  ///   child: Text('Something'),
  /// )
  /// ```
  ///
  /// For an explanation on the `child` parameter that `builder` receives,
  /// see the "Performance optimizations" section of [AnimatedBuilder].
  MultiProvider({
    Key? key,
    required List<SingleChildWidget> providers,
    Widget? child,
    TransitionBuilder? builder,
  }) : super(
          key: key,
          children: providers,
          child: builder != null
              ? Builder(
                  builder: (context) => builder(context, child),
                )
              : child,
        );
}

/// A [Provider] that manages the lifecycle of the value it provides by
/// delegating to a pair of [Create] and [Dispose].
///
/// It is usually used to avoid making a [StatefulWidget] for something trivial,
/// such as instantiating a BLoC.
///
/// [Provider] is the equivalent of a [State.initState] combined with
/// [State.dispose]. [Create] is called only once in [State.initState].
/// We cannot use [InheritedWidget] as it requires the value to be
/// constructor-initialized and final.
///
/// The following example instantiates a `Model` once, and disposes it when
/// [Provider] is removed from the tree.
///
/// ```dart
/// class Model {
///   void dispose() {}
/// }
///
/// class Stateless extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return Provider<Model>(
///       create: (context) =>  Model(),
///       dispose: (context, value) => value.dispose(),
///       child: ...,
///     );
///   }
/// }
/// ```
///
/// It is worth noting that the `create` callback is lazily called.
/// It is called the first time the value is read, instead of the first time
/// [Provider] is inserted in the widget tree.
///
/// This behavior can be disabled by passing `lazy: false` to [Provider].
///
/// ## Testing
///
/// When testing widgets that consumes providers, it is necessary to
/// add the proper providers in the widget tree above the tested widget.
///
/// A typical test may look like this:
///
/// ```dart
/// final foo = MockFoo();
///
/// await tester.pumpWidget(
///   Provider<Foo>.value(
///     value: foo,
///     child: TestedWidget(),
///   ),
/// );
/// ```
///
/// Note this example purposefully specified the object type, instead of having
/// it inferred.
/// Since we used a mocked class (typically using `mockito`), then we have to
/// downcast the mock to the type of the mocked class.
/// Otherwise, the type inference will resolve to `Provider<MockFoo>` instead of
/// `Provider<Foo>`, which will cause `Provider.of<Foo>` to fail.
class Provider<T> extends InheritedProvider<T> {
  /// Creates a value, store it, and expose it to its descendants.
  ///
  /// The value can be optionally disposed using [dispose] callback.
  /// This callback which will be called when [Provider] is unmounted from the
  /// widget tree.
  Provider({
    Key? key,
    required Create<T> create,
    Dispose<T>? dispose,
    bool? lazy,
    TransitionBuilder? builder,
    Widget? child,
  }) : super(
          key: key,
          lazy: lazy,
          builder: builder,
          create: create,
          dispose: dispose,
          debugCheckInvalidValueType: kReleaseMode
              ? null
              : (T value) =>
                  Provider.debugCheckInvalidValueType?.call<T>(value),
          child: child,
        );

  /// Expose an existing value without disposing it.
  ///
  /// {@template provider.updateshouldnotify}
  /// `updateShouldNotify` can optionally be passed to avoid unnecessarily
  /// rebuilding dependents when [Provider] is rebuilt but `value` did not change.
  ///
  /// Defaults to `(previous, next) => previous != next`.
  /// See [InheritedWidget.updateShouldNotify] for more information.
  /// {@endtemplate}
  Provider.value({
    Key? key,
    required T value,
    UpdateShouldNotify<T>? updateShouldNotify,
    TransitionBuilder? builder,
    Widget? child,
  })  : assert(() {
          Provider.debugCheckInvalidValueType?.call<T>(value);
          return true;
        }()),
        super.value(
          key: key,
          builder: builder,
          value: value,
          updateShouldNotify: updateShouldNotify,
          child: child,
        );

  /// Obtains the nearest [Provider<T>] up its widget tree and returns its
  /// value.
  ///
  /// If [listen] is `true`, later value changes will trigger a new
  /// [State.build] to widgets, and [State.didChangeDependencies] for
  /// [StatefulWidget].
  ///
  /// `listen: false` is necessary to be able to call `Provider.of` inside
  /// [State.initState] or the `create` method of providers like so:
  ///
  /// ```dart
  /// Provider(
  ///   create: (context) {
  ///     return Model(Provider.of<Something>(context, listen: false)),
  ///   },
  /// )
  /// ```
  static T of<T>(BuildContext context, {bool listen = true}) {
    assert(
      context.owner!.debugBuilding ||
          listen == false ||
          debugIsInInheritedProviderUpdate,
      '''
Tried to listen to a value exposed with provider, from outside of the widget tree.

This is likely caused by an event handler (like a button's onPressed) that called
Provider.of without passing `listen: false`.

To fix, write:
Provider.of<$T>(context, listen: false);

It is unsupported because may pointlessly rebuild the widget associated to the
event handler, when the widget tree doesn't care about the value.

The context used was: $context
''',
    );

    final inheritedElement = _inheritedElementOf<T>(context);

    if (listen) {
      // bind context with the element
      // We have to use this method instead of dependOnInheritedElement, because
      // dependOnInheritedElement does not support relocating using GlobalKey
      // if no provider were found previously.
      context.dependOnInheritedWidgetOfExactType<_InheritedProviderScope<T?>>();
    }

    final value = inheritedElement?.value;

    if (_isSoundMode) {
      if (value is! T) {
        throw ProviderNullException(T, context.widget.runtimeType);
      }
      return value;
    }

    return value as T;
  }

  static _InheritedProviderScopeElement<T?>? _inheritedElementOf<T>(
    BuildContext context,
  ) {
    // ignore: unnecessary_null_comparison, can happen if the application depends on a non-migrated code
    assert(context != null, '''
Tried to call context.read/watch/select or similar on a `context` that is null.

This can happen if you used the context of a StatefulWidget and that
StatefulWidget was disposed.
''');
    assert(
      _debugIsSelecting == false,
      'Cannot call context.read/watch/select inside the callback of a context.select',
    );
    assert(
      T != dynamic,
      '''
Tried to call Provider.of<dynamic>. This is likely a mistake and is therefore
unsupported.

If you want to expose a variable that can be anything, consider changing
`dynamic` to `Object` instead.
''',
    );
    final inheritedElement = context.getElementForInheritedWidgetOfExactType<
        _InheritedProviderScope<T?>>() as _InheritedProviderScopeElement<T?>?;

    if (inheritedElement == null && null is! T) {
      throw ProviderNotFoundException(T, context.widget.runtimeType);
    }

    return inheritedElement;
  }

  /// A sanity check to prevent misuse of [Provider] when a variant should be
  /// used instead.
  ///
  /// By default, [debugCheckInvalidValueType] will throw if `value` is a
  /// [Listenable] or a [Stream]. In release mode, [debugCheckInvalidValueType]
  /// does nothing.
  ///
  /// You can override the default behavior by "decorating" the default function.\
  /// For example if you want to allow rxdart's `Subject` to work on [Provider], then
  /// you could do:
  ///
  /// ```dart
  /// void main() {
  ///  final previous = Provider.debugCheckInvalidValueType;
  ///  Provider.debugCheckInvalidValueType = <T>(value) {
  ///    if (value is Subject) return;
  ///    previous<T>(value);
  ///  };
  ///
  ///  // ...
  /// }
  /// ```
  ///
  /// This will allow `Subject`, but still allow [Stream]/[Listenable].
  ///
  /// Alternatively you can disable this check entirely by setting
  /// [debugCheckInvalidValueType] to `null`:
  ///
  /// ```dart
  /// void main() {
  ///   Provider.debugCheckInvalidValueType = null;
  ///   runApp(MyApp());
  /// }
  /// ```
  // ignore: prefer_function_declarations_over_variables, false positive
  static void Function<T>(T value)? debugCheckInvalidValueType = <T>(T value) {
    assert(() {
      if (value is Listenable || value is Stream) {
        throw FlutterError('''
Tried to use Provider with a subtype of Listenable/Stream ($T).

This is likely a mistake, as Provider will not automatically update dependents
when $T is updated. Instead, consider changing Provider for more specific
implementation that handles the update mechanism, such as:

- ListenableProvider
- ChangeNotifierProvider
- ValueListenableProvider
- StreamProvider

Alternatively, if you are making your own provider, consider using InheritedProvider.

If you think that this is not an error, you can disable this check by setting
Provider.debugCheckInvalidValueType to `null` in your main file:

```
void main() {
  Provider.debugCheckInvalidValueType = null;

  runApp(MyApp());
}
```
''');
      }
      return true;
    }());
  };
}

/// Called `Provider.of<T>` instead of `Provider.of<T?>` but the provider
/// returned `null`.
class ProviderNullException implements Exception {
  /// Create a ProviderNullException error with the type represented as a String.
  ProviderNullException(this.valueType, this.widgetType);

  /// The type of the value being retrieved
  final Type valueType;

  /// The type of the Widget requesting the value
  final Type widgetType;
  @override
  String toString() {
    if (kReleaseMode) {
      return 'A provider for $valueType unexpectedly returned null.';
    }
    return '''
Error: The widget $widgetType tried to read Provider<$valueType> but the matching
provider returned null.

To fix the error, consider changing Provider<$valueType> to Provider<$valueType?>.
''';
  }
}

/// The error that will be thrown if [Provider.of] fails to find a [Provider]
/// as an ancestor of the [BuildContext] used.
class ProviderNotFoundException implements Exception {
  /// Create a ProviderNotFound error with the type represented as a String.
  ProviderNotFoundException(
    this.valueType,
    this.widgetType,
  );

  /// The type of the value being retrieved
  final Type valueType;

  /// The type of the Widget requesting the value
  final Type widgetType;

  @override
  String toString() {
    if (kReleaseMode) {
      return 'Provider<$valueType> not found for $widgetType';
    }
    return '''
Error: Could not find the correct Provider<$valueType> above this $widgetType Widget

This happens because you used a `BuildContext` that does not include the provider
of your choice. There are a few common scenarios:

- You added a new provider in your `main.dart` and performed a hot-reload.
  To fix, perform a hot-restart.

- The provider you are trying to read is in a different route.

  Providers are "scoped". So if you insert of provider inside a route, then
  other routes will not be able to access that provider.

- You used a `BuildContext` that is an ancestor of the provider you are trying to read.

  Make sure that $widgetType is under your MultiProvider/Provider<$valueType>.
  This usually happens when you are creating a provider and trying to read it immediately.

  For example, instead of:

  ```
  Widget build(BuildContext context) {
    return Provider<Example>(
      create: (_) => Example(),
      // Will throw a ProviderNotFoundError, because `context` is associated
      // to the widget that is the parent of `Provider<Example>`
      child: Text(context.watch<Example>().toString()),
    );
  }
  ```

  consider using `builder` like so:

  ```
  Widget build(BuildContext context) {
    return Provider<Example>(
      create: (_) => Example(),
      // we use `builder` to obtain a new `BuildContext` that has access to the provider
      builder: (context, child) {
        // No longer throws
        return Text(context.watch<Example>().toString());
      }
    );
  }
  ```

If none of these solutions work, consider asking for help on StackOverflow:
https://stackoverflow.com/questions/tagged/flutter
''';
  }
}

/// Exposes the [read] method.
extension ReadContext on BuildContext {
  /// Obtain a value from the nearest ancestor provider of type [T].
  ///
  /// This method is the opposite of [watch].\
  /// It will _not_ make widget rebuild when the value changes and cannot be
  /// called inside [StatelessWidget.build]/[State.build].\
  /// On the other hand, it can be freely called _outside_ of these methods.
  ///
  /// If that is incompatible with your criteria, consider using `Provider.of(context, listen: false)`.\
  /// It does the same thing, but without these added restrictions (but unsafe).
  ///
  /// **DON'T** call [read] inside build if the value is used only for events:
  ///
  /// ```dart
  /// Widget build(BuildContext context) {
  ///   // counter is used only for the onPressed of RaisedButton
  ///   final counter = context.read<Counter>();
  ///
  ///   return RaisedButton(
  ///     onPressed: () => counter.increment(),
  ///   );
  /// }
  /// ```
  ///
  /// While this code is not bugged in itself, this is an anti-pattern.
  /// It could easily lead to bugs in the future after refactoring the widget
  /// to use `counter` for other things, but forget to change [read] into [watch].
  ///
  /// **CONSIDER** calling [read] inside event handlers:
  ///
  /// ```dart
  /// Widget build(BuildContext context) {
  ///   return RaisedButton(
  ///     onPressed: () {
  ///       // as performant as the previous solution, but resilient to refactoring
  ///       context.read<Counter>().increment(),
  ///     },
  ///   );
  /// }
  /// ```
  ///
  /// This has the same efficiency as the previous anti-pattern, but does not
  /// suffer from the drawback of being brittle.
  ///
  /// **DON'T** use [read] for creating widgets with a value that never changes
  ///
  /// ```dart
  /// Widget build(BuildContext context) {
  ///   // using read because we only use a value that never changes.
  ///   final model = context.read<Model>();
  ///
  ///   return Text('${model.valueThatNeverChanges}');
  /// }
  /// ```
  ///
  /// While the idea of not rebuilding the widget if something else changes is
  /// good, this should not be done with [read].
  /// Relying on [read] for optimisations is very brittle and dependent
  /// on an implementation detail.
  ///
  /// **CONSIDER** using [select] for filtering unwanted rebuilds
  ///
  /// ```dart
  /// Widget build(BuildContext context) {
  ///   // Using select to listen only to the value that used
  ///   final valueThatNeverChanges = context.select((Model model) => model.valueThatNeverChanges);
  ///
  ///   return Text('$valueThatNeverChanges');
  /// }
  /// ```
  ///
  /// While more verbose than [read], using [select] is a lot safer.
  /// It does not rely on implementation details on `Model`, and it makes
  /// impossible to have a bug where our UI does not refresh.
  ///
  /// ## Using [read] to simplify objects depending on other objects
  ///
  /// This method can be freely passed to objects, so that they can read providers
  /// without having a reference on a [BuildContext].
  ///
  /// For example, instead of:
  ///
  /// ```dart
  /// class Model {
  ///   Model(this.context);
  ///
  ///   final BuildContext context;
  ///
  ///   void method() {
  ///     print(Provider.of<Whatever>(context));
  ///   }
  /// }
  ///
  /// // ...
  ///
  /// Provider(
  ///   create: (context) => Model(context),
  ///   child: ...,
  /// )
  /// ```
  ///
  /// we will prefer to write:
  ///
  /// ```dart
  /// class Model {
  ///   Model(this.read);
  ///
  ///   // `Locator` is a typedef that matches the type of `read`
  ///   final Locator read;
  ///
  ///   void method() {
  ///     print(read<Whatever>());
  ///   }
  /// }
  ///
  /// // ...
  ///
  /// Provider(
  ///   create: (context) => Model(context.read),
  ///   child: ...,
  /// )
  /// ```
  ///
  /// Both snippets behaves the same. But in the second snippet, `Model` has no dependency
  /// on Flutter/[BuildContext]/provider.
  ///
  /// See also:
  ///
  /// - [WatchContext] and its `watch` method, similar to [read], but
  ///   will make the widget tree rebuild when the obtained value changes.
  /// - [Locator], a typedef to make it easier to pass [read] to objects.
  T read<T>() {
    return Provider.of<T>(this, listen: false);
  }
}

/// Exposes the [watch] method.
extension WatchContext on BuildContext {
  /// Obtain a value from the nearest ancestor provider of type [T] or [T?], and subscribe
  /// to the provider.
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
  ///     final value = context.watch<Movie?>();
  ///
  ///     if (value == null) Text('no Movie found');
  ///     return Text(movie.title);
  ///   }),
  /// );
  /// ```
  ///
  /// Calling this method is equivalent to calling:
  ///
  /// ```dart
  /// Provider.of<T>(context)
  /// ```
  ///
  /// This method is accessible only inside [StatelessWidget.build] and
  /// [State.build].\
  /// If you need to use it outside of these methods, consider using [Provider.of]
  /// instead, which doesn't have this restriction.\
  /// The only exception to this rule is Providers's `update` method.
  ///
  /// See also:
  ///
  /// - [ReadContext] and its `read` method, similar to [watch], but doesn't make
  ///   widgets rebuild if the value obtained changes.
  T watch<T>() {
    return Provider.of<T>(this);
  }
}

/// A generic function that can be called to read providers, without having a
/// reference on [BuildContext].
///
/// It is typically a reference to the `read` [BuildContext] extension:
///
/// ```dart
/// BuildContext context;
/// Locator locator = context.read;
/// ```
///
/// This function
typedef Locator = T Function<T>();
