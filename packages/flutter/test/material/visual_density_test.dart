import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('VisualDensity.lerp', () {
    const VisualDensity a = VisualDensity(horizontal: 1.0, vertical: .5);
    const VisualDensity b = VisualDensity(horizontal: 2.0, vertical: 1.0);

    final VisualDensity noLerp = VisualDensity.lerp(a, b, 0.0);
    expect(noLerp.horizontal, 1.0);
    expect(noLerp.vertical, .5);

    final VisualDensity quarterLerp = VisualDensity.lerp(a, b, .25);
    expect(quarterLerp.horizontal, 1.25);
    expect(quarterLerp.vertical, .625);

    final VisualDensity fullLerp = VisualDensity.lerp(a, b, 1.0);
    expect(fullLerp.horizontal, 2.0);
    expect(fullLerp.vertical, 1.0);
  });
}
