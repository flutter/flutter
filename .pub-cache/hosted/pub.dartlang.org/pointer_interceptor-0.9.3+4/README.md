# pointer_interceptor

`PointerInterceptor` is a widget that prevents mouse events (in web) from being captured by an underlying [`HtmlElementView`](https://api.flutter.dev/flutter/widgets/HtmlElementView-class.html).

You can use this widget in a cross-platform app freely. In mobile, where the issue that this plugin fixes does not exist, the widget acts as a pass-through of its `children`, without adding anything to the render tree.

## What is the problem?

When overlaying Flutter widgets on top of `HtmlElementView` widgets that respond to mouse gestures (handle clicks, for example), the clicks will be consumed by the `HtmlElementView`, and not relayed to Flutter.

The result is that Flutter widget's `onTap` (and other) handlers won't fire as expected, but they'll affect the underlying webview.

|The problem...|
|:-:|
|![Depiction of problematic areas](https://raw.githubusercontent.com/flutter/packages/main/packages/pointer_interceptor/doc/img/affected-areas.png)|
|_In the dashed areas, mouse events won't work as expected. The `HtmlElementView` will consume them before Flutter sees them._|


## How does this work?

`PointerInterceptor` creates a platform view consisting of an empty HTML element. The element has the size of its `child` widget, and is inserted in the layer tree _behind_ its child in paint order.

This empty platform view doesn't do anything with mouse events, other than preventing them from reaching other platform views underneath it.

This gives an opportunity to the Flutter framework to handle the click, as expected:

|The solution...|
|:-:|
|![Depiction of the solution](https://raw.githubusercontent.com/flutter/packages/main/packages/pointer_interceptor/doc/img/fixed-areas.png)|
|_Each `PointerInterceptor` (green) renders between Flutter widgets and the underlying `HtmlElementView`. Mouse events now can't reach the background HtmlElementView, and work as expected._|

## How to use

Some common scenarios where this widget may come in handy:

* [FAB](https://api.flutter.dev/flutter/material/FloatingActionButton-class.html) unclickable in an app that renders a full-screen background Map
* Custom Play/Pause buttons on top of a video element don't work
* Drawer contents not interactive when it overlaps an iframe element
* ...

All the cases above have in common that they attempt to render Flutter widgets *on top* of platform views that handle pointer events.

There's two ways that the `PointerInterceptor` widget can be used to solve the problems above:

1. Wrapping your button element directly (FAB, Custom Play/Pause button...):

    ```dart
    PointerInterceptor(
      child: ElevatedButton(...),
    )
    ```

2. As a root container for a "layout" element, wrapping a bunch of other elements (like a Drawer):

    ```dart
    Scaffold(
      ...
      drawer: PointerInterceptor(
        child: Drawer(
          child: ...
        ),
      ),
      ...
    )
    ```

### `intercepting`

A common use of the `PointerInterceptor` widget is to block clicks only under
certain conditions (`isVideoShowing`, `isPanelOpen`...).

The `intercepting` property allows the `PointerInterceptor` widget to render
itself (or not) depending on a boolean value, instead of having to manually
write an `if/else` on the Flutter App widget tree, so code like this:

  ```dart
  if (someCondition) {
    return PointerInterceptor(
      child: ElevatedButton(...),
    )
  } else {
    return ElevatedButton(...),
  }
  ```

can be rewritten as:

   ```dart
    return PointerInterceptor(
      intercepting: someCondition,
      child: ElevatedButton(...),
    )
   ```

Note: when `intercepting` is false, the `PointerInterceptor` will not render
_anything_ in flutter, and just return its `child`. The code is exactly
equivalent to the example above.

### `debug`

The `PointerInterceptor` widget has a `debug` property, that will render it visibly on the screen (similar to the images above).

This may be useful to see what the widget is actually covering when used as a layout element.
