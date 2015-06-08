// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart.sky;

class Color {
  final int _value;
  int get value => _value;

  const Color(this._value);
  const Color.fromARGB(int a, int r, int g, int b) :
    _value = (((a & 0xff) << 24) |
              ((r & 0xff) << 16) |
              ((g & 0xff) << 8) |
              ((b & 0xff) << 0));

  int get alpha => (0xff000000 & _value) >> 24;
  int get red => (0x00ff0000 & _value) >> 16;
  int get green => (0x0000ff00 & _value) >> 8;
  int get blue => (0x000000ff & _value) >> 0;

  bool operator ==(other) => other is Color && _value == other._value;

  int get hashCode => _value.hashCode;
  String toString() => "Color(0x${_value.toRadixString(16).padLeft(8, '0')})";
}
