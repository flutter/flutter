import 'package:flutter/widgets.dart';

import 'change_notifier_provider.dart'
    show ChangeNotifierProvider, ChangeNotifierProxyProvider;
import 'provider.dart';
import 'proxy_provider.dart';

/// Listens to a [Listenable], expose it to its descendants and rebuilds
/// dependents whenever the listener emits an event.
///
/// For usage information, see [ChangeNotifierProvider], a subclass of
/// [ListenableProvider] made for [ChangeNotifier].
///
/// You will generally want to use [ChangeNotifierProvider] instead.
/// But [ListenableProvider] is available in case you want to implement
/// [Listenable] yourself, or use [Animation].
class ListenableProvider<T extends Listenable?> extends InheritedProvider<T> {
  /// Creates a [Listenable] using [create] and subscribes to it.
  ///
  /// [dispose] can optionally passed to free resources
  /// when [ListenableProvider] is removed from the tree.
  ///
  /// [create] must not be `null`.
  ListenableProvider({
    Key? key,
    required Create<T> create,
    Dispose<T>? dispose,
    bool? lazy,
    TransitionBuilder? builder,
    Widget? child,
  }) : super(
          key: key,
          startListening: _startListening,
          create: create,
          dispose: dispose,
          lazy: lazy,
          builder: builder,
          child: child,
        );

  /// Provides an existing [Listenable].
  ListenableProvider.value({
    Key? key,
    required T value,
    UpdateShouldNotify<T>? updateShouldNotify,
    TransitionBuilder? builder,
    Widget? child,
  }) : super.value(
          key: key,
          builder: builder,
          value: value,
          updateShouldNotify: updateShouldNotify,
          startListening: _startListening,
          child: child,
        );

  static VoidCallback _startListening(
    InheritedContext e,
    Listenable? value,
  ) {
    value?.addListener(e.markNeedsNotifyDependents);
    return () => value?.removeListener(e.markNeedsNotifyDependents);
  }
}

/// {@macro provider.listenableproxyprovider}
class ListenableProxyProvider0<R extends Listenable?>
    extends InheritedProvider<R> {
  /// Initializes [key] for subclasses.
  ListenableProxyProvider0({
    Key? key,
    Create<R>? create,
    required R Function(BuildContext, R? previous) update,
    Dispose<R>? dispose,
    UpdateShouldNotify<R>? updateShouldNotify,
    bool? lazy,
    TransitionBuilder? builder,
    Widget? child,
  }) : super(
          key: key,
          create: create,
          update: update,
          lazy: lazy,
          builder: builder,
          dispose: dispose,
          updateShouldNotify: updateShouldNotify,
          startListening: ListenableProvider._startListening,
          child: child,
        );
}

/// {@template provider.listenableproxyprovider}
/// A variation of [ListenableProvider] that builds its value from
/// values obtained from other providers.
///
/// See the discussion on [ChangeNotifierProxyProvider] for a complete
/// explanation on how to use it.
///
/// [ChangeNotifierProxyProvider] extends [ListenableProxyProvider] to make it
/// work with [ChangeNotifier], but the behavior stays the same.
/// Most of the time you'll want to use [ChangeNotifierProxyProvider] instead.
/// But [ListenableProxyProvider] is exposed in case someone wants to use a
/// [Listenable] implementation other than [ChangeNotifier], such as
/// [Animation].
/// {@endtemplate}
class ListenableProxyProvider<T, R extends Listenable?>
    extends ListenableProxyProvider0<R> {
  /// Initializes [key] for subclasses.
  ListenableProxyProvider({
    Key? key,
    Create<R>? create,
    required ProxyProviderBuilder<T, R> update,
    Dispose<R>? dispose,
    bool? lazy,
    TransitionBuilder? builder,
    Widget? child,
  }) : super(
          key: key,
          create: create,
          lazy: lazy,
          builder: builder,
          update: (context, previous) => update(
            context,
            Provider.of(context),
            previous,
          ),
          dispose: dispose,
          child: child,
        );
}

/// {@macro provider.listenableproxyprovider}
class ListenableProxyProvider2<T, T2, R extends Listenable?>
    extends ListenableProxyProvider0<R> {
  /// Initializes [key] for subclasses.
  ListenableProxyProvider2({
    Key? key,
    Create<R>? create,
    required ProxyProviderBuilder2<T, T2, R> update,
    Dispose<R>? dispose,
    bool? lazy,
    TransitionBuilder? builder,
    Widget? child,
  }) : super(
          key: key,
          create: create,
          lazy: lazy,
          builder: builder,
          update: (context, previous) => update(
            context,
            Provider.of(context),
            Provider.of(context),
            previous,
          ),
          dispose: dispose,
          child: child,
        );
}

/// {@macro provider.listenableproxyprovider}
class ListenableProxyProvider3<T, T2, T3, R extends Listenable?>
    extends ListenableProxyProvider0<R> {
  /// Initializes [key] for subclasses.
  ListenableProxyProvider3({
    Key? key,
    Create<R>? create,
    required ProxyProviderBuilder3<T, T2, T3, R> update,
    Dispose<R>? dispose,
    bool? lazy,
    TransitionBuilder? builder,
    Widget? child,
  }) : super(
          key: key,
          create: create,
          lazy: lazy,
          builder: builder,
          update: (context, previous) => update(
            context,
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            previous,
          ),
          dispose: dispose,
          child: child,
        );
}

/// {@macro provider.listenableproxyprovider}
class ListenableProxyProvider4<T, T2, T3, T4, R extends Listenable?>
    extends ListenableProxyProvider0<R> {
  /// Initializes [key] for subclasses.
  ListenableProxyProvider4({
    Key? key,
    Create<R>? create,
    required ProxyProviderBuilder4<T, T2, T3, T4, R> update,
    Dispose<R>? dispose,
    bool? lazy,
    TransitionBuilder? builder,
    Widget? child,
  }) : super(
          key: key,
          create: create,
          lazy: lazy,
          builder: builder,
          update: (context, previous) => update(
            context,
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            previous,
          ),
          dispose: dispose,
          child: child,
        );
}

/// {@macro provider.listenableproxyprovider}
class ListenableProxyProvider5<T, T2, T3, T4, T5, R extends Listenable?>
    extends ListenableProxyProvider0<R> {
  /// Initializes [key] for subclasses.
  ListenableProxyProvider5({
    Key? key,
    Create<R>? create,
    required ProxyProviderBuilder5<T, T2, T3, T4, T5, R> update,
    Dispose<R>? dispose,
    bool? lazy,
    TransitionBuilder? builder,
    Widget? child,
  }) : super(
          key: key,
          create: create,
          lazy: lazy,
          builder: builder,
          update: (context, previous) => update(
            context,
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            previous,
          ),
          dispose: dispose,
          child: child,
        );
}

/// {@macro provider.listenableproxyprovider}
class ListenableProxyProvider6<T, T2, T3, T4, T5, T6, R extends Listenable?>
    extends ListenableProxyProvider0<R> {
  /// Initializes [key] for subclasses.
  ListenableProxyProvider6({
    Key? key,
    Create<R>? create,
    required ProxyProviderBuilder6<T, T2, T3, T4, T5, T6, R> update,
    Dispose<R>? dispose,
    bool? lazy,
    TransitionBuilder? builder,
    Widget? child,
  }) : super(
          key: key,
          create: create,
          lazy: lazy,
          builder: builder,
          update: (context, previous) => update(
            context,
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            previous,
          ),
          dispose: dispose,
          child: child,
        );
}
