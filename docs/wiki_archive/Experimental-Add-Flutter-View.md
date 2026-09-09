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

### Hook up lifecycle events

Flutter's internal lifecycle state (which controls rendering, pauses/resumes execution, and notifies Dart code of lifecycle changes) is managed by the engine's `LifecycleChannel`. When using `FlutterView` directly without `FlutterActivity` or `FlutterFragment`, you **must** forward Android lifecycle events and window focus changes to the `LifecycleChannel` manually.

In your hosting `Activity` or `Fragment`, call the corresponding `LifecycleChannel` APIs:

```java
@Override
protected void onResume() {
  super.onResume();
  // Tell Flutter that the app is resumed.
  flutterEngine.getLifecycleChannel().appIsResumed();
}

@Override
protected void onPause() {
  super.onPause();
  // Tell Flutter that the app is inactive (about to be paused).
  flutterEngine.getLifecycleChannel().appIsInactive();
}

@Override
protected void onStop() {
  super.onStop();
  // Tell Flutter that the app is paused.
  flutterEngine.getLifecycleChannel().appIsPaused();
}

@Override
protected void onDestroy() {
  super.onDestroy();
  // Tell Flutter that the host is detached from the engine.
  flutterEngine.getLifecycleChannel().appIsDetached();
  // Detach the view from the engine to prevent memory leaks.
  flutterView.detachFromFlutterEngine();
  // Clean up the PlatformPlugin.
  if (platformPlugin != null) {
    platformPlugin.destroy();
    platformPlugin = null;
  }
}

@Override
public void onWindowFocusChanged(boolean hasFocus) {
  super.onWindowFocusChanged(hasFocus);
  if (hasFocus) {
    flutterEngine.getLifecycleChannel().aWindowIsFocused();
  } else {
    flutterEngine.getLifecycleChannel().noWindowsAreFocused();
  }
}
```

Without these lifecycle notifications, Flutter may remain in a paused state and refuse to render frames, resulting in a blank screen.


### Create and configure platform plugin

The `PlatformPlugin` handles system-level services requested by the Flutter framework (e.g. sound effects, clipboard, system chrome, preferred screen orientation, navigation back events).

To enable these platform services, instantiate a `PlatformPlugin` passing your `Activity` and the engine's `PlatformChannel`:

```java
platformPlugin = new PlatformPlugin(activity, flutterEngine.getPlatformChannel());
```

### Add accessibility support

TODO(mattcarroll)

### Add support for plugins

TODO(mattcarroll)

### Handling orientation change

TODO(mattcarroll)