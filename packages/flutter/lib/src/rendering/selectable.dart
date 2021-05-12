// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

abstract class SelectionService {
  void add(Selectable selectable);

  void remove(Selectable selectable);
}

abstract class Selectable {
  void update(Rect rect);

  Object? copy();

  void clear();
}
