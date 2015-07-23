import "../resources/dom_utils.dart";
import "../resources/third_party/unittest/unittest.dart";
import "../resources/unit.dart";

import "dart:sky";
import 'package:vector_math/vector_math.dart';

void main() {
  initUnit();

  PictureRecorder recorder = new PictureRecorder();
  Canvas canvas = new Canvas(recorder, new Rect.fromLTRB(0.0, 0.0, 100.0, 100.0));

  test("matrix access should work", () {
    // Matrix equality doesn't work!
    // https://github.com/google/vector_math.dart/issues/147
    expect(canvas.getTotalMatrix(), equals(new Matrix4.identity().storage));
    Matrix4 matrix = new Matrix4.identity();
    // Round-tripping through getTotalMatrix will lose the z value
    // So only scale to 1x in the z direction.
    matrix.scale(2.0, 2.0, 1.0);
    canvas.setMatrix(matrix.storage);
    expect(canvas.getTotalMatrix(), equals(matrix.storage));
  });

}
