This folder contains unit tests that are intended to provide basic coverage of deprecated features while we
are in the process of removing them. Due to the large number of pixel diff tests in google, it can be difficult
to land features that change subpixel values even slightly. Because we'd like to keep improving the performance and
fidelity of the framework, we must nevertheless soldier on.

For one example, we'd like to remove the forced compositing from the Material widget. However, this leads to
slight hairline differences in thousands of places. First, we add a private dart define in the library
with the significant behavioral change. Note: by default bool.fromEnvironment is false.

proxy_box.dart
```dart
// Allows opting into the old physical model behavior.
// to use: `flutter run --dart-define=flutter.deprecated.physical_model_layer=true`.
const bool _kForcePhysicalModeLayer = bool.fromEnvironment('flutter.deprecated.physical_model_layer');
```

Then, we leave the old functionality in the render object guarded by this const value:

proxy_box.dart
```dart
 @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) {
      layer = null;
      return;
    }

    _updateClip();
    final RRect offsetRRect = _clip!.shift(offset);
    final Rect offsetBounds = offsetRRect.outerRect;
    final Path offsetRRectAsPath = Path()..addRRect(offsetRRect);
    bool paintShadows = true;
    assert(() {
      if (debugDisableShadows) {
        if (elevation > 0.0) {
          context.canvas.drawRRect(
            offsetRRect,
            Paint()
              ..color = shadowColor
              ..style = PaintingStyle.stroke
              ..strokeWidth = elevation * 2.0,
          );
        }
        paintShadows = false;
      }
      return true;
    }());

    if (_kForcePhysicalModeLayer) {
      layer ??= PhysicalModelLayer();
      (layer! as PhysicalModelLayer)
        ..clipPath = offsetRRectAsPath
        ..clipBehavior = clipBehavior
        ..elevation = paintShadows ? elevation : 0.0
        ..color = color
        ..shadowColor = shadowColor;
      context.pushLayer(layer!, super.paint, offset, childPaintBounds: offsetBounds);
      assert(() {
        layer?.debugCreator = debugCreator;
        return true;
      }());
      return;
    }

    // Rest of the method...
```

Finally we update `dev/bots/deprecated_features.dart` to contain the value "flutter.deprecated.physical_model_layer" and then
write a simple test in this folder that asserts the old behavior is still present.
