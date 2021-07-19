// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

/// Something that can be selected by the [SelectionArea] widget, normally a render object.
abstract class Selectable {
  /// Clear the selection from the [Selectable].
  void clear();

  /// Copy the data from the selectable, returning `null` if nothing is selected.
  Object? copy();

  /// Update the selection area given the global [rect].
  void update(Rect rect);
}

/// The service used to register for selection via the [SelectionArea] widget.
abstract class SelectionService {
  /// Add this [selectable] to the current selection area.
  ///
  /// This allows the selectable to be selected.
  void add(Selectable selectable);

  /// Remove this [selectable] from the current selection area.
  void remove(Selectable selectable);
}
