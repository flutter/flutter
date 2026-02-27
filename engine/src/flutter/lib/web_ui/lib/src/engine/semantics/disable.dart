// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'semantics.dart';

/// Adds disable behavior to a semantic node.
///
/// A disabled node would have the `aria-disabled` set to "true" if the node
/// is currently disabled (i.e. [SemanticsObject.isEnabled] is false). If the
/// node is enabled (i.e. [SemanticsObject.isEnabled]
/// is true), then `aria-disabled` is unset.
class CanDisable extends SemanticBehavior {
  CanDisable(super.semanticsObject, super.owner);

  @override
  void update() {
    if (semanticsObject.isFlagsDirty) {
      if (semanticsObject.enabledState() == EnabledState.disabled) {
        owner.setAttribute('aria-disabled', 'true');
      } else {
        owner.removeAttribute('aria-disabled');
      }
    }
  }
}
