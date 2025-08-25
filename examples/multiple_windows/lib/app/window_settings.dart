// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class WindowSettings extends ChangeNotifier {
  WindowSettings({Size regularSize = const Size(400, 300)})
    : _regularSize = regularSize;

  WindowSettings.clone(WindowSettings other)
    : this(regularSize: other.regularSize);

  Size _regularSize;
  Size get regularSize => _regularSize;
  set regularSize(Size value) {
    _regularSize = value;
    notifyListeners();
  }

  void from(WindowSettings settings) {
    _regularSize = settings.regularSize;
    notifyListeners();
  }
}
