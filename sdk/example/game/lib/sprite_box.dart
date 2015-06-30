part of sprites;

/// Options for setting up a [SpriteBox].
///
///  * [nativePoints], use the same points as the parent [Widget].
///  * [letterbox], use the size of the root node for the coordinate system, constrain the aspect ratio and trim off
///  areas that end up outside the screen.
///  * [stretch], use the size of the root node for the coordinate system, scale it to fit the size of the box.
///  * [scaleToFit], similar to the letterbox option, but instead of trimming areas the sprite system will be scaled
///  down to fit the box.
///  * [fixedWidth], uses the width of the root node to set the size of the coordinate system, this option will change
///  the height of the root node to fit the box.
///  * [fixedHeight], uses the height of the root node to set the size of the coordinate system, this option will change
///  the width of the root node to fit the box.
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
  NodeWithSize _rootNode;

  // Tracking of frame rate and updates
  double _lastTimeStamp;
  int _numFrames = 0;
  double _frameRate = 0.0;

  // Transformation mode
  SpriteBoxTransformMode _transformMode;

  /// The transform mode used by the [SpriteBox].
  SpriteBoxTransformMode get transformMode => _transformMode;

  // Cached transformation matrix
  Matrix4 _transformMatrix;

  List<Node> _eventTargets;

  // Setup

  /// Creates a new SpriteBox with a node as its content, by default uses letterboxing.
  ///
  /// The [rootNode] provides the content of the node tree, typically it's a custom subclass of [NodeWithSize]. The
  /// [mode] provides different ways to scale the content to best fit it to the screen. In most cases it's preferred to
  /// use a [SpriteWidget] that automatically wraps the SpriteBox.
  ///
  ///     var spriteBox = new SpriteBox(myNode, SpriteBoxTransformMode.fixedHeight);
  SpriteBox(NodeWithSize rootNode, [SpriteBoxTransformMode mode = SpriteBoxTransformMode.letterbox]) {
    assert(rootNode != null);
    assert(rootNode._spriteBox == null);

    // Setup root node
    _rootNode = rootNode;

    // Assign SpriteBox reference to all the nodes
    _addSpriteBoxReference(_rootNode);

    // Setup transform mode
    _transformMode = mode;

    _scheduleTick();
  }

  void _addSpriteBoxReference(Node node) {
    node._spriteBox = this;
    for (Node child in node._children) {
      _addSpriteBoxReference(child);
    }
  }

  // Properties

  /// The root node of the node tree that is rendered by this box.
  ///
  ///     var rootNode = mySpriteBox.rootNode;
  NodeWithSize get rootNode => _rootNode;

  void performLayout() {
    size = constraints.biggest;
    _invalidateTransformMatrix();
    _callSpriteBoxPerformedLayout(_rootNode);
  }

  // Event handling

  void _addEventTargets(Node node, List<Node> eventTargets) {
    List children = node.children;
    int i = 0;

    // Add childrens that are behind this node
    while (i < children.length) {
      Node child = children[i];
      if (child.zPosition >= 0.0) break;
      _addEventTargets(child, eventTargets);
      i++;
    }

    // Add this node
    if (node.userInteractionEnabled) {
      eventTargets.add(node);
    }

    // Add children in front of this node
    while (i < children.length) {
      Node child = children[i];
      _addEventTargets(child, eventTargets);
      i++;
    }
  }

  void handleEvent(Event event, _SpriteBoxHitTestEntry entry) {
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
            if (node.isPointInside(posInNodeSpace)) {
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
    result.add(new _SpriteBoxHitTestEntry(this, position));
    return true;
  }

  // Rendering

  /// The transformation matrix used to transform the root node to the space of the box.
  ///
  /// It's uncommon to need access to this property.
  ///
  ///     var matrix = mySpriteBox.transformMatrix;
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

    double systemWidth = rootNode.size.width;
    double systemHeight = rootNode.size.height;

    switch(_transformMode) {
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
        } else {
          scaleX = scaleY;
          offsetX = (size.width - scaleX * systemWidth)/2.0;
        }
        break;
      case SpriteBoxTransformMode.scaleToFit:
        scaleX = size.width/systemWidth;
        scaleY = size.height/systemHeight;
        if (scaleX < scaleY) {
          scaleY = scaleX;
          offsetY = (size.height - scaleY * systemHeight)/2.0;
        } else {
          scaleX = scaleY;
          offsetX = (size.width - scaleX * systemWidth)/2.0;
        }
        break;
      case SpriteBoxTransformMode.fixedWidth:
        scaleX = size.width/systemWidth;
        scaleY = scaleX;
        systemHeight = size.height/scaleX;
        rootNode.size = new Size(systemWidth, systemHeight);
        break;
      case SpriteBoxTransformMode.fixedHeight:
        scaleY = size.height/systemHeight;
        scaleX = scaleY;
        systemWidth = size.width/scaleY;
        rootNode.size = new Size(systemWidth, systemHeight);
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

  void paint(PaintingCanvas canvas, Offset offset) {
    canvas.save();

    // Move to correct coordinate space before drawing
    canvas.translate(offset.dx, offset.dy);
    canvas.concat(transformMatrix.storage);

    // Draw the sprite tree
    _rootNode._visit(canvas);

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
    for (int i = node.children.length - 1; i >= 0; i--) {
      Node child = node.children[i];
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

  /// Finds all nodes at a position defined in the box's coordinates.
  ///
  /// Use this method with caution. It searches the complete node tree to locate the nodes, which can be slow if the
  /// node tree is large.
  ///
  ///     List nodes = mySpriteBox.findNodesAtPosition(new Point(50.0, 50.0));
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
    if (node.isPointInside(posInNodeSpace)) {
      list.add(node);
    }
  }
}

class _SpriteBoxHitTestEntry extends BoxHitTestEntry {
  List<Node> nodeTargets;
  _SpriteBoxHitTestEntry(RenderBox target, Point localPosition) : super(target, localPosition);
}

/// An event that is passed down the node tree when pointer events occur. The SpriteBoxEvent is typically handled in
/// the handleEvent method of [Node].
class SpriteBoxEvent {

  /// The position of the event in box coordinates.
  ///
  /// You can use the convertPointToNodeSpace of [Node] to convert the position to local coordinates.
  ///
  ///     bool handleEvent(SpriteBoxEvent event) {
  ///       Point localPosition = convertPointToNodeSpace(event.boxPosition);
  ///       if (event.type == 'pointerdown') {
  ///         // Do something!
  ///       }
  ///     }
  final Point boxPosition;

  /// The type of event, there are currently four valid types, 'pointerdown', 'pointermoved', 'pointerup', and
  /// 'pointercancel'.
  ///
  ///     if (event.type == 'pointerdown') {
  ///       // Do something!
  ///     }
  final String type;

  /// The id of the pointer. Each pointer on the screen will have a unique pointer id.
  ///
  ///     if (event.pointer == firstPointerId) {
  ///       // Do something
  ///     }
  final int pointer;

  /// Creates a new SpriteBoxEvent, typically this is done internally inside the SpriteBox.
  ///
  ///     var event = new SpriteBoxEvent(new Point(50.0, 50.0), 'pointerdown', 0);
  SpriteBoxEvent(this.boxPosition, this.type, this.pointer);
}
