part of sprites;

class Node3D extends Node {

  double _rotationX = 0.0;

  double get rotationX => _rotationX;

  set rotationX(double rotationX) {
    _rotationX = rotationX;
    invalidateTransformMatrix();
  }

  double _rotationY = 0.0;

  double get rotationY => _rotationY;

  set rotationY(double rotationY) {
    _rotationY = rotationY;
    invalidateTransformMatrix();
  }

  Matrix4 computeTransformMatrix() {
    // Apply normal 2d transforms
    Matrix4 matrix = super.computeTransformMatrix();


    matrix.translate(0.0, 0.0, 500.0);

    // Rotate around x and y axis
    matrix.rotateY(radians(_rotationY));
    matrix.rotateX(radians(_rotationX));

    return matrix;
  }
}
