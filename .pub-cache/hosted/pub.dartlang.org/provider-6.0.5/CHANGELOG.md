# 6.0.5

- Fix broken links on pub.dev

# 6.0.4

Fix typos and broken links in the documentation

# 6.0.3

- fix late initialization error when using `debugPrintRebuildDirtyWidgets`
- slightly reduced the binary size of release mode applications using provider
- Fix typos in the error message of ProviderNotFoundException
- improve performances for reading providers (thanks to @jiahaog)

# 6.0.2

Added error details for provider that threw during the creation (thanks to @jmewes)

# 6.0.1

Removed the assert that prevented from using `ChangeNotifierProvider`
with notifiers that already had listeners.

# 6.0.0

- **Breaking**: It is no longer possible to define providers where their
  only difference is the nullability of the exposed value:

  ```dart
  MultiProvider(
    providers: [
      Provider<Model>(...),
      Provider<Model?>(...)
    ]
  )
  ```

  Before, when defining those providers, doing `context.watch<Model>`
  vs `context.watch<Model?>` would point to a different provider.
  Now, both will always point to the deepest provider (in this example `Provider<Model?>`).

  That fixes issues where a common developer mistake is to define a provider
  as `Model?` but try to read it as `Model`. Previously, that would give a `ProviderNotFoundException`.
  Now, this will correctly resolve the value.

  That also helps large codebase migrate to null-safety progressively, as
  they would temporarily contain both null-safe and unsound code. Previously,
  unsound code would be unable to read a provider defined as `Provider<Model?>`,
  as `Model?` is not a valid syntax. With this change, this is now feasible.

- It is now possible to read a provider without throwing a `ProviderNotFoundException`
  if the provider is optional.

  To do so, when calling `context.watch`/`context.read`, make the generic type
  nullable. Such that instead of:

  ```dart
  context.watch<Model>()
  ```

  which will throw a `ProviderNotFoundException` if no matching providers are found,
  do:

  ```dart
  context.watch<Model?>()
  ```

  which will try to obtain a matching provider. But if none are found,
  `null` will be returned instead of throwing.

# 6.0.0-dev

- **Breaking**: It is no longer possible to define providers where their
  only difference is the nullability of the exposed value:

  ```dart
  MultiProvider(
    providers: [
      Provider<Model>(...),
      Provider<Model?>(...)
    ]
  )
  ```

  Before, when defining those providers, doing `context.watch<Model>`
  vs `context.watch<Model?>` would point to a different provider.
  Now, both will always point to the deepest provider (in this example `Provider<Model?>`).

  That fixes issues where a common developer mistake is to define a provider
  as `Model?` but try to read it as `Model`. Previously, that would give a `ProviderNotFoundException`.
  Now, this will correctly resolve the value.

  That also helps large codebase migrate to null-safety progressively, as
  they would temporarily contain both null-safe and unsound code. Previously,
  unsound code would be unable to read a provider defined as `Provider<Model?>`,
  as `Model?` is not a valid syntax. With this change, this is now feasible.

- It is now possible to read a provider without throwing a `ProviderNotFoundException`
  if the provider is optional.

  To do so, when calling `context.watch`/`context.read`, make the generic type
  nullable. Such that instead of:

  ```dart
  context.watch<Model>()
  ```

  which will throw a `ProviderNotFoundException` if no matching providers are found,
  do:

  ```dart
  context.watch<Model?>()
  ```

  which will try to obtain a matching provider. But if none are found,
  `null` will be returned instead of throwing.

# 5.0.0

- Stable, null-safe release.
- pre-release of the mechanism for state-inspection using the Flutter devtool
- Updated oudated doc in `StreamProvider`

# 5.0.0-nullsafety.5

Fixed an issue where providers with an `update` parameter in sound null-safety mode could throw null exceptions.

# 5.0.0-nullsafety.4

- Upgraded `nested` dependency to 1.0.0 and `collection` to 1.15.0

# 5.0.0-nullsafety.3

- Improved the error message of `ProviderNotFoundException` to mention hot-reload. (#595)
- Removed the asserts that prevented `ChangeNotifier`s in `ChangeNotifierProvider()`
  to have listeners (#596)
- Removed the opinionated asserts in `context.watch`/`context.read`
  that prevented them to be used inside specific conditions (#585)

# 5.0.0-nullsafety.2

- Improved the error message when an exception is thrown inside `create` of a provider`

# 5.0.0-nullsafety.1

- Reintroduced `ValueListenableProvider.value` (the default constructor is still removed).

# 5.0.0-nullsafety.0

Migrated Provider to non-nullable types:

- `initialData` for both `FutureProvider` and `StreamProvider` is now required.

  To migrate, what used to be:

  ```dart
  FutureProvider<int>(
    create: (context) => Future.value(42),
    child: MyApp(),
  )

  Widget build(BuildContext context) {
    final value = context.watch<int>();
    return Text('$value');
  }
  ```

  is now:

  ```dart
  FutureProvider<int?>(
    initialValue: null,
    create: (context) => Future.value(42),
    child: MyApp(),
  )

  Widget build(BuildContext context) {
    // be sure to specify the ? in watch<int?>
    final value = context.watch<int?>();
    return Text('$value');
  }
  ```

- `ValueListenableProvider` is removed

  To migrate, you can instead use `Provider` combined with `ValueListenableBuilder`:

  ```dart
  ValueListenableBuilder<int>(
    valueListenable: myValueListenable,
    builder: (context, value, _) {
      return Provider<int>.value(
        value: value,
        child: MyApp(),
      );
    }
  )
  ```

# 4.3.3

- Improved the error message of `ProviderNotFoundException` to mention hot-reload. (#595)
- Removed the asserts that prevented `ChangeNotifier`s in `ChangeNotifierProvider()`
  to have listeners (#596)
- Removed the opinionated asserts in `context.watch`/`context.read`
  that prevented them to be used inside specific conditions (#585)

# 4.3.2+4

`ValueListenableProvider` is no-longer deprecated.
Only its default constructor is deprecated (the `.value` constructor is kept)

# 4.3.2+3

Marked `ValueListenableProvider` as deprecated

# 4.3.2+2

Improve pub score

# 4.3.2+1

Documentation improvement about the `builder` parameter of Providers.

# 4.3.2

Fixed typo in the error message of `ProviderNotFoundException`

# 4.3.1

- Fixed a bug where hot-reload forced all lazy-loaded providers to be computed.

# 4.3.0

- Added `ReassembleHandler` interface, for objects to implement so that
  `provider` let them handle hot-reload.

# 4.2.0

- Added a `builder` parameter on `MultiProvider` (thanks to @joaomarcos96):

  ```dart
  MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (ct) => Counter()),
    ],
    builder: (ctx, child) {
      final counter = ctx.watch<Counter>();
      return Text('${counter.count}');
    },
  );
  ```

# 4.1.3+1

- Small Readme changes

# 4.1.3

- Improved the error message of `ProviderNotFoundException` with instructions
  that better fit what is usually the problem.

- Added documentation on why `context.read` should not be called inside `build`,
  and what to do instead.

- Improved the performances of `context.select`, by not calling the selectors
  when the provider changes if the widgets listening to the value are already
  needing build.

- Fixes a bug where `context.watch` couldn't be called inside `ListView`/`LayoutBuilder`

- Improve the error message when trying to use `context.select` inside `ListView.builder`

- Improve the error message when calling `context.read/watch/select`/`Provider.of` with
  a `context` that is `null`.

# 4.1.2

- Loosened the constraint on Flutter's version to be compatible with `beta` channel.

# 4.1.1

- Fixes an "aspect" leak with `context.select`, leading to memory leaks and unnecessary rebuilds
- Fixes the `builder` parameter of providers not working (thanks to @passsy)

# 4.1.0

- Now requires:
  - Flutter >= 1.6.0
  - Dart >= 2.7.0
- Added a `select` extension on `BuildContext`. It behaves similarly to `Selector`,
  but is a lot less verbose to write:

  With Selector:

  ```dart
  Widget build(BuildContext context) {
    return Selector<Person, String>(
      selector: (_, p) => p.name,
      builder: (_, name, __) {
        return Text(name);
      },
    ),
  }
  ```

  VS with the new `select` extension:

  ```dart
  Widget build(BuildContext context) {
    final name = context.select((Person p) => p.name);
    return Text(name);
  }
  ```

- Added `builder` on the different providers.
  This parameter simplifies situations where we need a [BuildContext] that
  can access the new provider.

  As such, instead of:

  ```dart
  Provider(
    create: (_) => Something(),
    child: Builder(
      builder: (context) {
        final name = context.select((Something s) => s.name);
        return Text(name);
      },
    ),
  )
  ```

  we can write:

  ```dart
  Provider(
    create: (_) => Something(),
    builder: (context, child) {
      final name = context.select((Something s) => s.name);
      return Text(name);
    },
  )
  ```

  The behavior is the same. This is only a small syntax sugar.

- Added a two extensions on [BuildContext], to slightly reduce the boilerplate:

  | before                                   | after               |
  | ---------------------------------------- | ------------------- |
  | `Provider.of<T>(context, listen: false)` | `context.read<T>()` |
  | `Provider.of<T>(context)`                | `context.watch<T>`  |

- Added a `Locator` typedef and an extension on [BuildContext], to help with
  being able to read providers from a class that doesn't depend on Flutter.

# 4.0.5+1

- Added Português translation of the readme file (thanks to @robsonsilv4)

# 4.0.5

- Improve error message when forgetting to pass a `child` when using a provider outside of `MultiProvider` (thanks to @felangel)

# 4.0.4

- Update the ProviderNotFoundException to remove outdated solution. (thanks @augustinreille)

# 4.0.3

- improved error message when `Provider.of` is called without specifying
  `listen: false` outside of the widget tree.

# 4.0.2

- fix `Provider.of` returning the previous value instead of the new value
  if called inside `didChangeDependencies`.
- fixed an issue where `update` was unnecessarily called.

# 4.0.1

- stable release of 4.0.0-hotfix+1
- fix some typos

# 4.0.0-hotfix.1

- removed the inference of the `listen` flag of `Provider.of` in favor of an exception in debug mode if `listen` is true when it shouldn't.

  This is because it caused a critical performance issue. See https://github.com/rrousselGit/provider/issues/305

# 4.0.0

- `Selector` now deeply compares collections by default, and offers a `shouldRebuild`
  to customize the rebuild behavior.
- renamed `ProviderNotFoundError` to `ProviderNotFoundException`.
  This allows calling `Provider.of` inside a `try/catch` without triggering a
  warning.
- update provider to work with Flutter 1.12.1
- The creation and listening of objects using providers is now performed lazily.
  This means that objects are created the first time the value is read instead of
  the first time the provider is mounted.
- ~~The `listen` argument of `Provider.of` is now automatically inferred.
  It is no longer necessary to pass `listen: false` when calling `Provider.of`
  outside of the widget tree.~~ removed by 4.0.0-hotfix. See https://github.com/rrousselGit/provider/issues/305
- renamed `initialBuilder` & `builder` of `*ProxyProvider` to `create` & `update`
- renamed `builder` of `*Provider` to `create`
- added a `*ProxyProvider0` variant

# 3.2.0

- Deprecated "builder" of providers in favor to "create"
- Deprecated "initialBuilder"/"builder" of proxy providers in favor of respectively
  "create" and "update"

# 3.1.0

- Added `Selector`, similar to `Consumer` but can filter unneeded updates
- improved the overall documentation
- fixed a bug where `ChangeNotifierProvider.value` didn't update dependents
  when the `ChangeNotifier` instance changed.
- `Consumer` can now be used inside `MultiProvider`

  ```dart
  MultiProvider(
    providers: [
      Provider(builder: (_) => Foo()),
      Consumer<Foo>(
        builder: (context, foo, child) =>
          Provider.value(value: foo.bar, child: child),
      )
    ],
  );
  ```

# 3.0.0

## breaking (see the readme for migration steps)

- `Provider` now throws if used with a `Listenable`/`Stream`. This can be disabled by setting
  `Provider.debugCheckInvalidValueType` to `null`.
- The default constructor of `StreamProvider` has now builds a `Stream`
  instead of `StreamController`. The previous behavior has been moved to `StreamProvider.controller`.
- All `XXProvider.value` constructors now use `value` as parameter name.
- Added `FutureProvider`, which takes a future and updates dependents when the future completes.
- Providers can no longer be instantiated using `const` constructors.

## non-breaking

- Added `ProxyProvider`, `ListenableProxyProvider`, and `ChangeNotifierProxyProvider`.
  These providers allows building values that depends on other providers,
  without loosing reactivity or manually handling the state.
- Added `DelegateWidget` and a few related classes to help building custom providers.
- Exposed the internal generic `InheritedWidget` to help building custom providers.

# 2.0.1

- fix a bug where `ListenableProvider.value`/`ChangeNotifierProvider.value`
  /`StreamProvider.value`/`ValueListenableProvider.value` subscribed/unsubscribed
  to their respective object too often
- fix a bug where `ListenableProvider.value`/`ChangeNotifierProvider.value` may
  rebuild too often or skip some.

# 2.0.0

- `Consumer` now takes an optional `child` argument for optimization purposes.
- merged `Provider` and `StatefulProvider`
- added a "builder" constructor to `ValueListenableProvider`
- normalized providers constructors such that the default constructor is a "builder",
  and offer a `value` named constructor.

# 1.6.1

- `Provider.of<T>` now crashes with a `ProviderNotFoundException` when no `Provider<T>`
  are found in the ancestors of the context used.

# 1.6.0

- new: `ChangeNotifierProvider`, similar to scoped_model that exposes `ChangeNotifer` subclass and
  rebuilds dependents only when `notifyListeners` is called.
- new: `ValueListenableProvider`, a provider that rebuilds whenever the value passed
  to a `ValueNotifier` change.

# 1.5.0

- new: Add `Consumer` with up to 6 parameters.
- new: `MultiProvider`, a provider that makes a tree of provider more readable
- new: `StreamProvider`, a stream that exposes to its descendants the current value of a `Stream`.

# 1.4.0

- Reintroduced `StatefulProvider` with a modified prototype.
  The second argument of `valueBuilder` and `didChangeDependencies` have been removed.
  And `valueBuilder` is now called only once for the whole life-cycle of `StatefulProvider`.

# 1.3.0

- Added `Consumer`, useful when we need to both expose and consume a value simultaneously.

# 1.2.0

- Added: `HookProvider`, a `Provider` that creates its value from a `Hook`.
- Deprecated `StatefulProvider`. Either make a `StatefulWidget` or use `HookProvider`.
- Integrated the widget inspector, so that `Provider` widget shows the current value.

# 1.1.1

- add `didChangeDependencies` callback to allow updating the value based on an `InheritedWidget`
- add `updateShouldNotify` method to both `Provider` and `StatefulProvider`

# 1.1.0

- `onDispose` has been added to `StatefulProvider`
- [BuildContext] is now passed to `valueBuilder` callback

[buildcontext]: https://api.flutter.dev/flutter/widgets/BuildContext-class.html
