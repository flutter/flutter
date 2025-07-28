Flutter apps work by transforming the widget tree in an application to a render
tree that describes how to graphically render the widgets onscreen, and
animating in response to input events or the passage of time. We refer to a
single still image within the sequence of images composing an animation as a
frame, similar to a frame in a movie filmstrip. In the context of a complete
Flutter application these are rendered into a `FlutterView` class which is
typically an instance of a platform-specific view class like [SurfaceView] on
Android, [UIView] on iOS, [HWND] on Windows, [NSView] on macOS, or [GtkBox] on
Linux.

This page attempts to describe the life of a Flutter frame in the engine from
initial trigger to rasterization, presentation, and finally
destruction/recycling. For an overview of the Framework side of this process,
see the [Flutter's Rendering Pipeline][renderingpipelinetalk] tech talk.

## How a frame begins

All frames are born with a call to `RequestFrame` in the [Animator].

A frame may be requested for a variety of reasons, ranging from resizing the
Flutter view, to lifecycle events like backgrounding or foregrounding an app, to
requests from either the app (via dart:ui's
[PlatformDispatcher.scheduleFrame][scheduleframe]) or the embedder (via the
[embedder API][embedderapi]'s `FlutterEngineScheduleFrame`).

Flutter does some minimal housekeeping when a frame is requested, primarily to
ignore any duplicate requests to schedule a frame before the frame is actually
produced.

Once a frame is scheduled, Flutter [waits for a vsync][vsyncwaiter] from the
operating system to proceed.

## Building the frame

At the heart of Flutter's graphics workflow is the frame [pipeline]. The
pipeline is responsible for coordinating work between the UI thread, where the
application code runs, and the Raster thread, where rasterization and
compositing is performed. See the [threading section][enginearchthreading] of
the Engine Architecture wiki for more details on threading in the engine.

When a vsync occurs, Flutter begins the work of producing the frame in
[Animator]'s aptly-named `BeginFrame`. At this point, the animator reserves a
spot in the pipeline and notifies the framework to begin the process of
producing a frame by triggering the
[PlatformDispatcher.onBeginFrame][onbeginframe] dart:ui callback.

When using the engine with the Flutter framework, `onBeginFrame` is handled by
[handleBeginFrame] in the framework, whose job it is to kick off the production
of a [Scene] in the framework. A good overview of this process can be found in
the documentation of [RendererBinding.drawFrame][drawframe] and the
[Flutter's Rendering Pipeline][renderingpipelinetalk] tech talk. This process
ultimately culminates in the production of a `Scene` which is handed back to the
engine through a call to [FlutterView.render][flutterviewrender].

On the engine side, a `Scene` is represented as a [LayerTree]. Calling
`FlutterView.render` hands the layer tree to the Animator via a call its
`Render` method, which posts the layer tree to the pipeline and notifies the
Rasterizer that it's time to start rasterizing the frame.

## Rasterizing the frame

Rasterization is the process of converting the in-memory layer tree into pixels
on a surface. Rasterization-related code in Flutter is executed on the Raster
thread, which coordinates with the GPU. On some platforms, the Raster thread and
the Platform thread may be the same thread.

Rasterization starts with a call to the `Draw` method in the [Rasterizer]. At
this point, the recently-produced `LayerTree` is pulled from the pipeline. The
rasterizer does a quick check to see whether the app is running in headless mode
(e.g. backgrounded) and if so, the frame is discarded; otherwise, rasterization
proceeds.

Rasterization begins with a request for a surface to which the GPU can draw via
a call to the `AcquireFrame` method of [Surface]. This delegates
platform-specific code implemented in each embedder in response to callbacks
configured in `FlutterRendererConfig` which acquires an appropriate Metal,
OpenGL, Vulkan, or software surface for use by the rasterizer.

Once a surface is acquired, the [LayerTree] is rasterized to the surface via
recursive `Preroll` and `Paint` calls through the layers. Behavior of these
calls is specific to each layer type, but in the end, generally resolves to
drawing via either either Skia or Impeller. Once the layer tree has been walked
and all graphics operations have been collected, the frame is submitted to the
GPU, and embedders are provided a callback to perform further platform-specific
handling on their part -- typically presenting the surface via the
platform-specific view implementation.

The above process is repeated until the pipeline is empty.

## Warm-up frame

Normally, the Flutter framework begins producing a frame when it receives a
vsync event from the operating system. However, this may not happen for several
milliseconds after the app starts (or after a hot reload). To make use of the
time between when the widget tree is first configured and when the engine
requests an update, the framework schedules a _warm-up frame_ using
[PlatformDispatcher.scheduleWarmUpFrame][schedulewarmupframe].

A warm-up frame may never actually render (as it invokes
[FlutterView.render][flutterviewrender] outside of the scope of
[PlatformDispatcher.onBeginFrame][onbeginframe] or
[PlatformDispatcher.onDrawFrame][ondrawframe]), but it will cause the framework
to go through the steps of building, laying out, and painting, which can
together take several milliseconds. Thus, when the engine requests a real frame,
much of the work will already have been completed, and the framework can
generate the frame with minimal additional effort.

At startup, a warm-up frame can be produced before the Flutter engine has
reported the initial view metrics using
[PlatformDispatcher.onMetricsChanged][onmetricschanged]. As a result, the first
frame can be produced with a size of zero.

## Cleaning up frame resources

TODO(cbracken): write this up using
[this patch](https://github.com/flutter/engine/pull/38038) as a reminder.

[animator]: https://github.com/flutter/flutter/blob/main/engine/src/flutter/shell/common/animator.h
[drawframe]: https://api.flutter.dev/flutter/rendering/RendererBinding/drawFrame.html
[embedderapi]: https://github.com/flutter/flutter/blob/main/engine/src/flutter/shell/platform/embedder/embedder.h
[enginearchthreading]: ../about/The-Engine-architecture.md#threading
[flutterviewrender]: https://api.flutter.dev/flutter/dart-ui/FlutterView/render.html
[gtkbox]: https://docs.gtk.org/gtk3/class.Box.html
[handlebeginframe]: https://api.flutter.dev/flutter/scheduler/SchedulerBinding/handleBeginFrame.html
[hwnd]: https://learn.microsoft.com/en-us/windows/win32/winprog/windows-data-types#HWND
[layertree]: https://github.com/flutter/flutter/blob/main/engine/src/flutter/flow/layers/layer_tree.h
[nsview]: https://developer.apple.com/documentation/appkit/nsview
[onbeginframe]: https://api.flutter.dev/flutter/dart-ui/PlatformDispatcher/onBeginFrame.html
[ondrawframe]: https://api.flutter.dev/flutter/dart-ui/PlatformDispatcher/onDrawFrame.html
[onmetricschanged]: https://api.flutter.dev/flutter/dart-ui/PlatformDispatcher/onMetricsChanged.html
[pipeline]: https://github.com/flutter/flutter/blob/main/engine/src/flutter/shell/common/pipeline.h
[rasterizer]: https://github.com/flutter/flutter/blob/main/engine/src/flutter/shell/common/rasterizer.h
[renderingpipelinetalk]: https://www.youtube.com/watch?v=UUfXWzp0-DU
[scene]: https://api.flutter.dev/flutter/dart-ui/Scene-class.html
[scheduleframe]: https://api.flutter.dev/flutter/dart-ui/PlatformDispatcher/scheduleFrame.html
[schedulewarmupframe]: https://api.flutter.dev/flutter/dart-ui/PlatformDispatcher/scheduleWarmUpFrame.html
[surface]: https://github.com/flutter/flutter/blob/main/engine/src/flutter/flow/surface.h
[surfaceview]: https://developer.android.com/reference/android/view/SurfaceView
[uiview]: https://developer.apple.com/documentation/uikit/uiview
[vsyncwaiter]: https://github.com/flutter/flutter/blob/main/engine/src/flutter/shell/common/vsync_waiter.h
