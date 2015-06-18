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
  double _frameRate = 0.0;

  // Transformation mode
  SpriteBoxTransformMode transformMode;
  double _systemWidth;
  double _systemHeight;

  // Cached transformation matrix
  Matrix4 _transformMatrix;

  List<Node> _eventTargets;

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
    _invalidateTransformMatrix();
    _callSpriteBoxPerformedLayout(_rootNode);
  }

  // Event handling

  void _addEventTargets(Node node, List<Node> eventTargets) {
    if (node.userInteractionEnabled) {
      eventTargets.add(node);
    }
    for (Node child in node.children) {
      _addEventTargets(child, eventTargets);
    }
  }

  void handleEvent(Event event, SpriteBoxHitTestEntry entry) {
    if (event is PointerEvent) {

      if (event.type == 'pointerdown') {
        // Build list of event targets
        if (_eventTargets == null) {
          _eventTargets = [];
          _addEventTargets(_rootNode, _eventTargets);
        }

        // Find the once that are hit by the pointer
        List<Node> nodeTargets = [];
        for (int i = _eventTargets.length - 1; i >= 0; i--) {
          Node node = _eventTargets[i];

          // Check if the node is ready to handle a pointer
          if (node.handleMultiplePointers || node._handlingPointer == null) {
            // Do the hit test
            Point posInNodeSpace = node.convertPointToNodeSpace(entry.localPosition);
            if (node.hitTest(posInNodeSpace)) {
              nodeTargets.add(node);
              node._handlingPointer = event.pointer;
            }
          }
        }

        entry.nodeTargets = nodeTargets;
      }

      // Pass the event down to nodes that were hit by the pointerdown
      List<Node> targets = entry.nodeTargets;
      for (Node node in targets) {
        // Check if this event should be dispatched
        if (node.handleMultiplePointers || event.pointer == node._handlingPointer) {
          // Dispatch event
          bool consumedEvent = node.handleEvent(new SpriteBoxEvent(new Point(event.x, event.y), event.type, event.pointer));
          if (consumedEvent == null || consumedEvent) break;
        }
      }

      // De-register pointer for nodes that doesn't handle multiple pointers
      for (Node node in targets) {
        if (event.type == 'pointerup' || event.type == 'pointercancel') {
          node._handlingPointer = null;
        }
      }
    }
  }

  bool hitTest(HitTestResult result, { Point position }) {
    result.add(new SpriteBoxHitTestEntry(this, position));
    return true;
  }

  // Rendering

  Matrix4 get transformMatrix {
    // Get cached matrix if available
    if (_transformMatrix != null) {
      return _transformMatrix;
    }

    _transformMatrix = new Matrix4.identity();

    // Calculate matrix
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

    _transformMatrix.translate(offsetX, offsetY);
    _transformMatrix.scale(scaleX, scaleY);

    return _transformMatrix;
  }

  void _invalidateTransformMatrix() {
    _transformMatrix = null;
    _rootNode._invalidateToBoxTransformMatrix();
  }

  void paint(RenderObjectDisplayList canvas) {
    canvas.save();

    // Move to correct coordinate space before drawing
    canvas.concat(transformMatrix.storage);

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

    _frameRate = 1.0/delta;

    // Print frame rate
    if (_numFrames % 60 == 0) print("delta: $delta fps: $_frameRate");

    _callUpdate(_rootNode, delta);
    _scheduleTick();
  }

  void _callUpdate(Node node, double dt) {
    node.update(dt);
    for (Node child in node.children) {
      if (!child.paused) {
        _callUpdate(child, dt);
      }
    }
  }

  void _callSpriteBoxPerformedLayout(Node node) {
    node.spriteBoxPerformedLayout();
    for (Node child in node.children) {
      _callSpriteBoxPerformedLayout(child);
    }
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

class SpriteBoxHitTestEntry extends BoxHitTestEntry {
  List<Node> nodeTargets;
  SpriteBoxHitTestEntry(RenderBox target, Point localPosition) : super(target, localPosition);
}

class SpriteBoxEvent {
  Point boxPosition;
  String type;
  int pointer;

  SpriteBoxEvent(this.boxPosition, this.type, this.pointer);
}