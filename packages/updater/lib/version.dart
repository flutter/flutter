// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

// This class represents a dot-separated version string. Used for comparing
// versions.
// Usage: assert(new Version('1.1.0') < new Version('1.2.1'));
class Version {
  Version(String versionStr) :
    _parts = versionStr.split('.').map((String val) => int.parse(val)).toList();

  List<int> _parts;

  bool operator<(Version other) => _compare(other) < 0;
  bool operator==(dynamic other) => other is Version && _compare(other) == 0;
  bool operator>(Version other) => _compare(other) > 0;

  int _compare(Version other) {
    int length = min(_parts.length, other._parts.length);
    for (int i = 0; i < length; ++i) {
      if (_parts[i] < other._parts[i])
        return -1;
      if (_parts[i] > other._parts[i])
        return 1;
    }
    return _parts.length - other._parts.length;  // results in 1.0 < 1.0.0
  }

  int get hashCode => _parts.fold(373, (int acc, int part) => 37*acc + part);
}
