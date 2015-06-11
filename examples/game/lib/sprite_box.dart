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

  // Member variables

  // Root node for drawing
  Node _rootNode;

  // Tracking of frame rate and updates
  double _lastTimeStamp;
  int _numFrames = 0;

  SpriteBoxTransformMode transformMode;
  double _systemWidth;
  double _systemHeight;

  // Setup

  SpriteBox(Node rootNode, [SpriteBoxTransformMode mode = SpriteBoxTransformMode.nativePoints, double width=1024.0, double height=1024.0]) {
    assert(rootNode != null);
    assert(rootNode._spriteBox == null);

    // Setup root node
    _rootNode = rootNode;

    // Assign SpriteBox reference to all the nodes
    _addSpriteBoxReference(_rootNode);

    // Setup transform mode
    transformMode = mode;
    _systemWidth = width;
    _systemHeight = height;

    _scheduleTick();
  }

  void _addSpriteBoxReference(Node node) {
    node._spriteBox = this;
    for (Node child in node._children) {
      _addSpriteBoxReference(child);
    }
  }

  // Properties

  double get systemWidth => _systemWidth;
  double get systemHeight => _systemHeight;

  Node get rootNode => _rootNode;

  void performLayout() {
    size = constraints.constrain(Size.infinite);
  }

  // Event handling

  void handleEvent(Event event, BoxHitTestEntry entry) {
  }

  // Rendering

  void paint(RenderObjectDisplayList canvas) {
    // Move to correct coordinate space before drawing
    double scaleX = 1.0;
    double scaleY = 1.0;
    double offsetX = 0.0;
    double offsetY = 0.0;

    switch(transformMode) {
      case SpriteBoxTransformMode.stretch:
        scaleX = size.width/_systemWidth;
        scaleY = size.height/_systemHeight;
        break;
      case SpriteBoxTransformMode.letterbox:
        scaleX = size.width/_systemWidth;
        scaleY = size.height/_systemHeight;
        if (scaleX > scaleY) {
          scaleY = scaleX;
          offsetY = (size.height - scaleY * _systemHeight)/2.0;
        }
        else {
          scaleX = scaleY;
          offsetX = (size.width - scaleX * _systemWidth)/2.0;
        }
        break;
      case SpriteBoxTransformMode.scaleToFit:
        scaleX = size.width/_systemWidth;
        scaleY = size.height/_systemHeight;
        if (scaleX < scaleY) {
          scaleY = scaleX;
          offsetY = (size.height - scaleY * _systemHeight)/2.0;
        }
        else {
          scaleX = scaleY;
          offsetX = (size.width - scaleX * _systemWidth)/2.0;
        }
        break;
      case SpriteBoxTransformMode.fixedWidth:
        scaleX = size.width/_systemWidth;
        scaleY = scaleX;
        _systemHeight = size.height/scaleX;
        break;
      case SpriteBoxTransformMode.fixedHeight:
        scaleY = size.height/_systemHeight;
        scaleX = scaleY;
        _systemWidth = size.width/scaleY;
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

  // Updates

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

  // Hit tests

  List<Node> findNodesAtPosition(Point position) {
    assert(position != null);

    List<Node> nodes = [];

    // Traverse the render tree and find objects at the position
    _addNodesAtPosition(_rootNode, position, nodes);

    return nodes;
  }

  _addNodesAtPosition(Node node, Point position, List<Node> list) {
    // Visit children first
    for (Node child in node.children) {
      _addNodesAtPosition(child, position, list);
    }
    // Do the hit test
    Point posInNodeSpace = node.convertPointToNodeSpace(position);
    if (node.hitTest(posInNodeSpace)) {
      list.add(node);
    }
  }
}
