part of flutter_sprites;

/// A sequence of colors representing a gradient or a color transition over
/// time. The sequence is represented by a list of [colors] and a list of
/// [colorStops], the stops are normalized values (0.0 to 1.0) and ordered in
/// the list. Both lists have the same number of elements.
class ColorSequence {
  /// List of colors.
  List<Color> colors;

  /// List of color stops, normalized values (0.0 to 1.0) and ordered.
  List<double> colorStops;

  /// Creates a new color sequence from a list of [colors] and a list of
  /// [colorStops].
  ColorSequence(this.colors, this.colorStops) {
    assert(colors != null);
    assert(colorStops != null);
    assert(colors.length == colorStops.length);
  }

  /// Creates a new color sequence from a start and an end color.
  ColorSequence.fromStartAndEndColor(Color start, Color end) {
    colors = <Color>[start, end];
    colorStops = <double>[0.0, 1.0];
  }

  /// Creates a new color sequence by copying an existing sequence.
  ColorSequence.copy(ColorSequence sequence) {
    colors = new List<Color>.from(sequence.colors);
    colorStops = new List<double>.from(sequence.colorStops);
  }

  /// Returns the color at a normalized (0.0 to 1.0) position in the color
  /// sequence. If a color stop isn't hit, the returned color will be an
  /// interpolation of a color between two color stops.
  Color colorAtPosition(double pos) {
    assert(pos >= 0.0 && pos <= 1.0);

    if (pos == 0.0) return colors[0];

    double lastStop = colorStops[0];
    Color lastColor = colors[0];

    for (int i = 0; i < colors.length; i++) {
      double currentStop = colorStops[i];
      Color currentColor = colors[i];

      if (pos <= currentStop) {
        double blend = (pos - lastStop) / (currentStop - lastStop);
        return _interpolateColor(lastColor, currentColor, blend);
      }
      lastStop = currentStop;
      lastColor = currentColor;
    }
    return colors[colors.length-1];
  }
}

Color _interpolateColor(Color a, Color b, double blend) {
  double aa = a.alpha.toDouble();
  double ar = a.red.toDouble();
  double ag = a.green.toDouble();
  double ab = a.blue.toDouble();

  double ba = b.alpha.toDouble();
  double br = b.red.toDouble();
  double bg = b.green.toDouble();
  double bb = b.blue.toDouble();

  int na = (aa * (1.0 - blend) + ba * blend).toInt();
  int nr = (ar * (1.0 - blend) + br * blend).toInt();
  int ng = (ag * (1.0 - blend) + bg * blend).toInt();
  int nb = (ab * (1.0 - blend) + bb * blend).toInt();

  return new Color.fromARGB(na, nr, ng, nb);
}
