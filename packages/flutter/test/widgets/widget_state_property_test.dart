// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  test('WidgetStateProperty.resolveWith()', () {
    final WidgetStateProperty<WidgetState> value = WidgetStateProperty.resolveWith<WidgetState>(
      (Set<WidgetState> states) => states.first,
    );
    expect(value.resolve(<WidgetState>{WidgetState.hovered}), WidgetState.hovered);
    expect(value.resolve(<WidgetState>{WidgetState.focused}), WidgetState.focused);
    expect(value.resolve(<WidgetState>{WidgetState.pressed}), WidgetState.pressed);
    expect(value.resolve(<WidgetState>{WidgetState.dragged}), WidgetState.dragged);
    expect(value.resolve(<WidgetState>{WidgetState.selected}), WidgetState.selected);
    expect(value.resolve(<WidgetState>{WidgetState.disabled}), WidgetState.disabled);
    expect(value.resolve(<WidgetState>{WidgetState.error}), WidgetState.error);
  });

  test('WidgetStateProperty.all()', () {
    final WidgetStateProperty<int> value = WidgetStateProperty.all<int>(123);
    expect(value.resolve(<WidgetState>{WidgetState.hovered}), 123);
    expect(value.resolve(<WidgetState>{WidgetState.focused}), 123);
    expect(value.resolve(<WidgetState>{WidgetState.pressed}), 123);
    expect(value.resolve(<WidgetState>{WidgetState.dragged}), 123);
    expect(value.resolve(<WidgetState>{WidgetState.selected}), 123);
    expect(value.resolve(<WidgetState>{WidgetState.disabled}), 123);
    expect(value.resolve(<WidgetState>{WidgetState.error}), 123);
  });

  test('WidgetStatePropertyAll', () {
    const WidgetStatePropertyAll<int> value = WidgetStatePropertyAll<int>(123);
    expect(value.resolve(<WidgetState>{}), 123);
    expect(value.resolve(<WidgetState>{WidgetState.hovered}), 123);
    expect(value.resolve(<WidgetState>{WidgetState.focused}), 123);
    expect(value.resolve(<WidgetState>{WidgetState.pressed}), 123);
    expect(value.resolve(<WidgetState>{WidgetState.dragged}), 123);
    expect(value.resolve(<WidgetState>{WidgetState.selected}), 123);
    expect(value.resolve(<WidgetState>{WidgetState.disabled}), 123);
    expect(value.resolve(<WidgetState>{WidgetState.error}), 123);
  });

  test('toString formats correctly', () {
    const WidgetStateProperty<Color?> colorProperty = WidgetStatePropertyAll<Color?>(Color(0xFFFFFFFF));
    expect(colorProperty.toString(), equals('WidgetStatePropertyAll(Color(0xffffffff))'));

    const WidgetStateProperty<double?> doubleProperty = WidgetStatePropertyAll<double?>(33 + 1/3);
    expect(doubleProperty.toString(), equals('WidgetStatePropertyAll(33.3)'));
  });

  test("Can interpolate between two WidgetStateProperty's", () {
    const WidgetStateProperty<TextStyle?> textStyle1 =  WidgetStatePropertyAll<TextStyle?>(
      TextStyle(fontSize: 14.0),
    );
    const WidgetStateProperty<TextStyle?> textStyle2 = WidgetStatePropertyAll<TextStyle?>(
      TextStyle(fontSize: 20.0),
    );

    // Using `0.0` interpolation value.
    TextStyle textStyle = WidgetStateProperty.lerp<TextStyle?>(
      textStyle1,
      textStyle2,
      0.0,
      TextStyle.lerp,
    )!.resolve(enabled)!;
    expect(textStyle.fontSize, 14.0);

    // Using `0.5` interpolation value.
    textStyle = WidgetStateProperty.lerp<TextStyle?>(
      textStyle1,
      textStyle2,
      0.5,
      TextStyle.lerp,
    )!.resolve(enabled)!;
    expect(textStyle.fontSize, 17.0);

    // Using `1.0` interpolation value.
    textStyle = WidgetStateProperty.lerp<TextStyle?>(
      textStyle1,
      textStyle2,
      1.0,
      TextStyle.lerp,
    )!.resolve(enabled)!;
    expect(textStyle.fontSize, 20.0);
  });

  test('WidgetStateBorderSide.lerp()', () {
    const WidgetStateProperty<BorderSide?> borderSide1 =  WidgetStatePropertyAll<BorderSide?>(
      BorderSide(
        color: Color(0xffff0000),
        width: 4.0,
      ),
    );
    const WidgetStateProperty<BorderSide?> borderSide2 = WidgetStatePropertyAll<BorderSide?>(
      BorderSide(
        color: Color(0xff0000ff),
        width: 12.0,
      ),
    );

    // Using `0.0` interpolation value.
    BorderSide borderSide = WidgetStateBorderSide.lerp(
      borderSide1,
      borderSide2,
      0.0,
    )!.resolve(enabled)!;
    expect(borderSide.color, const Color(0xffff0000));
    expect(borderSide.width, 4.0);

    // Using `0.5` interpolation value.
    borderSide = WidgetStateBorderSide.lerp(
      borderSide1,
      borderSide2,
      0.5,
    )!.resolve(enabled)!;
    expect(borderSide.color, const Color(0xff7f007f));
    expect(borderSide.width, 8.0);

    // Using `1.0` interpolation value.
    borderSide = WidgetStateBorderSide.lerp(
      borderSide1,
      borderSide2,
      1.0,
    )!.resolve(enabled)!;
    expect(borderSide.color, const Color(0xff0000ff));
    expect(borderSide.width, 12.0);
  });
}

Set<WidgetState> enabled = <WidgetState>{};
