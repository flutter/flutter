part of sprites;

enum SpriteBoxTransformMode {
  nativePoints,
  letterbox,
  stretch,
  scaleToFit,
  fixedWidth,
  fixedHeight,
}

class SpriteBox extends RenderBox {

  // Root node for drawing
  TransformNode _rootNode;

  // Tracking of frame rate and updates
  double _lastTimeStamp;
  int _numFrames = 0;

  SpriteBoxTransformMode transformMode;
  double systemWidth;
  double systemHeight;

  SpriteBox(TransformNode rootNode, [SpriteBoxTransformMode mode = SpriteBoxTransformMode.nativePoints, double width=1024.0, double height=1024.0]) {
    // Setup root node
    _rootNode = rootNode;

    // Setup transform mode
    transformMode = mode;
    systemWidth = width;
    systemHeight = height;

    _scheduleTick();
  }

  void performLayout() {
    size = constraints.constrain(new Size.infinite());
  }

  void handlePointer(PointerEvent event) {
    switch (event.type) {
      case 'pointerdown':
        print("pointerdown");
        break;
    }
  }

  void paint(RenderNodeDisplayList canvas) {
    // Move to correct coordinate space before drawing
    double scaleX = 1.0;
    double scaleY = 1.0;
    double offsetX = 0.0;
    double offsetY = 0.0;

    switch(transformMode) {
      case SpriteBoxTransformMode.stretch:
        scaleX = size.width/systemWidth;
        scaleY = size.height/systemHeight;
        break;
      case SpriteBoxTransformMode.letterbox:
        scaleX = size.width/systemWidth;
        scaleY = size.height/systemHeight;
        if (scaleX > scaleY) {
          scaleY = scaleX;
          offsetY = (size.height - scaleY * systemHeight)/2.0;
        }
        else {
          scaleX = scaleY;
          offsetX = (size.width - scaleX * systemWidth)/2.0;
        }
        break;
      case SpriteBoxTransformMode.nativePoints:
        break;
      default:
        assert(false);
        break;
    }

    canvas.save();

    canvas.translate(offsetX, offsetY);
    canvas.scale(scaleX, scaleY);

    // Draw the sprite tree
    _rootNode.visit(canvas);

    canvas.restore();
  }

  int _animationId = 0;

  void _scheduleTick() {
    _animationId = scheduler.requestAnimationFrame(_tick);
  }

  void _tick(double timeStamp) {

      // Calculate the time between frames in seconds
    if (_lastTimeStamp == null) _lastTimeStamp = timeStamp;
    double delta = (timeStamp - _lastTimeStamp) / 1000;
    _lastTimeStamp = timeStamp;

    // Count the number of frames we've been running
    _numFrames += 1;

    // Print frame rate
    if (_numFrames % 60 == 0) print("delta: ${delta} fps: ${1.0/delta}");

    _rootNode.update(delta);
    _scheduleTick();
  }
}