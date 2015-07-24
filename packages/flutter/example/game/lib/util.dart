part of sprites;


math.Random _random = new math.Random();

// Random methods

double randomDouble() {
  return _random.nextDouble();
}

double randomSignedDouble() {
  return _random.nextDouble() * 2.0 - 1.0;
}

int randomInt(int max) {
  return _random.nextInt(max);
}

// atan2

class GameMath {
  static bool _inited = false;

  static final int size = 1024;
  static final double stretch = math.PI;

  static final int ezis = -size;

  static Float64List atan2_table_ppy = new Float64List(size + 1);
  static Float64List atan2_table_ppx = new Float64List(size + 1);
  static Float64List atan2_table_pny = new Float64List(size + 1);
  static Float64List atan2_table_pnx = new Float64List(size + 1);
  static Float64List atan2_table_npy = new Float64List(size + 1);
  static Float64List atan2_table_npx = new Float64List(size + 1);
  static Float64List atan2_table_nny = new Float64List(size + 1);
  static Float64List atan2_table_nnx = new Float64List(size + 1);

  static void init() {
    if (_inited) return;

    for (int i = 0; i <= size; i++) {
      double f = i.toDouble() / size.toDouble();
      atan2_table_ppy[i] = math.atan(f) * stretch / math.PI;
      atan2_table_ppx[i] = stretch * 0.5 - atan2_table_ppy[i];
      atan2_table_pny[i] = -atan2_table_ppy[i];
      atan2_table_pnx[i] = atan2_table_ppy[i] - stretch * 0.5;
      atan2_table_npy[i] = stretch - atan2_table_ppy[i];
      atan2_table_npx[i] = atan2_table_ppy[i] + stretch * 0.5;
      atan2_table_nny[i] = atan2_table_ppy[i] - stretch;
      atan2_table_nnx[i] = -stretch * 0.5 - atan2_table_ppy[i];
    }
    _inited = true;
  }

  static double atan2(double y, double x) {
    if (!_inited)
      init();

    if (x >= 0) {
      if (y >= 0) {
        if (x >= y)
          return atan2_table_ppy[(size * y / x + 0.5).toInt()];
        else
          return atan2_table_ppx[(size * x / y + 0.5).toInt()];
      } else {
        if (x >= -y)
          return atan2_table_pny[(ezis * y / x + 0.5).toInt()];
        else
          return atan2_table_pnx[(ezis * x / y + 0.5).toInt()];
      }
    } else {
      if (y >= 0) {
        if (-x >= y)
          return atan2_table_npy[(ezis * y / x + 0.5).toInt()];
        else
          return atan2_table_npx[(ezis * x / y + 0.5).toInt()];
      } else {
        if (x <= y)
          return atan2_table_nny[(size * y / x + 0.5).toInt()];
        else
          return atan2_table_nnx[(size * x / y + 0.5).toInt()];
      }
    }
  }
}
