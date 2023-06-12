import '../image/image.dart';

/// Find the minimum and maximum color value in the image.
/// Returns a list as \[min, max\].
List<num> minMax(Image image) {
  var first = true;
  num min = 0;
  num max = 0;
  for (final p in image) {
    for (var c in p) {
      if (first || c < min) {
        min = c;
      }
      if (first || c > max) {
        max = c;
      }
    }
    first = false;
  }

  return [min, max];
}
