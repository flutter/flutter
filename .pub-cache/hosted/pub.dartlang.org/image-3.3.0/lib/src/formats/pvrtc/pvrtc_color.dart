abstract class PvrtcColorRgbCore<T> {
  T copy();

  void setMin(T c);

  void setMax(T c);
}

class PvrtcColorRgb extends PvrtcColorRgbCore<PvrtcColorRgb> {
  int r;
  int g;
  int b;

  PvrtcColorRgb([this.r = 0, this.g = 0, this.b = 0]);

  PvrtcColorRgb.from(PvrtcColorRgb other)
      : r = other.r,
        g = other.g,
        b = other.b;

  @override
  PvrtcColorRgb copy() => PvrtcColorRgb.from(this);

  PvrtcColorRgb operator *(int x) => PvrtcColorRgb(r * x, g * x, b * x);

  PvrtcColorRgb operator +(PvrtcColorRgb x) =>
      PvrtcColorRgb(r + x.r, g + x.g, b + x.b);

  PvrtcColorRgb operator -(PvrtcColorRgb x) =>
      PvrtcColorRgb(r - x.r, g - x.g, b - x.b);

  int dotProd(PvrtcColorRgb x) => r * x.r + g * x.g + b * x.b;

  @override
  void setMin(PvrtcColorRgb c) {
    if (c.r < r) {
      r = c.r;
    }
    if (c.g < g) {
      g = c.g;
    }
    if (c.b < b) {
      b = c.b;
    }
  }

  @override
  void setMax(PvrtcColorRgb c) {
    if (c.r > r) {
      r = c.r;
    }
    if (c.g > g) {
      g = c.g;
    }
    if (c.b > b) {
      b = c.b;
    }
  }
}

class PvrtcColorRgba extends PvrtcColorRgbCore<PvrtcColorRgba> {
  int r;
  int g;
  int b;
  int a;

  PvrtcColorRgba([this.r = 0, this.g = 0, this.b = 0, this.a = 0]);

  PvrtcColorRgba.from(PvrtcColorRgba other)
      : r = other.r,
        g = other.g,
        b = other.b,
        a = other.a;

  @override
  PvrtcColorRgba copy() => PvrtcColorRgba.from(this);

  PvrtcColorRgba operator *(int x) =>
      PvrtcColorRgba(r * x, g * x, b * x, a * x);

  PvrtcColorRgba operator +(PvrtcColorRgba x) =>
      PvrtcColorRgba(r + x.r, g + x.g, b + x.b, a + x.a);

  PvrtcColorRgba operator -(PvrtcColorRgba x) =>
      PvrtcColorRgba(r - x.r, g - x.g, b - x.b, a - x.a);

  int dotProd(PvrtcColorRgba x) => r * x.r + g * x.g + b * x.b + a * x.a;

  @override
  void setMin(PvrtcColorRgba c) {
    if (c.r < r) {
      r = c.r;
    }
    if (c.g < g) {
      g = c.g;
    }
    if (c.b < b) {
      b = c.b;
    }
    if (c.a < a) {
      a = c.a;
    }
  }

  @override
  void setMax(PvrtcColorRgba c) {
    if (c.r > r) {
      r = c.r;
    }
    if (c.g > g) {
      g = c.g;
    }
    if (c.b > b) {
      b = c.b;
    }
    if (c.a > a) {
      a = c.a;
    }
  }
}
