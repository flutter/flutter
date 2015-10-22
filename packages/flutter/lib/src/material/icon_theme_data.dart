// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

enum IconThemeColor { white, black }

class IconThemeData {
  const IconThemeData({ this.color });
  final IconThemeColor color;

  bool operator ==(dynamic other) {
    if (other is! IconThemeData)
      return false;
    final IconThemeData typedOther = other;
    return color == typedOther.color;
  }

  int get hashCode => color.hashCode;

  String toString() => '$color';
}
