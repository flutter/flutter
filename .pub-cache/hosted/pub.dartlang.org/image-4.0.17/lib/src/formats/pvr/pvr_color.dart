abstract class PvrColorRgbCore<T> {
  T copy();

  void setMin(T c);

  void setMax(T c);
}

class PvrColorRgb extends PvrColorRgbCore<PvrColorRgb> {
  int r;
  int g;
  int b;

  PvrColorRgb([this.r = 0, this.g = 0, this.b = 0]);

  PvrColorRgb.from(PvrColorRgb other)
      : r = other.r,
        g = other.g,
        b = other.b;

  @override
  PvrColorRgb copy() => PvrColorRgb.from(this);

  PvrColorRgb operator *(int x) => PvrColorRgb(r * x, g * x, b * x);

  PvrColorRgb operator +(PvrColorRgb x) =>
      PvrColorRgb(r + x.r, g + x.g, b + x.b);

  PvrColorRgb operator -(PvrColorRgb x) =>
      PvrColorRgb(r - x.r, g - x.g, b - x.b);

  int dotProd(PvrColorRgb x) => r * x.r + g * x.g + b * x.b;

  @override
  void setMin(PvrColorRgb c) {
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
  void setMax(PvrColorRgb c) {
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

class PvrColorRgba extends PvrColorRgbCore<PvrColorRgba> {
  int r;
  int g;
  int b;
  int a;

  PvrColorRgba([this.r = 0, this.g = 0, this.b = 0, this.a = 0]);

  PvrColorRgba.from(PvrColorRgba other)
      : r = other.r,
        g = other.g,
        b = other.b,
        a = other.a;

  @override
  PvrColorRgba copy() => PvrColorRgba.from(this);

  PvrColorRgba operator *(int x) => PvrColorRgba(r * x, g * x, b * x, a * x);

  PvrColorRgba operator +(PvrColorRgba x) =>
      PvrColorRgba(r + x.r, g + x.g, b + x.b, a + x.a);

  PvrColorRgba operator -(PvrColorRgba x) =>
      PvrColorRgba(r - x.r, g - x.g, b - x.b, a - x.a);

  int dotProd(PvrColorRgba x) => r * x.r + g * x.g + b * x.b + a * x.a;

  @override
  void setMin(PvrColorRgba c) {
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
  void setMax(PvrColorRgba c) {
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
