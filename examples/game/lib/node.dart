part of sprites;

double convertDegrees2Radians(double degrees) => degrees * Math.PI/180.8;

double convertRadians2Degrees(double radians) => radians * 180.0/Math.PI;

class Node {

  // Member variables

  SpriteBox _spriteBox;
  Node _parent;

  Point _position;
  double _rotation;

  Matrix4 _transformMatrix;
  Matrix4 _transformMatrixNodeToBox;
  Matrix4 _transformMatrixBoxToNode;

  double _scaleX;
  double _scaleY;

  bool visible;

  double _zPosition;
  int _addedOrder;
  int _childrenLastAddedOrder;
  bool _childrenNeedSorting;

  bool paused = false;

  bool _userInteractionEnabled = false;
  bool handleMultiplePointers = false;
  int _handlingPointer;

  List<Node>_children;

  // Constructors
  
  Node() {
    _rotation = 0.0;
    _position = Point.origin;
    _scaleX = _scaleY = 1.0;
    _transformMatrix = new Matrix4.identity();
    _children = [];
    _childrenNeedSorting = false;
    _childrenLastAddedOrder = 0;
    _zPosition = 0.0;
    visible = true;
  }

  // Property setters and getters

  SpriteBox get spriteBox => _spriteBox;

  Node get parent => _parent;
  
  double get rotation => _rotation;
  
  void set rotation(double rotation) {
    assert(rotation != null);
    _rotation = rotation;
    _invalidateTransformMatrix();
  }

  Point get position => _position;
  
  void set position(Point position) {
    assert(position != null);
    _position = position;
    _invalidateTransformMatrix();
  }

  double get zPosition => _zPosition;

  void set zPosition(double zPosition) {
    assert(zPosition != null);
    _zPosition = zPosition;
    if (_parent != null) {
      _parent._childrenNeedSorting = true;
    }
  }

  double get scale {
    assert(_scaleX == _scaleY);
    return _scaleX;
  }

  void set scale(double scale) {
    assert(scale != null);
    _scaleX = _scaleY = scale;
    _invalidateTransformMatrix();
  }

  List<Node> get children => _children;

  // Adding and removing children

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

  void removeChild(Node child) {
    assert(child != null);
    if (_children.remove(child)) {
      child._parent = null;
      child._spriteBox = null;
      if (_spriteBox != null) _spriteBox._eventTargets = null;
    }
  }

  void removeFromParent() {
    assert(_parent != null);
    _parent.removeChild(this);
  }

  void removeAllChildren() {
    for (Node child in _children) {
      child._parent = null;
      child._spriteBox = null;
    }
    _children = [];
    _childrenNeedSorting = false;
    if (_spriteBox != null) _spriteBox._eventTargets = null;
  }

  // Calculating the transformation matrix
  
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

  Point convertPointToNodeSpace(Point boxPoint) {
    assert(boxPoint != null);
    assert(_spriteBox != null);

    Vector4 v =_boxToNodeMatrix().transform(new Vector4(boxPoint.x, boxPoint.y, 0.0, 1.0));
    return new Point(v[0], v[1]);
  }

  Point convertPointToBoxSpace(Point nodePoint) {
    assert(nodePoint != null);
    assert(_spriteBox != null);

    Vector4 v =_nodeToBoxMatrix().transform(new Vector4(nodePoint.x, nodePoint.y, 0.0, 1.0));
    return new Point(v[0], v[1]);
  }

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

  bool hitTest(Point nodePoint) {
    assert(nodePoint != null);

    return false;
  }

  // Rendering
  
  void visit(PictureRecorder canvas) {
    assert(canvas != null);
    if (!visible) return;

    prePaint(canvas);
    paint(canvas);
    visitChildren(canvas);
    postPaint(canvas);
  }
  
  void prePaint(PictureRecorder canvas) {
    canvas.save();

    // Get the transformation matrix and apply transform
    canvas.concat(transformMatrix.storage);
  }
  
  void paint(PictureRecorder canvas) {
  }
 
  void visitChildren(PictureRecorder canvas) {
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

    // Visit each child
    _children.forEach((child) => child.visit(canvas));
  }
  
  void postPaint(PictureRecorder canvas) {
    canvas.restore();
  }

  // Receiving update calls

  void update(double dt) {
  }

  void spriteBoxPerformedLayout() {
  }

  // Handling user interaction

  bool get userInteractionEnabled => _userInteractionEnabled;

  void set userInteractionEnabled(bool userInteractionEnabled) {
    _userInteractionEnabled = userInteractionEnabled;
    if (_spriteBox != null) _spriteBox._eventTargets = null;
  }

  bool handleEvent(SpriteBoxEvent event) {
    return false;
  }
}