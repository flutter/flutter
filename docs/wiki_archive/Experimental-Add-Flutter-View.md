_**Everything in this doc and linked from this doc is experimental. These details WILL change. Do not use these instructions or APIs in production code because we will break you.**_

# Add a Flutter View

Flutter can be added to an Android app as a single `View` in an `Activity`'s `View` hierarchy.

Before adding Flutter as a single `View`, you should consider if it is possible to add Flutter as a `Fragment` to reduce your development burden.

* [How to use a `FlutterFragment`](Experimental-Add-Flutter-Fragment-ViewPager.md)

If you really need to add Flutter as a single `View` then do the following.

## How to use FlutterView

### Create and start a FlutterEngine

Create and start a `FlutterEngine` by following the appropriate instructions. See the [FlutterEngine page](Experimental-Reuse-FlutterEngine-across-screens.md)

### Create a FlutterView and add to layout

```java
// Instantiate a new FlutterView.
FlutterView flutterView = new FlutterView(this);

// Add your FlutterView wherever you'd like. In this case we add
// the FlutterView to a FrameLayout.
FrameLayout frameLayout = findViewById(R.id.framelayout);
frameLayout.addView(flutterView);
```

Your `FlutterView` will not render anything at this point because it is not backed by any particular Flutter app.

### Attach your FlutterView to your FlutterEngine

```java
flutterView.attachToFlutterEngine(flutterEngine);
```

At this point you should see your Flutter UI rendering to your `FlutterView`, and touch interaction should work.

### Create and configure platform plugin

TODO(mattcarroll): update this info about the platform plugin

Fundamental communication between the Android platform and your Flutter app takes place over a `MethodChannel` with the name `"flutter/platform"`. For example, Android's `onPostResume()` call must be forwarded over the `flutterPlatformChannel` with the message `"AppLifecycleState.resumed"`.

```java
  platformPlugin = new PlatformPlugin(activity);
  MethodChannel flutterPlatformChannel = new MethodChannel(
    flutterEngine.getDartExecutor(),
    "flutter/platform",
    JSONMethodCodec.INSTANCE
  );
  flutterPlatformChannel.setMethodCallHandler(platformPlugin);
```

### Add accessibility support

TODO(mattcarroll)

### Add support for plugins

TODO(mattcarroll)

### Handling orientation change

TODO(mattcarroll)