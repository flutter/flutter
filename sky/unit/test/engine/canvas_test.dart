import 'dart:sky' as sky;
import 'dart:sky' show Rect, Color, Paint;

import 'package:test/test.dart';
import 'package:vector_math/vector_math.dart';

void main() {

  sky.PictureRecorder recorder = new sky.PictureRecorder();
  sky.Canvas canvas = new sky.Canvas(recorder, new Rect.fromLTRB(0.0, 0.0, 100.0, 100.0));

  test("matrix access should work", () {
    // Matrix equality doesn't work!
    // https://github.com/google/vector_math.dart/issues/147
    expect(canvas.getTotalMatrix(), equals(new Matrix4.identity().storage));
    Matrix4 matrix = new Matrix4.identity();
    // Round-tripping through getTotalMatrix will lose the z value
    // So only scale to 1x in the z direction.
    matrix.scale(2.0, 2.0, 1.0);
    canvas.setMatrix(matrix.storage);
    canvas.drawPaint(new Paint()..color = const Color(0xFF00FF00));
    expect(canvas.getTotalMatrix(), equals(matrix.storage));
  });

}
