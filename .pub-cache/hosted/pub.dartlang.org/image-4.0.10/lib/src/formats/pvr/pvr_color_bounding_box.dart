import 'pvr_color.dart';

class PvrColorBoundingBox<PvrColor extends PvrColorRgbCore<PvrColor>> {
  PvrColor min;
  PvrColor max;

  PvrColorBoundingBox(PvrColor min, PvrColor max)
      : min = min.copy(),
        max = max.copy();

  void add(PvrColor c) {
    min.setMin(c);
    max.setMax(c);
  }
}
