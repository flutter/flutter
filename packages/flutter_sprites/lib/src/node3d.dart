part of flutter_sprites;

/// An node that transforms its children using a 3D perspective projection. This
/// node type can be used to create 3D flips and other similar effects.
///
///     var myNode3D = new Node3D();
///     myNode3D.rotationY = 45.0;
///     myNode3D.addChild(new Sprite(myTexture));
class Node3D extends Node {

  double _rotationX = 0.0;

  /// The node's rotation around the x axis in degrees.
  double get rotationX => _rotationX;

  set rotationX(double rotationX) {
    _rotationX = rotationX;
    invalidateTransformMatrix();
  }

  double _rotationY = 0.0;

  /// The node's rotation around the y axis in degrees.
  double get rotationY => _rotationY;

  set rotationY(double rotationY) {
    _rotationY = rotationY;
    invalidateTransformMatrix();
  }

  double _projectionDepth = 500.0;

  /// The projection depth. Default value is 500.0.
  double get projectionDepth => _projectionDepth;

  set projectionDepth(double projectionDepth) {
    _projectionDepth = projectionDepth;
    invalidateTransformMatrix();
  }

  Matrix4 computeTransformMatrix() {
    // Apply normal 2d transforms
    Matrix4 matrix = super.computeTransformMatrix();

    // Apply perspective projection
    Matrix4 projection = new Matrix4(1.0, 0.0, 0.0, 0.0,
                                     0.0, 1.0, 0.0, 0.0,
                                     0.0, 0.0, 1.0, -1.0/_projectionDepth,
                                     0.0, 0.0, 0.0, 1.0);
    matrix = matrix.multiply(projection);

    // Rotate around x and y axis
    matrix.rotateY(radians(_rotationY));
    matrix.rotateX(radians(_rotationX));

    return matrix;
  }
}
