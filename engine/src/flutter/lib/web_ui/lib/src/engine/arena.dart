// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

abstract class Collectable {
  void collect();
}

class Arena {
  List<Collectable> _collectables = <Collectable>[];
  void add(Collectable collectable) {
    _collectables.add(collectable);
  }

  void collect() {
    final List<Collectable> collectables = _collectables;
    _collectables = <Collectable>[];
    for (final collect in collectables) {
      collect.collect();
    }
  }
}
