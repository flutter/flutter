Flutter's v2 Android embedding includes reflection code that should find and register all plugins listed in your `pubspec.yaml` file without any intervention on your part. If your desired plugins are not registered automatically, please file an issue.

### Partial plugin registration

To prevent Flutter from registering all plugins and instead register only specific plugins of your choosing, do the following.

First, construct a `FlutterEngine` either as a [cached `FlutterEngine`](https://flutter.dev/docs/development/add-to-app/android/add-flutter-screen#step-3-optional-use-a-cached-flutterengine), or by overriding `provideFlutterEngine()` in [`FlutterActivity`](https://api.flutter.dev/javadoc/io/flutter/embedding/android/FlutterActivity.html#provideFlutterEngine-android.content.Context-) or [`FlutterFragment`](https://api.flutter.dev/javadoc/io/flutter/embedding/android/FlutterFragment.html#provideFlutterEngine-android.content.Context-) such that the `FlutterEngine` instance doesn't automatically register plugins.

```java
FlutterEngine flutterEngine = new FlutterEngine(
  context,
  FlutterLoader.getInstance(),
  new FlutterJNI(),
  dartVmArgs, // or an empty array if no args needed
  false // this arg instructs the FlutterEngine NOT to register plugins automatically
);
```

Second, register the plugins that you want. If you overrode `provideFlutterEngine()` in `FlutterActivity` or `FlutterFragment` then override `configureFlutterEngine()` to add plugins:

```java
public void configureFlutterEngine(FlutterEngine engine) {
  // The ShimPluginRegistry is how the v2 embedding works with v1 plugins.
  ShimPluginRegistry shimPluginRegistry = new ShimPluginRegistry(
    flutterEngine,
    new PlatformViewsController()
  );

  // Add any v1 plugins to the shim
  // MyV1Plugin.registerWith(
  //   shimPluginRegistry.registrarFor("com.my.package.MyV1Plugin")
  // );

  // Add any v2 plugins that you want
  // engine.getPlugins().add(new MyPlugin());
}
```

If you went with the cached `FlutterEngine` approach instead of `FlutterActivity` and `FlutterFragment` method overrides, then you can add plugins whenever you'd like. You can even add them immediately after instantiating your `FlutterEngine`. However, be advised that some v1 plugins expect an `Activity` to be available immediately upon registration. This will not be the case unless you add plugins in `configureFlutterEngine()` as shown earlier.

```java
// Instantiate cached FlutterEngine.
FlutterEngine flutterEngine = new FlutterEngine(
  context,
  FlutterLoader.getInstance(),
  new FlutterJNI(),
  dartVmArgs, // or an empty array if no args needed
  false // this arg instructs the FlutterEngine NOT to register plugins automatically
);

// Immediately add plugins to the cached FlutterEngine.
// The ShimPluginRegistry is how the v2 embedding works with v1 plugins.
ShimPluginRegistry shimPluginRegistry = new ShimPluginRegistry(
  flutterEngine,
  new PlatformViewsController()
);

// Add any v1 plugins to the shim
// MyV1Plugin.registerWith(
//   shimPluginRegistry.registrarFor("com.my.package.MyV1Plugin")
// );

// Add any v2 plugins that you want
// engine.getPlugins().add(new MyPlugin());
```