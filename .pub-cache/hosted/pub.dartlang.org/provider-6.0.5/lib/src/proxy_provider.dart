import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'provider.dart';

// ignore: public_member_api_docs
typedef ProviderBuilder<R> = Widget Function(
  BuildContext context,
  R value,
  Widget child,
);

// ignore: public_member_api_docs
typedef ProxyProviderBuilder<T, R> = R Function(
  BuildContext context,
  T value,
  R? previous,
);

// ignore: public_member_api_docs
typedef ProxyProviderBuilder2<T, T2, R> = R Function(
  BuildContext context,
  T value,
  T2 value2,
  R? previous,
);

// ignore: public_member_api_docs
typedef ProxyProviderBuilder3<T, T2, T3, R> = R Function(
  BuildContext context,
  T value,
  T2 value2,
  T3 value3,
  R? previous,
);

// ignore: public_member_api_docs
typedef ProxyProviderBuilder4<T, T2, T3, T4, R> = R Function(
  BuildContext context,
  T value,
  T2 value2,
  T3 value3,
  T4 value4,
  R? previous,
);

// ignore: public_member_api_docs
typedef ProxyProviderBuilder5<T, T2, T3, T4, T5, R> = R Function(
  BuildContext context,
  T value,
  T2 value2,
  T3 value3,
  T4 value4,
  T5 value5,
  R? previous,
);

// ignore: public_member_api_docs
typedef ProxyProviderBuilder6<T, T2, T3, T4, T5, T6, R> = R Function(
  BuildContext context,
  T value,
  T2 value2,
  T3 value3,
  T4 value4,
  T5 value5,
  T6 value6,
  R? previous,
);

/// {@macro provider.proxyprovider}
class ProxyProvider0<R> extends InheritedProvider<R> {
  /// Initializes [key] for subclasses.
  ProxyProvider0({
    Key? key,
    Create<R>? create,
    required R Function(BuildContext context, R? value) update,
    UpdateShouldNotify<R>? updateShouldNotify,
    Dispose<R>? dispose,
    bool? lazy,
    TransitionBuilder? builder,
    Widget? child,
  }) : super(
          key: key,
          lazy: lazy,
          builder: builder,
          create: create,
          update: update,
          dispose: dispose,
          updateShouldNotify: updateShouldNotify,
          debugCheckInvalidValueType: kReleaseMode
              ? null
              : (R value) =>
                  Provider.debugCheckInvalidValueType?.call<R>(value),
          child: child,
        );
}

/// {@template provider.proxyprovider}
/// A provider that builds a value based on other providers.
///
/// The exposed value is built through either `create` or `update`, then passed
/// to [InheritedProvider].
///
/// As opposed to `create`, `update` may be called more than once.
/// It will be called once the first time the value is obtained, then once
/// whenever [ProxyProvider] rebuilds or when one of the providers it depends on
/// updates.
///
/// [ProxyProvider] comes in different variants such as [ProxyProvider2]. This
/// is syntax sugar on the top of [ProxyProvider0].
///
/// As such, `ProxyProvider<A, Result>` is equal to:
/// ```dart
/// ProxyProvider0<Result>(
///   update: (context, result) {
///     final a = Provider.of<A>(context);
///     return update(context, a, result);
///   }
/// );
/// ```
///
/// Whereas `ProxyProvider2<A, B, Result>` is equal to:
/// ```dart
/// ProxyProvider0<Result>(
///   update: (context, result) {
///     final a = Provider.of<A>(context);
///     final b = Provider.of<B>(context);
///     return update(context, a, b, result);
///   }
/// );
/// ```
///
/// This last parameter of `update` is the last value returned by either
/// `create` or `update`.
/// It is `null` by default.
///
/// `update` must not be `null`.
///
/// See also:
///
///  * [Provider], which matches the behavior of [ProxyProvider] but has only
///     a `create` callback.
/// {@endtemplate}
class ProxyProvider<T, R> extends ProxyProvider0<R> {
  /// Initializes [key] for subclasses.
  ProxyProvider({
    Key? key,
    Create<R>? create,
    required ProxyProviderBuilder<T, R> update,
    UpdateShouldNotify<R>? updateShouldNotify,
    Dispose<R>? dispose,
    bool? lazy,
    TransitionBuilder? builder,
    Widget? child,
  }) : super(
          key: key,
          lazy: lazy,
          builder: builder,
          create: create,
          update: (context, value) => update(
            context,
            Provider.of(context),
            value,
          ),
          updateShouldNotify: updateShouldNotify,
          dispose: dispose,
          child: child,
        );
}

/// {@macro provider.proxyprovider}
class ProxyProvider2<T, T2, R> extends ProxyProvider0<R> {
  /// Initializes [key] for subclasses.
  ProxyProvider2({
    Key? key,
    Create<R>? create,
    required ProxyProviderBuilder2<T, T2, R> update,
    UpdateShouldNotify<R>? updateShouldNotify,
    Dispose<R>? dispose,
    bool? lazy,
    TransitionBuilder? builder,
    Widget? child,
  }) : super(
          key: key,
          lazy: lazy,
          builder: builder,
          create: create,
          update: (context, value) => update(
            context,
            Provider.of(context),
            Provider.of(context),
            value,
          ),
          updateShouldNotify: updateShouldNotify,
          dispose: dispose,
          child: child,
        );
}

/// {@macro provider.proxyprovider}
class ProxyProvider3<T, T2, T3, R> extends ProxyProvider0<R> {
  /// Initializes [key] for subclasses.
  ProxyProvider3({
    Key? key,
    Create<R>? create,
    required ProxyProviderBuilder3<T, T2, T3, R> update,
    UpdateShouldNotify<R>? updateShouldNotify,
    Dispose<R>? dispose,
    bool? lazy,
    TransitionBuilder? builder,
    Widget? child,
  }) : super(
          key: key,
          lazy: lazy,
          builder: builder,
          create: create,
          update: (context, value) => update(
            context,
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            value,
          ),
          updateShouldNotify: updateShouldNotify,
          dispose: dispose,
          child: child,
        );
}

/// {@macro provider.proxyprovider}
class ProxyProvider4<T, T2, T3, T4, R> extends ProxyProvider0<R> {
  /// Initializes [key] for subclasses.
  ProxyProvider4({
    Key? key,
    Create<R>? create,
    required ProxyProviderBuilder4<T, T2, T3, T4, R> update,
    UpdateShouldNotify<R>? updateShouldNotify,
    Dispose<R>? dispose,
    bool? lazy,
    TransitionBuilder? builder,
    Widget? child,
  }) : super(
          key: key,
          lazy: lazy,
          builder: builder,
          create: create,
          update: (context, value) => update(
            context,
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            value,
          ),
          updateShouldNotify: updateShouldNotify,
          dispose: dispose,
          child: child,
        );
}

/// {@macro provider.proxyprovider}
class ProxyProvider5<T, T2, T3, T4, T5, R> extends ProxyProvider0<R> {
  /// Initializes [key] for subclasses.
  ProxyProvider5({
    Key? key,
    Create<R>? create,
    required ProxyProviderBuilder5<T, T2, T3, T4, T5, R> update,
    UpdateShouldNotify<R>? updateShouldNotify,
    Dispose<R>? dispose,
    bool? lazy,
    TransitionBuilder? builder,
    Widget? child,
  }) : super(
          key: key,
          lazy: lazy,
          builder: builder,
          create: create,
          update: (context, value) => update(
            context,
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            value,
          ),
          updateShouldNotify: updateShouldNotify,
          dispose: dispose,
          child: child,
        );
}

/// {@macro provider.proxyprovider}
class ProxyProvider6<T, T2, T3, T4, T5, T6, R> extends ProxyProvider0<R> {
  /// Initializes [key] for subclasses.
  ProxyProvider6({
    Key? key,
    Create<R>? create,
    required ProxyProviderBuilder6<T, T2, T3, T4, T5, T6, R> update,
    UpdateShouldNotify<R>? updateShouldNotify,
    Dispose<R>? dispose,
    bool? lazy,
    TransitionBuilder? builder,
    Widget? child,
  }) : super(
          key: key,
          lazy: lazy,
          builder: builder,
          create: create,
          update: (context, value) => update(
            context,
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            value,
          ),
          updateShouldNotify: updateShouldNotify,
          dispose: dispose,
          child: child,
        );
}
