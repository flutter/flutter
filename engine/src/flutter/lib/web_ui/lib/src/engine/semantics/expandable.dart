// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/ui.dart' as ui;

import 'label_and_value.dart';
import 'semantics.dart';

/// Adds expandability behavior to a semantic node.
///
/// A expanded node would have the `aria-expanded` set to "true" if the node
/// is currently expanded (i.e. [SemanticsObject.isExpanded] is true), and set
/// to "false" if it's not expanded (i.e. [SemanticsObject.isExpanded] is
/// false). If the node is not expandable (i.e. [SemanticsObject.isExpandable]
/// is false), then `aria-expanded` is unset.
class Expandable extends SemanticBehavior {
  Expandable(super.semanticsObject, super.owner);

  @override
  void update() {
    if (semanticsObject.isFlagsDirty) {
      if (semanticsObject.isExpandable) {
        owner.setAttribute('aria-expanded', semanticsObject.isExpanded);
      } else {
        owner.removeAttribute('aria-expanded');
      }
    }
  }
}
