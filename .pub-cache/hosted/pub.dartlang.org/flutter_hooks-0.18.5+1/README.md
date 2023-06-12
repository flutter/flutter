[English](https://github.com/rrousselGit/flutter_hooks/blob/master/README.md) | [Português](https://github.com/rrousselGit/flutter_hooks/blob/master/packages/flutter_hooks/resources/translations/pt_br/README.md)

[![Build](https://github.com/rrousselGit/flutter_hooks/workflows/Build/badge.svg)](https://github.com/rrousselGit/flutter_hooks/actions?query=workflow%3ABuild) [![codecov](https://codecov.io/gh/rrousselGit/flutter_hooks/branch/master/graph/badge.svg)](https://codecov.io/gh/rrousselGit/flutter_hooks) [![pub package](https://img.shields.io/pub/v/flutter_hooks.svg)](https://pub.dartlang.org/packages/flutter_hooks) [![pub package](https://img.shields.io/badge/Awesome-Flutter-blue.svg?longCache=true&style=flat-square)](https://github.com/Solido/awesome-flutter)
<a href="https://discord.gg/Bbumvej"><img src="https://img.shields.io/discord/765557403865186374.svg?logo=discord&color=blue" alt="Discord"></a>

<img src="https://raw.githubusercontent.com/rrousselGit/flutter_hooks/master/packages/flutter_hooks/flutter-hook.svg?sanitize=true" width="200">

# Flutter Hooks

A Flutter implementation of React hooks: https://medium.com/@dan_abramov/making-sense-of-react-hooks-fdbde8803889

Hooks are a new kind of object that manage the life-cycle of a `Widget`. They exist
for one reason: increase the code-sharing _between_ widgets by removing duplicates.

## Motivation

`StatefulWidget` suffers from a big problem: it is very difficult to reuse the
logic of say `initState` or `dispose`. An obvious example is `AnimationController`:

```dart
class Example extends StatefulWidget {
  final Duration duration;

  const Example({Key? key, required this.duration})
      : super(key: key);

  @override
  _ExampleState createState() => _ExampleState();
}

class _ExampleState extends State<Example> with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
  }

  @override
  void didUpdateWidget(Example oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _controller!.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _controller!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```

All widgets that desire to use an `AnimationController` will have to reimplement
almost all of this logic from scratch, which is of course undesired.

Dart mixins can partially solve this issue, but they suffer from other problems:

- A given mixin can only be used once per class.
- Mixins and the class share the same object.\
  This means that if two mixins define a variable under the same name, the result
  may vary between compilation fails to unknown behavior.

---

This library proposes a third solution:

```dart
class Example extends HookWidget {
  const Example({Key? key, required this.duration})
      : super(key: key);

  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(duration: duration);
    return Container();
  }
}
```

This code is functionally equivalent to the previous example. It still disposes the
`AnimationController` and still updates its `duration` when `Example.duration` changes.
But you're probably thinking:

> Where did all the logic go?

That logic has been moved into `useAnimationController`, a function included directly in
this library (see [Existing hooks](https://github.com/rrousselGit/flutter_hooks#existing-hooks)) - It is what we call a _Hook_.

Hooks are a new kind of object with some specificities:

- They can only be used in the `build` method of a widget that mix-in `Hooks`.
- The same hook can be reused arbitrarily many times.
  The following code defines two independent `AnimationController`, and they are
  correctly preserved when the widget rebuild.

  ```dart
  Widget build(BuildContext context) {
    final controller = useAnimationController();
    final controller2 = useAnimationController();
    return Container();
  }
  ```

- Hooks are entirely independent of each other and from the widget.\
  This means that they can easily be extracted into a package and published on
  [pub](https://pub.dartlang.org/) for others to use.

## Principle

Similar to `State`, hooks are stored in the `Element` of a `Widget`. However, instead
of having one `State`, the `Element` stores a `List<Hook>`. Then in order to use a `Hook`,
one must call `Hook.use`.

The hook returned by `use` is based on the number of times it has been called.
The first call returns the first hook; the second call returns the second hook,
the third call returns the third hook and so on.

If this idea is still unclear, a naive implementation of hooks could look as follows:

```dart
class HookElement extends Element {
  List<HookState> _hooks;
  int _hookIndex;

  T use<T>(Hook<T> hook) => _hooks[_hookIndex++].build(this);

  @override
  performRebuild() {
    _hookIndex = 0;
    super.performRebuild();
  }
}
```

For more explanation of how hooks are implemented, here's a great article about
how is was done in React: https://medium.com/@ryardley/react-hooks-not-magic-just-arrays-cd4f1857236e

## Rules

Due to hooks being obtained from their index, some rules must be respected:

### DO always prefix your hooks with `use`:

```dart
Widget build(BuildContext context) {
  // starts with `use`, good name
  useMyHook();
  // doesn't start with `use`, could confuse people into thinking that this isn't a hook
  myHook();
  // ....
}
```

### DO call hooks unconditionally

```dart
Widget build(BuildContext context) {
  useMyHook();
  // ....
}
```

### DON'T wrap `use` into a condition

```dart
Widget build(BuildContext context) {
  if (condition) {
    useMyHook();
  }
  // ....
}
```

---

### About hot-reload

Since hooks are obtained from their index, one may think that hot-reloads while refactoring will break the application.

But worry not, a `HookWidget` overrides the default hot-reload behavior to work with hooks. Still, there are some situations in which the state of a Hook may be reset.

Consider the following list of hooks:

```dart
useA();
useB(0);
useC();
```

Then consider that we edited the parameter of `HookB` after performing a hot-reload:

```dart
useA();
useB(42);
useC();
```

Here everything works fine and all hooks maintain their state.

Now consider that we removed `HookB`. We now have:

```dart
useA();
useC();
```

In this situation, `HookA` maintains its state but `HookC` gets hard reset.
This happens because, when a hot-reload is performed after refactoring, all hooks _after_ the first line impacted are disposed of.
So, since `HookC` was placed _after_ `HookB`, it will be disposed.

## How to create a hook

There are two ways to create a hook:

- A function

  Functions are by far the most common way to write hooks. Thanks to hooks being
  composable by nature, a function will be able to combine other hooks to create
  a more complex custom hook. By convention, these functions will be prefixed by `use`.

  The following code defines a custom hook that creates a variable and logs its value
  to the console whenever the value changes:

  ```dart
  ValueNotifier<T> useLoggedState<T>([T initialData]) {
    final result = useState<T>(initialData);
    useValueChanged(result.value, (_, __) {
      print(result.value);
    });
    return result;
  }
  ```

- A class

  When a hook becomes too complex, it is possible to convert it into a class that extends `Hook` - which can then be used using `Hook.use`.\
  As a class, the hook will look very similar to a `State` class and have access to widget
  life-cycle and methods such as `initHook`, `dispose` and `setState`.

  It is usually good practice to hide the class under a function as such:

  ```dart
  Result useMyHook() {
    return use(const _TimeAlive());
  }
  ```

  The following code defines a hook that prints the total time a `State` has been alive on its dispose.

  ```dart
  class _TimeAlive extends Hook<void> {
    const _TimeAlive();

    @override
    _TimeAliveState createState() => _TimeAliveState();
  }

  class _TimeAliveState extends HookState<void, _TimeAlive> {
    DateTime start;

    @override
    void initHook() {
      super.initHook();
      start = DateTime.now();
    }

    @override
    void build(BuildContext context) {}

    @override
    void dispose() {
      print(DateTime.now().difference(start));
      super.dispose();
    }
  }
  ```

## Existing hooks

Flutter_Hooks already comes with a list of reusable hooks which are divided into different kinds:

### Primitives

A set of low-level hooks that interact with the different life-cycles of a widget

| Name                                                                                                              | Description                                                         |
| ----------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| [useEffect](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useEffect.html)             | Useful for side-effects and optionally canceling them.              |
| [useState](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useState.html)               | Creates a variable and subscribes to it.                            |
| [useMemoized](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useMemoized.html)         | Caches the instance of a complex object.                            |
| [useRef](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useRef.html)                   | Creates an object that contains a single mutable property.          |
| [useCallback](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useCallback.html)         | Caches a function instance.                                         |
| [useContext](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useContext.html)           | Obtains the `BuildContext` of the building `HookWidget`.            |
| [useValueChanged](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useValueChanged.html) | Watches a value and triggers a callback whenever its value changed. |

### Object-binding

This category of hooks the manipulation of existing Flutter/Dart objects with hooks.
They will take care of creating/updating/disposing an object.

#### dart:async related hooks:

| Name                                                                                                                      | Description                                                                   |
| ------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| [useStream](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useStream.html)                     | Subscribes to a `Stream` and returns its current state as an `AsyncSnapshot`. |
| [useStreamController](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useStreamController.html) | Creates a `StreamController` which will automatically be disposed.            |
| [useFuture](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useFuture.html)                     | Subscribes to a `Future` and returns its current state as an `AsyncSnapshot`. |

#### Animation related hooks:

| Name                                                                                                                              | Description                                                            |
| --------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| [useSingleTickerProvider](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useSingleTickerProvider.html) | Creates a single usage `TickerProvider`.                               |
| [useAnimationController](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useAnimationController.html)   | Creates an `AnimationController` which will be automatically disposed. |
| [useAnimation](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useAnimation.html)                       | Subscribes to an `Animation` and returns its value.                    |

#### Listenable related hooks:

| Name                                                                                                                          | Description                                                                                         |
| ----------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| [useListenable](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useListenable.html)                 | Subscribes to a `Listenable` and marks the widget as needing build whenever the listener is called. |
| [useListenableSelector](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useListenableSelector.html) | Similar to `useListenable`, but allows filtering UI rebuilds                                        |
| [useValueNotifier](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useValueNotifier.html)           | Creates a `ValueNotifier` which will be automatically disposed.                                     |
| [useValueListenable](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useValueListenable.html)       | Subscribes to a `ValueListenable` and return its value.                                             |

#### Misc hooks:

A series of hooks with no particular theme.

| Name                                                                                                                                        | Description                                                                |
| ------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------- |
| [useReducer](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useReducer.html)                                     | An alternative to `useState` for more complex states.                      |
| [usePrevious](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/usePrevious.html)                                   | Returns the previous argument called to [usePrevious].                     |
| [useTextEditingController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useTextEditingController-constant.html)         | Creates a `TextEditingController`.                                         |
| [useFocusNode](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useFocusNode.html)                                 | Creates a `FocusNode`.                                                     |
| [useTabController](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useTabController.html)                         | Creates and disposes a `TabController`.                                    |
| [useScrollController](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useScrollController.html)                   | Creates and disposes a `ScrollController`.                                 |
| [usePageController](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/usePageController.html)                       | Creates and disposes a `PageController`.                                   |
| [useAppLifecycleState](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useAppLifecycleState.html)                 | Returns the current `AppLifecycleState` and rebuilds the widget on change. |
| [useOnAppLifecycleStateChange](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useOnAppLifecycleStateChange.html) | Listens to `AppLifecycleState` changes and triggers a callback on change.  |
| [useTransformationController](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useTransformationController.html)   | Creates and disposes a `TransformationController`.                         |
| [useIsMounted](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useIsMounted.html)                                 | An equivalent to `State.mounted` for hooks.                                |
| [useAutomaticKeepAlive](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useAutomaticKeepAlive.html)               | An equivalent to the `AutomaticKeepAlive` widget for hooks.                |
| [useOnPlatformBrightnessChange](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useOnPlatformBrightnessChange.html) | Listens to platform `Brightness` changes and triggers a callback on change.|

## Contributions

Contributions are welcomed!

If you feel that a hook is missing, feel free to open a pull-request.

For a custom-hook to be merged, you will need to do the following:

- Describe the use-case.

  Open an issue explaining why we need this hook, how to use it, ...
  This is important as a hook will not get merged if the hook doesn't appeal to
  a large number of people.

  If your hook is rejected, don't worry! A rejection doesn't mean that it won't
  be merged later in the future if more people show interest in it.
  In the mean-time, feel free to publish your hook as a package on https://pub.dev.

- Write tests for your hook

  A hook will not be merged unless fully tested to avoid inadvertently breaking it
  in the future.

- Add it to the README and write documentation for it.

## Sponsors

<p align="center">
  <a href="https://raw.githubusercontent.com/rrousselGit/freezed/master/sponsorkit/sponsors.svg">
    <img src='https://raw.githubusercontent.com/rrousselGit/freezed/master/sponsorkit/sponsors.svg'/>
  </a>
</p>
