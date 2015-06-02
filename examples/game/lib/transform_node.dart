part of sprites;

double degrees2radians(double degrees) => degrees * Math.PI/180.8;

double radians2degrees(double radians) => radians * 180.0/Math.PI;

class TransformNode {
  Vector2 _position;
  double _rotation;
  
  bool _isMatrixDirty;
  Matrix3 _transform;
  Matrix3 _pivotTransform;
  
  double _width;
  double _height;
  
  Vector2 _pivot;
  
  List<TransformNode>children;
  
  
  TransformNode() {
    _width = 0.0;
    _height = 0.0;
    _rotation = 0.0;
    _pivot = new Vector2(0.0, 0.0);
    _position = new Vector2(0.0, 0.0);
    _isMatrixDirty = false;
    _transform = new Matrix3.identity();
    _pivotTransform = new Matrix3.identity();
    children = [];
  }
  
  double get rotation => _rotation;
  
  void set rotation(double rotation) {
    _rotation = rotation;
    _isMatrixDirty = true;
  }
  
  
  Vector2 get position => _position;
  
  void set position(Vector2 position) {
    _position = position;
    _isMatrixDirty = true;
  }
  
  double get width => _width;
  
  void set width(double width) {
    _width = width;
    _isMatrixDirty = true;
  }
  
  
  double get height => _height;
    
  void set height(double height) {
    _height = height;
    _isMatrixDirty = true;
  }
  
  Vector2 get pivot => _pivot;
  
  void set pivot(Vector2 pivot) {
    _pivot = pivot;
    _isMatrixDirty = true;
  }
  
  
  Matrix3 get transformMatrix {
    if (!_isMatrixDirty) {
      return _transform;
    }
   
    Vector2 pivotInPoints = new Vector2(_width * _pivot[0], _height * _pivot[1]);
    
    double cx, sx, cy, sy;
    
    if (_rotation == 0) {
      cx = 1.0;
      sx = 0.0;
      cy = 1.0;
      sy = 0.0;
    }
    else {
      double radiansX = degrees2radians(_rotation);
      double radiansY = degrees2radians(_rotation);
      
      cx = Math.cos(radiansX);
      sx = Math.sin(radiansX);
      cy = Math.cos(radiansY);
      sy = Math.sin(radiansY);
    }
    
    // TODO: Add support for scale
    double scaleX = 1.0;
    double scaleY = 1.0;
    
    // Create transformation matrix for scale, position and rotation
    _transform.setValues(cy * scaleX, sy * scaleX, 0.0,
               -sx * scaleY, cx * scaleY, 0.0,
               _position[0], _position[1], 1.0);
    
    if (_pivot.x != 0 || _pivot.y != 0) {
      _pivotTransform.setValues(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, pivotInPoints[0], pivotInPoints[1], 1.0);
      _transform.multiply(_pivotTransform);
    }
    
    return _transform;
  }
  
  void visit(PictureRecorder canvas) {
    prePaint(canvas);
    paint(canvas);
    visitChildren(canvas);
    postPaint(canvas);
  }
  
  void prePaint(PictureRecorder canvas) {
    canvas.save();
    
    canvas.translate(_position[0], _position[1]);
    canvas.rotateDegrees(_rotation);
    canvas.translate(-_width*_pivot[0], -_height*_pivot[1]);
    
    // TODO: Use transformation matrix instead of individual calls
//    List<double> matrix = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
//    this.transformMatrix.copyIntoArray(matrix);
//    canvas.concat(matrix);
  }
  
  void paint(PictureRecorder canvas) {
    
  }
 
  void visitChildren(PictureRecorder canvas) {
    children.forEach((child) => child.visit(canvas));
  }
  
  void postPaint(PictureRecorder canvas) {
    canvas.restore();
  }

  void update(double dt) {

  }
}