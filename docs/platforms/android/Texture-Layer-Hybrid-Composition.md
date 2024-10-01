_See also: [Hybrid Composition|Hybrid Composition#Android](../Hybrid-Composition.md)_

# Background

Texture Layer Hybrid Composition (TLHC) is one of several modes for displaying platform views on Android. See [Android Platform Views](Android-Platform-Views.md) for an overview of modes.

It was introduced in Flutter 3.0 to combine the best aspects of Virtual Display and Hybrid Composition while addressing their most significant issues. While it was originally intended to replace both, it turned out to have some limitations that prevented serving as a complete replacement, so is now a third option.

# Approach

TLHC uses a [custom `FrameLayout`](https://github.com/flutter/engine/blob/7025645c52bfaeb1cc67be5ca842b65772c89c8e/shell/platform/android/io/flutter/plugin/platform/PlatformViewWrapper.java#L35-L46), which is placed in the native view hierarchy as normal, but [redirects drawing](https://github.com/flutter/engine/blob/7025645c52bfaeb1cc67be5ca842b65772c89c8e/shell/platform/android/io/flutter/plugin/platform/PlatformViewWrapper.java#L299-L309) to a canvas that backs a Flutter [`Texture`](https://api.flutter.dev/flutter/widgets/Texture-class.html) in order to compose with the rest of the Flutter UI as normal (without the layering and threading complexities of Hybrid Composition).

# Limitations

- Because of the APIs involved, this requires SDK level 23 or later, so does not support quite as far back as Virtual Display (SDK 20+) or Hybrid Composition (SDK 19+).
- [Android `SurfaceView`s](https://developer.android.com/reference/android/view/SurfaceView) bypass the normal drawing mechanism of Android views, so are not redirected as expected. Instead, they draw as if the redirect did not happen, which generally causes them to draw over all Flutter content.
    - To mitigate this, platform views attempt to automatically fall back to another mode when a `SurfaceView` is present. However, this currently [only works if the `SurfaceView` is present when the platform view is created](https://github.com/flutter/flutter/issues/109690).
- [Android `TextureView`s](https://developer.android.com/reference/android/view/TextureView) do not always show updates correctly. This is [still under investigation](https://github.com/flutter/flutter/issues/103686), and for now affected plugins are best off using another mode.

To see all known issues specific to this mode, search for the [`tlhc-only` label](https://github.com/flutter/flutter/labels/tlhc-only).