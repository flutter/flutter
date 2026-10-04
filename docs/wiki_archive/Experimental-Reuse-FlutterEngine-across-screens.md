_**Everything in this doc and linked from this doc is experimental. These details WILL change. Do not use these instructions or APIs in production code because we will break you.**_

# Re-use a FlutterEngine across screens

A `FlutterEngine` is responsible for executing Dart code, rendering a Flutter UI to a `FlutterView`, and connecting plugins to the core Flutter system. Each instance of `FlutterEngine` comes with a non-trivial "warm-up" time, which sets up a group of dedicated threads and other resources.

Due to the warm-up time of a `FlutterEngine` instance, developers may choose to cache one or more instances of `FlutterEngine`s and re-use those instances across different `Activity`s and/or `Fragment`s in their Android app. This document explains how to cache and re-use `FlutterEngine`s, as well as handle nuances when re-using those `FlutterEngine`s.

## Ensure Flutter is initialized

Flutter must be initialized before instantiating a single `FlutterEngine` instance. To ensure that Flutter is initialized, invoke the following methods before instantiating a `FlutterEngine`.

```java
FlutterMain.startInitialization(...);
FlutterMain.ensureInitializationComplete(...);
```

## Initializing FlutterEngines

A `FlutterEngine` must go through 2 steps to be fully initialized. First, an instance is instantiated. Second, the `FlutterEngine` is instructed to execute a Dart entrypoint, e.g., `main()`.

```java
// Instantiate a FlutterEngine.
FlutterEngine engine = new FlutterEngine(appContext);

// Define a DartEntrypoint
DartExecutor.DartEntrypoint entrypoint = new DartExecutor.createDefault();

// Execute the DartEntrypoint within the FlutterEngine.
engine.getDartExecutor().executeDartEntrypoint(entrypoint);
```

To cache one or more `FlutterEngine`s, store the initialized `FlutterEngine`s in a central place that you can access from your desired `Activity`s and `Fragment`s. You could choose to store these `FlutterEngine`s in your `Application` subclass, or you could store them in a statically accessible location of your choice. This choice is up to you, and should consider your specific application architecture and development practices.

## Dart entrypoint restrictions

A `FlutterEngine` can only execute a Dart entrypoint one time. Once a `FlutterEngine` has started executing Dart code, it will continue to execute that Dart code until the `FlutterEngine` is disposed. To re-use a `FlutterEngine` that needs to display different experiences at different times you will need to find an approach that accomplishes your goals without restarting Dart execution. Below are a couple options.

### Using a Navigator with routes

The `Navigator` widget in Flutter already has the ability to switch experiences at runtime. We call these different experiences `routes`, and your app is probably already using them. Typically, `routes` are controlled with Dart code, but the Android embedding also has a navigation system channel that allows you to `pushRoute(...)` and `popRoute(...)`. The `NavigationChannel` can be retrieved from a `FlutterEngine` instance.

```java
myFlutterEngine.getNavigationChannel().pushRoute("myPage");
```

You'll need to ensure that pushing a route at the desired time has the desired effect in your app. This approach of pushing routes may not work for all apps.

### Using method channels and a custom widget

Custom method channels offer a mechanism to implement your own solution for jumping between experiences. Method channels allow you to send any message you would like to your Flutter app, and then take whatever action you'd like.

Start by [setting up a method channel](https://docs.flutter.dev/development/platform-integration/platform-channels) with the navigation messages that you're interested in sending.

Once your method channel is setup, respond to your messages on the Flutter/Dart side by switching out your top-level widget, or by switching out any other widget in your hierarchy that makes sense for your use-case.

TODO(mattcarroll): add a code example here.

## Re-using FlutterEngines across screens

Re-using the same `FlutterEngine` across screens that are significantly separated should work as described above. However, developers must consider the possibility that one Flutter experience might show through to another. For example, consider an `Activity` that displays `flutterEngineA`, which then launches a native Android dialog, and that dialog is a `Fragment` that also displays `flutterEngineA`. This situation won't work because both the dialog and the underlying `Activity` are simultaneously visible and a single `FlutterEngine` can only render a single UI at a given moment.

When two Flutter experiences are shown back to back, you must carefully consider the possibility that Flutter might be instructed to show two different UIs at the same time. If such a situation occurs, you will need to switch your strategy to cache two `FlutterEngine`s instead of one, or you'll need to allow a new `FlutterEngine` to be instantiated for the second Flutter experience.
