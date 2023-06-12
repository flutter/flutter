import '../../../image.dart';

class PvrtcColorBoundingBox<Color extends PvrtcColorRgbCore<Color>> {
  Color min;
  Color max;

  PvrtcColorBoundingBox(Color min, Color max)
      : min = min.copy(),
        max = max.copy();

  void add(Color c) {
    min.setMin(c);
    max.setMax(c);
  }
}
