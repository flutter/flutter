part of sprites;

double convertDegrees2Radians(double degrees) => degrees * Math.PI/180.8;

double convertRadians2Degrees(double radians) => radians * 180.0/Math.PI;

/// A base class for all objects that can be added to the sprite node tree and rendered to screen using [SpriteBox] and
/// [SpriteWidget].
///
/// The [Node] class itself doesn't render any content, but provides the basic functions of any type of node, such as
/// handling transformations and user input. To render the node tree, a root node must be added to a [SpriteBox] or a
/// [SpriteWidget]. Commonly used sub-classes of [Node] are [Sprite], [NodeWithSize], and many more upcoming subclasses.
///
/// Nodes form a hierarchical tree. Each node can have a number of children, and the transformation (positioning,
/// rotation, and scaling) of a node also affects its children.
class Node {

  // Member variables

  SpriteBox _spriteBox;
  Node _parent;

  Point _position = Point.origin;
  double _rotation = 0.0;

  Matrix4 _transformMatrix = new Matrix4.identity();
  Matrix4 _transformMatrixNodeToBox;
  Matrix4 _transformMatrixBoxToNode;

  double _scaleX = 1.0;
  double _scaleY = 1.0;

  /// The visibility of this node and its children.
  bool visible = true;

  double _zPosition = 0.0;
  int _addedOrder;
  int _childrenLastAddedOrder = 0;
  bool _childrenNeedSorting = false;

  /// Decides if the node and its children is currently paused.
  ///
  /// A paused node will not receive any input events, update calls, or run any animations.
  ///
  ///     myNodeTree.paused = true;
  bool paused = false;

  bool _userInteractionEnabled = false;

  /// If set to true the node will receive multiple pointers, otherwise it will only receive events the first pointer.
  ///
  /// This property is only meaningful if [userInteractionEnabled] is set to true. Default value is false.
  ///
  ///     class MyCustomNode extends Node {
  ///       handleMultiplePointers = true;
  ///     }
  bool handleMultiplePointers = false;
  int _handlingPointer;

  List<Node>_children = [];

  // Constructors

  /// Creates a new [Node] without any transformation.
  ///
  ///     var myNode = new Node();
  Node() {
  }

  // Property setters and getters

  /// The [SpriteBox] this node is added to, or null if it's not currently added to a [SpriteBox].
  ///
  /// For most applications it's not necessary to access the [SpriteBox] directly.
  ///
  ///     // Get the transformMode of the sprite box
  ///     var transformMode = myNode.spriteBox.transformMode;
  SpriteBox get spriteBox => _spriteBox;

  /// The parent of this node, or null if it doesn't have a parent.
  ///
  ///     // Hide the parent
  ///     myNode.parent.visible = false;
  Node get parent => _parent;

  /// The rotation of this node in degrees.
  ///
  ///     myNode.rotation = 45.0;
  double get rotation => _rotation;
  
  void set rotation(double rotation) {
    assert(rotation != null);
    _rotation = rotation;
    _invalidateTransformMatrix();
  }

  /// The position of this node relative to its parent.
  ///
  ///     myNode.position = new Point(42.0, 42.0);
  Point get position => _position;
  
  void set position(Point position) {
    assert(position != null);
    _position = position;
    _invalidateTransformMatrix();
  }

  /// The draw order of this node compared to its parent and its siblings.
  ///
  /// By default nodes are drawn in the order that they have been added to a parent. To override this behavior the
  /// [zPosition] property can be used. A higher value of this property will force the node to be drawn in front of
  /// siblings that have a lower value. If a negative value is used the node will be drawn behind its parent.
  ///
  ///     nodeInFront.zPosition = 1.0;
  ///     nodeBehind.zPosition = -1.0;
  double get zPosition => _zPosition;

  void set zPosition(double zPosition) {
    assert(zPosition != null);
    _zPosition = zPosition;
    if (_parent != null) {
      _parent._childrenNeedSorting = true;
    }
  }

  /// The scale of this node relative its parent.
  ///
  /// The [scale] property is only valid if [scaleX] and [scaleY] are equal values.
  ///
  ///     myNode.scale = 5.0;
  double get scale {
    assert(_scaleX == _scaleY);
    return _scaleX;
  }

  void set scale(double scale) {
    assert(scale != null);
    _scaleX = _scaleY = scale;
    _invalidateTransformMatrix();
  }

  /// The horizontal scale of this node relative its parent.
  ///
  ///     myNode.scaleX = 5.0;
  double get scaleX => _scaleX;

  void set scaleX(double scaleX) {
    assert(scaleX != null);
    _scaleX = scaleX;
    _invalidateTransformMatrix();
  }

  /// The vertical scale of this node relative its parent.
  ///
  ///     myNode.scaleY = 5.0;
  double get scaleY => _scaleY;

  void set scaleY(double scaleY) {
    assert(scaleY != null);
    _scaleY = scaleY;
    _invalidateTransformMatrix();
  }

  /// A list of the children of this node.
  ///
  /// This list should only be modified by using the [addChild] and [removeChild] methods.
  ///
  ///     // Iterate over a nodes children
  ///     for (Node child in myNode.children) {
  ///       // Do something with the child
  ///     }
  List<Node> get children {
    _sortChildren();
    return _children;
  }

  // Adding and removing children

  /// Adds a child to this node.
  ///
  /// The same node cannot be added to multiple nodes.
  ///
  ///     addChild(new Sprite(myImage));
  void addChild(Node child) {
    assert(child != null);
    assert(child._parent == null);

    _childrenNeedSorting = true;
    _children.add(child);
    child._parent = this;
    child._spriteBox = this._spriteBox;
    _childrenLastAddedOrder += 1;
    child._addedOrder = _childrenLastAddedOrder;
    if (_spriteBox != null) _spriteBox._eventTargets = null;
  }

  /// Removes a child from this node.
  ///
  ///     removeChild(myChildNode);
  void removeChild(Node child) {
    assert(child != null);
    if (_children.remove(child)) {
      child._parent = null;
      child._spriteBox = null;
      if (_spriteBox != null) _spriteBox._eventTargets = null;
    }
  }

  /// Removes this node from its parent node.
  ///
  ///     removeFromParent();
  void removeFromParent() {
    assert(_parent != null);
    _parent.removeChild(this);
  }

  /// Removes all children of this node.
  ///
  ///     removeAllChildren();
  void removeAllChildren() {
    for (Node child in _children) {
      child._parent = null;
      child._spriteBox = null;
    }
    _children = [];
    _childrenNeedSorting = false;
    if (_spriteBox != null) _spriteBox._eventTargets = null;
  }

  void _sortChildren() {
    // Sort children primarily by zPosition, secondarily by added order
    if (_childrenNeedSorting) {
      _children.sort((Node a, Node b) {
        if (a._zPosition == b._zPosition) {
          return a._addedOrder - b._addedOrder;
        }
        else if (a._zPosition > b._zPosition) {
          return 1;
        }
        else {
          return -1;
        }
      });
      _childrenNeedSorting = false;
    }
  }

  // Calculating the transformation matrix

  /// The transformMatrix describes the transformation from the node's parent.
  ///
  /// You cannot set the transformMatrix directly, instead use the position, rotation and scale properties.
  ///
  ///     Matrix4 matrix = myNode.transformMatrix;
  Matrix4 get transformMatrix {
    if (_transformMatrix != null) {
      return _transformMatrix;
    }
    
    double cx, sx, cy, sy;
    
    if (_rotation == 0.0) {
      cx = 1.0;
      sx = 0.0;
      cy = 1.0;
      sy = 0.0;
    }
    else {
      double radiansX = convertDegrees2Radians(_rotation);
      double radiansY = convertDegrees2Radians(_rotation);
      
      cx = Math.cos(radiansX);
      sx = Math.sin(radiansX);
      cy = Math.cos(radiansY);
      sy = Math.sin(radiansY);
    }

    // Create transformation matrix for scale, position and rotation
    _transformMatrix = new Matrix4(cy * _scaleX, sy * _scaleX, 0.0, 0.0,
               -sx * _scaleY, cx * _scaleY, 0.0, 0.0,
               0.0, 0.0, 1.0, 0.0,
              _position.x, _position.y, 0.0, 1.0);
    
    return _transformMatrix;
  }

  void _invalidateTransformMatrix() {
    _transformMatrix = null;
    _invalidateToBoxTransformMatrix();
  }

  void _invalidateToBoxTransformMatrix () {
    _transformMatrixNodeToBox = null;
    _transformMatrixBoxToNode = null;

    for (Node child in children) {
      child._invalidateToBoxTransformMatrix();
    }
  }

  // Transforms to other nodes

  Matrix4 _nodeToBoxMatrix() {
    assert(_spriteBox != null);
    if (_transformMatrixNodeToBox != null) {
      return _transformMatrixNodeToBox;
    }

    if (_parent == null) {
      // Base case, we are at the top
      assert(this == _spriteBox.rootNode);
      _transformMatrixNodeToBox = new Matrix4.copy(_spriteBox.transformMatrix).multiply(transformMatrix);
    }
    else {
      _transformMatrixNodeToBox = new Matrix4.copy(_parent._nodeToBoxMatrix()).multiply(transformMatrix);
    }
    return _transformMatrixNodeToBox;
  }

  Matrix4 _boxToNodeMatrix() {
    assert(_spriteBox != null);

    if (_transformMatrixBoxToNode != null) {
      return _transformMatrixBoxToNode;
    }

    _transformMatrixBoxToNode = new Matrix4.copy(_nodeToBoxMatrix());
    _transformMatrixBoxToNode.invert();

    return _transformMatrixBoxToNode;
  }

  /// Converts a point from the coordinate system of the [SpriteBox] to the local coordinate system of the node.
  ///
  /// This method is particularly useful when handling pointer events and need the pointers position in a local
  /// coordinate space.
  ///
  ///     Point localPoint = myNode.convertPointToNodeSpace(pointInBoxCoordinates);
  Point convertPointToNodeSpace(Point boxPoint) {
    assert(boxPoint != null);
    assert(_spriteBox != null);

    Vector4 v =_boxToNodeMatrix().transform(new Vector4(boxPoint.x, boxPoint.y, 0.0, 1.0));
    return new Point(v[0], v[1]);
  }

  /// Converts a point from the local coordinate system of the node to the coordinate system of the [SpriteBox].
  ///
  ///     Point pointInBoxCoordinates = myNode.convertPointToBoxSpace(localPoint);
  Point convertPointToBoxSpace(Point nodePoint) {
    assert(nodePoint != null);
    assert(_spriteBox != null);

    Vector4 v =_nodeToBoxMatrix().transform(new Vector4(nodePoint.x, nodePoint.y, 0.0, 1.0));
    return new Point(v[0], v[1]);
  }

  /// Converts a [point] from another [node]s coordinate system into the local coordinate system of this node.
  ///
  ///     Point pointInNodeASpace = nodeA.convertPointFromNode(pointInNodeBSpace, nodeB);
  Point convertPointFromNode(Point point, Node node) {
    assert(node != null);
    assert(point != null);
    assert(_spriteBox != null);
    assert(_spriteBox == node._spriteBox);

    Point boxPoint = node.convertPointToBoxSpace(point);
    Point localPoint = convertPointToNodeSpace(boxPoint);

    return localPoint;
  }

  // Hit test

  /// Returns true if the [point] is inside the node, the [point] is in the local coordinate system of the node.
  ///
  ///     myNode.isPointInside(localPoint);
  ///
  /// [NodeWithSize] provides a basic bounding box check for this method, if you require a more detailed check this
  /// method can be overridden.
  ///
  ///     bool isPointInside (Point nodePoint) {
  ///       double minX = -size.width * pivot.x;
  ///       double minY = -size.height * pivot.y;
  ///       double maxX = minX + size.width;
  ///       double maxY = minY + size.height;
  ///       return (nodePoint.x >= minX && nodePoint.x < maxX &&
  ///       nodePoint.y >= minY && nodePoint.y < maxY);
  ///     }
  bool isPointInside(Point point) {
    assert(point != null);

    return false;
  }

  // Rendering
  
  void _visit(RenderCanvas canvas) {
    assert(canvas != null);
    if (!visible) return;

    _prePaint(canvas);
    _visitChildren(canvas);
    _postPaint(canvas);
  }
  
  void _prePaint(RenderCanvas canvas) {
    canvas.save();

    // Get the transformation matrix and apply transform
    canvas.concat(transformMatrix.storage);
  }

  /// Paints this node to the canvas.
  ///
  /// Subclasses, such as [Sprite], override this method to do the actual painting of the node. To do custom
  /// drawing override this method and make calls to the [canvas] object. All drawing is done in the node's local
  /// coordinate system, relative to the node's position. If you want to make the drawing relative to the node's
  /// bounding box's origin, override [NodeWithSize] and call the applyTransformForPivot method before making calls for
  /// drawing.
  ///
  ///     void paint(RenderCanvas canvas) {
  ///       canvas.save();
  ///       applyTransformForPivot(canvas);
  ///
  ///       // Do painting here
  ///
  ///       canvas.restore();
  ///     }
  void paint(RenderCanvas canvas) {
  }
 
  void _visitChildren(RenderCanvas canvas) {
    // Sort children if needed
    _sortChildren();

    int i = 0;

    // Visit children behind this node
    while (i < _children.length) {
      Node child = _children[i];
      if (child.zPosition >= 0.0) break;
      child._visit(canvas);
      i++;
    }

    // Paint this node
    paint(canvas);

    // Visit children in front of this node
    while (i < _children.length) {
      Node child = _children[i];
      child._visit(canvas);
      i++;
    }
  }
  
  void _postPaint(RenderCanvas canvas) {
    canvas.restore();
  }

  // Receiving update calls

  /// Called before a frame is drawn.
  ///
  /// Override this method to do any updates to the node or node tree before it's drawn to screen.
  ///
  ///     // Make the node rotate at a fixed speed
  ///     void update(double dt) {
  ///       rotation = rotation * 10.0 * dt;
  ///     }
  void update(double dt) {
  }

  /// Called whenever the [SpriteBox] is modified or resized, or if the device is rotated.
  ///
  /// Override this method to do any updates that may be necessary to correctly display the node or node tree with the
  /// new layout of the [SpriteBox].
  ///
  ///     void spriteBoxPerformedLayout() {
  ///       // Move some stuff around here
  ///     }
  void spriteBoxPerformedLayout() {
  }

  // Handling user interaction

  /// The node will receive user interactions, such as pointer (touch or mouse) events.
  ///
  ///     class MyCustomNode extends NodeWithSize {
  ///       userInteractionEnabled = true;
  ///     }
  bool get userInteractionEnabled => _userInteractionEnabled;

  void set userInteractionEnabled(bool userInteractionEnabled) {
    _userInteractionEnabled = userInteractionEnabled;
    if (_spriteBox != null) _spriteBox._eventTargets = null;
  }

  /// Handles an event, such as a pointer (touch or mouse) event.
  ///
  /// Override this method to handle events. The node will only receive events if the [userInteractionEnabled] property
  /// is set to true and the [isPointInside] method returns true for the position of the pointer down event (default
  /// behavior provided by [NodeWithSize]). Unless [handleMultiplePointers] is set to true, the node will only receive
  /// events for the first pointer that is down.
  ///
  /// Return true if the node has consumed the event, if an event is consumed it will not be passed on to nodes behind
  /// the current node.
  ///
  ///     // MyTouchySprite gets transparent when we touch it
  ///     class MyTouchySprite extends Sprite {
  ///
  ///       MyTouchySprite(Image img) : super (img) {
  ///         userInteractionEnabled = true;
  ///       }
  ///
  ///       bool handleEvent(SpriteBoxEvent event) {
  ///         if (event.type == 'pointerdown) {
  ///           opacity = 0.5;
  ///         }
  ///         else if (event.type == 'pointerup') {
  ///           opacity = 1.0;
  ///         }
  ///         return true;
  ///       }
  ///     }
  bool handleEvent(SpriteBoxEvent event) {
    return false;
  }
}