part of flutter_sprites;

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

  void set rootNode (NodeWithSize value) {
    if (value == _rootNode) return;

    // Ensure that the root node has a size
    assert(_transformMode == SpriteBoxTransformMode.nativePoints
      || value.size.width > 0);
    assert(_transformMode == SpriteBoxTransformMode.nativePoints
      || value.size.height > 0);

    // Remove sprite box references
    if (_rootNode != null) _removeSpriteBoxReference(_rootNode);

    // Update the value
    _rootNode = value;

    // Add new references
    _addSpriteBoxReference(_rootNode);
    markNeedsLayout();
  }

  // Tracking of frame rate and updates
  Duration _lastTimeStamp;
  double _frameRate = 0.0;

  double get frameRate => _frameRate;

  // Transformation mode
  SpriteBoxTransformMode _transformMode;

  void set transformMode (SpriteBoxTransformMode value) {
    if (value == _transformMode)
      return;
    _transformMode = value;

    // Invalidate stuff
    markNeedsLayout();
  }

  /// The transform mode used by the [SpriteBox].
  SpriteBoxTransformMode get transformMode => _transformMode;

  // Cached transformation matrix
  Matrix4 _transformMatrix;

  List<Node> _eventTargets;

  List<ActionController> _actionControllers;

  List<Node> _constrainedNodes;

  List<PhysicsWorld> _physicsNodes;

  Rect _visibleArea;

  Rect get visibleArea {
    if (_visibleArea == null)
      _calcTransformMatrix();
    return _visibleArea;
  }

  bool _initialized = false;

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

    // Setup transform mode
    this.transformMode = mode;

    // Setup root node
    this.rootNode = rootNode;
  }

  void _removeSpriteBoxReference(Node node) {
    node._spriteBox = null;
    for (Node child in node._children) {
      _removeSpriteBoxReference(child);
    }
  }

  void _addSpriteBoxReference(Node node) {
    node._spriteBox = this;
    for (Node child in node._children) {
      _addSpriteBoxReference(child);
    }
  }

  void attach() {
    super.attach();
    _scheduleTick();
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
    _initialized = true;
  }

  // Adding and removing nodes

  void _registerNode(Node node) {
    _actionControllers = null;
    _eventTargets = null;
    _physicsNodes = null;
    if (node == null || node.constraints != null) _constrainedNodes = null;
  }

  void _deregisterNode(Node node) {
    _actionControllers = null;
    _eventTargets = null;
    _physicsNodes = null;
    if (node == null || node.constraints != null) _constrainedNodes = null;
  }

  // Event handling

  void _addEventTargets(Node node, List<Node> eventTargets) {
    List children = node.children;
    int i = 0;

    // Add childrens that are behind this node
    while (i < children.length) {
      Node child = children[i];
      if (child.zPosition >= 0.0)
        break;
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

  void handleEvent(InputEvent event, _SpriteBoxHitTestEntry entry) {
    if (!attached)
      return;

    if (event is PointerInputEvent) {

      if (event.type == 'pointerdown') {
        // Build list of event targets
        if (_eventTargets == null) {
          _eventTargets = <Node>[];
          _addEventTargets(_rootNode, _eventTargets);
        }

        // Find the once that are hit by the pointer
        List<Node> nodeTargets = <Node>[];
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
          if (consumedEvent == null || consumedEvent)
            break;
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
    if (_transformMatrix == null) {
      _calcTransformMatrix();
    }
    return _transformMatrix;
  }

  void _calcTransformMatrix() {
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
        systemWidth = size.width;
        systemHeight = size.height;
        break;
      default:
        assert(false);
        break;
    }

    _visibleArea = new Rect.fromLTRB(-offsetX / scaleX,
                                     -offsetY / scaleY,
                                     systemWidth + offsetX / scaleX,
                                     systemHeight + offsetY / scaleY);

    _transformMatrix.translate(offsetX, offsetY);
    _transformMatrix.scale(scaleX, scaleY);
  }

  void _invalidateTransformMatrix() {
    _visibleArea = null;
    _transformMatrix = null;
    _rootNode._invalidateToBoxTransformMatrix();
  }

  void paint(PaintingContext context, Offset offset) {
    final PaintingCanvas canvas = context.canvas;
    canvas.save();

    // Move to correct coordinate space before drawing
    canvas.translate(offset.dx, offset.dy);
    canvas.concat(transformMatrix.storage);

    // Draw the sprite tree
    Matrix4 totalMatrix = new Matrix4.fromFloat64List(canvas.getTotalMatrix());
    _rootNode._visit(canvas, totalMatrix);

    // Draw physics debug
    for (PhysicsWorld world in _physicsNodes) {
      if (world.drawDebug) {
        canvas.setMatrix(world._debugDrawTransform.storage);
        world.paintDebug(canvas);
      }
    }

    canvas.restore();
  }

  // Updates

  void _scheduleTick() {
    scheduler.scheduleFrameCallback(_tick);
  }

  void _tick(Duration timeStamp) {
    if (!attached)
      return;

    // Calculate delta and frame rate
    if (_lastTimeStamp == null)
      _lastTimeStamp = timeStamp;
    double delta = (timeStamp - _lastTimeStamp).inMicroseconds.toDouble() / Duration.MICROSECONDS_PER_SECOND;
    _lastTimeStamp = timeStamp;

    _frameRate = 1.0/delta;

    if (_initialized) {
      _callConstraintsPreUpdate(delta);
      _runActions(delta);
      _callUpdate(_rootNode, delta);
      _callStepPhysics(delta);
      _callConstraintsConstrain(delta);
    }

    // Schedule next update
    _scheduleTick();

    // Make sure the node graph is redrawn
    markNeedsPaint();
  }

  void _runActions(double dt) {
    if (_actionControllers == null) {
      _rebuildActionControllersAndPhysicsNodes();
    }
    for (ActionController actions in _actionControllers) {
      actions.step(dt);
    }
  }

  void _rebuildActionControllersAndPhysicsNodes() {
    _actionControllers = <ActionController>[];
    _physicsNodes = <PhysicsWorld>[];
    _addActionControllersAndPhysicsNodes(_rootNode);
  }

  void _addActionControllersAndPhysicsNodes(Node node) {
    if (node._actions != null) _actionControllers.add(node._actions);
    if (node is PhysicsWorld) _physicsNodes.add(node);

    for (int i = node.children.length - 1; i >= 0; i--) {
      Node child = node.children[i];
      _addActionControllersAndPhysicsNodes(child);
    }
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

  void _callStepPhysics(double dt) {
    if (_physicsNodes == null)
      _rebuildActionControllersAndPhysicsNodes();

    for (PhysicsWorld physicsNode in _physicsNodes) {
      physicsNode._stepPhysics(dt);
    }
  }

  void _callConstraintsPreUpdate(double dt) {
    if (_constrainedNodes == null) {
      _constrainedNodes = <Node>[];
      _addConstrainedNodes(_rootNode, _constrainedNodes);
    }

    for (Node node in _constrainedNodes) {
      for (Constraint constraint in node.constraints) {
        constraint.preUpdate(node, dt);
      }
    }
  }

  void _callConstraintsConstrain(double dt) {
    if (_constrainedNodes == null) {
      _constrainedNodes = <Node>[];
      _addConstrainedNodes(_rootNode, _constrainedNodes);
    }

    for (Node node in _constrainedNodes) {
      for (Constraint constraint in node.constraints) {
        constraint.constrain(node, dt);
      }
    }
  }

  void _addConstrainedNodes(Node node, List<Node> nodes) {
    if (node._constraints != null && node._constraints.length > 0) {
      nodes.add(node);
    }

    for (Node child in node.children) {
      _addConstrainedNodes(child, nodes);
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

    List<Node> nodes = <Node>[];

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
