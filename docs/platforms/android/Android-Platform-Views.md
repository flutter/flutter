# Background

Flutter UIs function conceptually similar to a WebView on Android. The
Flutter Framework takes a widget tree described by the app developer and
translates that into an internal widget hierarchy, and then from that decides
what pixels to actually render. Web developers can think of this as analogous
to how a browser takes HTML/CSS, creates a Document Object Model ("DOM"), and
then uses that DOM to actually render pixels each frame. Also like a WebView,
Flutter UIs aren't translated to a set of Android View widgets and composited
by the Android OS itself. Flutter controls a texture (generally through a
[SurfaceView](https://developer.android.com/reference/android/view/SurfaceView))
and uses Skia to render directly to the texture without ever using any kind of
Android View hierarchy to represent its internal Flutter widget hierarchy or
UI.

This means that like a WebView, by default a Flutter UI could never contain
an Android View within its widget hierarchy. Since the Flutter UI is just
being drawn to a texture and its widget tree is entirely internal, there's no
place for the View to "fit" within Flutter's internal model or render
interleaved within Flutter widgets. That's a problem for developers that would
like to include complex pre-existing Android views in their Flutter apps, like
WebViews themselves, or maps.

To solve this problem Flutter created an [AndroidView
widget](https://api.flutter.dev/flutter/widgets/AndroidView-class.html) that
Flutter developers can use to visually embed actual Android View components
within their Flutter UI.

# Approaches

There are currently three different implementations of Android platform views:
- [Virtual Display](Virtual_Display.md) (VD)
- [Hybrid Composition](../Hybrid-Composition.md) (HC)
- [Texture Layer Hybrid Composition](Texture-Layer-Hybrid-Composition.md) (TLHC)

Each has a different set of limitations and tradeoffs, as discussed below. The pages linked above give details about each implementation.

## Virtual Display

This mode works by rendering the platform view into [a `VirtualDisplay`](https://developer.android.com/reference/android/hardware/display/VirtualDisplay), whose contents are connected to [a Flutter `Texture`](https://api.flutter.dev/flutter/widgets/Texture-class.html).

Because this renders to a `Texture`, it integrates well into the Flutter drawing system. However, the use of `VirtualDisplay` introduces a number of compatibility issues, including with text input, accessibility, and secondary views (see [the Virtual Display page](Virtual-Display.md) for details).

This display mode requires SDK 20 or later.

## Hybrid Composition

This mode directly displays the native Android [`View`](https://developer.android.com/reference/android/view/View) in the view hierarchy. This requires several significant changes to the way Flutter renders:
- The Flutter widget tree is divided into two different Android `View`s, one below the platform view and one above it.
- To avoid tearing or other visual artifacts, Flutter's composition must be done on the platform thread rather than a dedicated thread.

Because the native view is being displayed directly, just as it would be in non-Flutter application, this mode is the least likely to have compatibility issues with the platform view. However, the rendering changes can significantly impact Flutter's performance. In addition, on versions of Android before SDK 29 (Android 10) Flutter frames have a GPU->CPU->GPU round trip that further impacts performance.

This display mode requires SDK 19 or later, and uses the FlutterImageView based renderer.

## Texture Layer Hybrid Composition

This mode, introduced in Flutter 3.0, attempted to address the limitations of the modes above, and was originally intended to replace both. Like Hybrid Composition, the view is actually placed on the screen at the correct location. However, as with Virtual Display the drawing uses a `Texture`, which in this case is populated by redirecting [`draw`](https://developer.android.com/reference/android/view/View#draw(android.graphics.Canvas)).

In most cases this combines the best aspects of Virtual Display and Hybrid Composition, and should be preferred when possible. One notable exception however is that if the platform view is, or contains, a [`SurfaceView`](https://developer.android.com/reference/android/view/SurfaceView) this mode will not work correctly, and the `SurfaceView` will be drawn at the wrong location and/or z-index.

This display mode requires SDK 23 or later.

# Selecting a mode

Usually Android platform views are created with one of the `init*` methods:
- `initAndroidView` creates a [`TextureAndroidViewController`](https://api.flutter.dev/flutter/services/TextureAndroidViewController-class.html), which will use TLHC mode if possible, and fall back to VD if not. The fallback is triggered if:
    - the current SDK version is <23, or
    - the platform view hierarchy contains a `SurfaceView` (or subclass) **at creation time**.

  There is [a known issue](https://github.com/flutter/flutter/issues/109690) where if the view hierarchy does not contain a `SurfaceView` at creation time, but one is added later, rendering will not work correctly. Until that issue is resolved, plugin authors can work around this by either:
    - including a 0x0 `SurfaceView` in the view hierarchy at creation time, to trigger fallback to VD, or
    - switching to `initExpensiveAndroidView` to require HC.

  (The behavior described above is for Flutter 3.3+. Flutter 3.0 did not include the fallback to VD, and in Flutter <3.0 this always used VD.)
- `initSurfaceAndroidView` creates a [`SurfaceAndroidViewController`](https://api.flutter.dev/flutter/services/SurfaceAndroidViewController-class.html), which will use TLHC if possible, and fall back to HC if not. As above, the fallback is triggered if:
    - the current SDK version is <23, or
    - the platform view hierarchy contains a `SurfaceView` (or subclass) **at creation time**.

  There is [a known issue](https://github.com/flutter/flutter/issues/109690) where if the view hierarchy does not contain a `SurfaceView` at creation time, but one is added later, rendering will not work correctly. Until that issue is resolved, plugin authors can work around this by either:
    - including a 0x0 `SurfaceView` in the view hierarchy at creation time, to trigger fallback to HC, or
    - switching to `initExpensiveAndroidView` to require HC directly.

  (The behavior described above is for Flutter 3.7+. In Flutter 3.0 and 3.0 this behaved identically to `initAndroidView`, and in Flutter <3.0 this always used HC.)
- `initExpensiveAndroidView` creates an [`ExpensiveAndroidViewController`](https://api.flutter.dev/flutter/services/ExpensiveAndroidViewController-class.html), which will always use HC.

  (This API was introduced in Flutter 3.0.)

In general, plugins will likely get the best performance by using `initAndroidView` or `initSurfaceAndroidView` (depending on which fallback mode is desired for older versions of Android), and should only use `initExpensiveAndroidView` if the plugin is found to be incompatible with TLHC (such as dynamically adding a `SurfaceView`).