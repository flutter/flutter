## 0.18.5+1

Update links to the repository

## 0.18.5

- Added `useListenableSelector`, similar to `useListenable`, for listening to a
`Listenable` but rebuilding the widget only if a certain data has changed (thanks to @ronnieeeeee)
- Added `useAutomaticKeepAlive` (thanks to @DevNico)
- Added `usePlatformBrightness` and `useOnPlatformBrightnessChange` to interact with platform `Brightness` (thanks to @AhmedLSayed9)

## 0.18.4

Upgrade to Flutter 3.0.0

## 0.18.3

Added `onKeyEvent` to `useFocusNode` (thanks to @kdelorey)

## 0.18.2+1

Improved the documentation (thanks to @Renni771)

## 0.18.2

- Allow null in `useListenable`

## 0.18.1

- Added `useTransformationController`, to create a `TransformationController` (thanks to @shrouxm)
- Added `useAppLifecycleState` and `useOnAppLifecycleStateChange` to interact with `AppLifecycleState` (thanks to @francipvb)

## 0.18.0

- **Breaking**: `useRef` now receive an initial value as parameter.
  To migrate, you can change:

  ```dart
  ObjectRef<int> ref = useRef<int>();
  ```

  to:

  ```dart
  ObjectRef<int?> ref = useRef<int?>(null);
  ```

- Updated `useStream`/`useFuture` to match the behavior of `StreamBuilder`/`FutureBuilder` regarding initial values.

- Added a `reverseDuration` parameter to `useAnimationController`

## 0.17.0

- `useFuture`/`useStream`'s `AsynsSnapshot` now correctly expose the StackTrace when there is an error.
- added `useRef` and `useCallback`, similar to the React equivalents.
- `initialData` of `useStream` and `useFuture` is now optional.

## 0.16.0

Stable null-safety release

## 0.16.0-nullsafety.0

Migrated flutter_hooks to null-safety (special thanks to @DevNico for the help!)

## 0.15.0

- Added `usePageController` to create a `PageController`

## 0.14.1

- Increased the minimum version of the Flutter SDK required to match changes on
  `useFocusNode`

  The minimum required is now 1.20.0 (the stable channel is at 1.20.4)

## 0.14.0

- added all `FocusNode` parameters to `useFocusNode`
- Fixed a bug where on hot-reload, a `HookWidget` could potentially not rebuild
- Allow hooks to integrate with the devtool using the `Diagnosticable` API, and
  implement it for all built-in hooks.

## 0.13.1

- `useIsMounted` now returns a function instead of a callable class.

## 0.13.0

- Added `useIsMounted` to determine whether a widget was destroyed or not (thanks to @davidmartos96)

## 0.12.0

- Added `useScrollController` to create a `ScrollController`
- added `useTabController` to create a `TabController` (thanks to @Albert221)

## 0.11.0

**Breaking change**:

- Removed `HookState.didBuild`.  
  If you still need it, use `addPostFrameCallback` or `Future.microtask`.

**Non-breaking changes**:

- Fix a bug where the order in which hooks are disposed is incorrect.
- It is now allowed to rebuild a `HookWidget` with more/less hooks than previously.
  Example:

  ```dart
  Widget build(context) {
    useSomething();
    if (condition) {
      return Container();
    }
    useSomething()
    return Container();
  }
  ```

- Deprecated `Hook.use` in favor of a new short-hand `use`.
  Before:

  ```dart
  Hook.use(MyHook());
  ```

  After:

  ```dart
  use(MyHook());
  ```

## 0.10.0

**Breaking change**:

- The order in which hooks are disposed has been reversed.

  Consider:

  ```dart
  useSomething();
  useSomethingElse();
  ```

  Before, the `useSomething` was disposed before `useSomethingElse`.
  Now, `useSomethingElse` is disposed before the `useSomething`.

  The reason for this change is for cases like:

  ```dart
  // Creates an AnimationController
  final animationController = useAnimationController();
  // Immediately listen to the AnimationController
  useListenable(animationController);
  ```

  Before, when the widget was disposed, this caused an exception as
  `useListenable` unsubscribed to the `AnimationController` _after_ its `dispose`
  method was called.

**Non-breaking changes**:

- Added a way for hooks to potentially abort a widget rebuild.
- Added `StatefulHookWidget`, a `StatefulWidget` that can use hooks inside its `build` method.

## 0.9.0

- Added a `deactivate` life-cycle to `HookState`

## 0.8.0+1

- Fixed link to "Existing hooks" in `README.md`.

## 0.8.0:

Added `useFocusNode`

## 0.7.0:

- Added `useTextEditingController`, thanks to simolus3!

## 0.6.1:

- Added `useReassemble` hook, thanks to @SahandAkbarzadeh

## 0.6.0:

- Make hooks compatible with newer flutter stable version 1.7.8-hotfix.2.

## 0.4.0:

- Make hooks compatible with newer flutter version. (see https://groups.google.com/forum/#!topic/flutter-announce/hp1RNIgej38)

## 0.3.0:

- NEW: `usePrevious`, a hook that returns the previous argument is received.
- NEW: it is now impossible to call `inheritFromWidgetOfExactType` inside `initHook` of hooks. This forces authors to handle value updates.
- FIX: use List<Object> instead of List<dynamic> for keys. This fixes `implicit-dynamic` rule mistakenly reporting errors.
- NEW: Hooks are now visible on `HookElement` through `debugHooks` in development, for testing purposes.
- NEW: If a widget throws on the first build or after a hot-reload, next rebuilds can still add/edit hooks until one `build` finishes entirely.
- NEW: new life-cycle available on `HookState`: `didBuild`.
  This life-cycle is called synchronously right after `build` method of `HookWidget` finished.
- NEW: new `reassemble` life-cycle on `HookState`. It is equivalent to `State.reassemble` of statefulwidgets.
- NEW: `useStream` and `useFuture` now have an optional `preserveState` flag.
  This toggle how these hooks behave when changing the stream/future:
  If true (default) they keep the previous value, else they reset to initialState.

## 0.2.1:

- NEW: `useValueNotifier`, which creates a `ValueNotifier` similarly to `useState`. But without listening it.
  This can be useful to have a more granular rebuild when combined to `useValueListenable`.
- NEW: `useContext`, which exposes the `BuildContext` of the currently building `HookWidget`.

## 0.2.0:

- Made all existing hooks as static functions, and removed `HookContext`. The migration is as followed:

```dart
Widget build(HookContext context) {
    final state = context.useState(0);
}
```

becomes:

```dart
Widget build(BuildContext context) {
    final state = useState(0);
}
```

- Introduced keys for hooks and applied them to hooks where it makes sense.
- Added `useReducer` for complex state. It is similar to `useState` but is being managed by a `Reducer` and can only be changed by dispatching an action.
- fixes a bug where hot-reload without using hooks thrown an exception

## 0.1.0:

- `useMemoized` callback doesn't take the previous value anymore (to match React API)
  Use `useValueChanged` instead.
- Introduced `useEffect` and `useStreamController`
- fixed a bug where hot-reload while reordering/adding hooks did not work properly
- improved readme

## 0.0.1:

Added a few common hooks:

- `useStream`
- `useFuture`
- `useAnimationController`
- `useSingleTickerProvider`
- `useListenable`
- `useValueListenable`
- `useAnimation`

## 0.0.0:

- initial release
