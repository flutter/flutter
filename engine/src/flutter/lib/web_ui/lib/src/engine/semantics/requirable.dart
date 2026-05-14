// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'semantics.dart';

/// Adds requirability behavior to a semantic node.
///
/// A requirable node has the `aria-required` attribute set to "true" if the node
/// is currently required (i.e. [SemanticsObject.isRequired] is true), and set
/// to "false" if it's not required (i.e. [SemanticsObject.isRequired] is false).
/// If the node is not requirable (i.e. [SemanticsObject.isRequirable] is false),
/// then `aria-required` is unset.
class Requirable extends SemanticBehavior {
  Requirable(super.semanticsObject, super.owner);

  @override
  void update() {
    if (semanticsObject.isFlagsDirty) {
      if (semanticsObject.isRequirable) {
        owner.setAttribute('aria-required', semanticsObject.isRequired);
      } else {
        owner.removeAttribute('aria-required');
      }
    }
  }
}
