// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'label_and_value.dart';
import 'semantics.dart';

/// Indicates a combo box element.
///
/// Uses aria combobox role to convey this semantic information to the element.
///
/// Screen-readers takes advantage of "aria-label" to describe the visual.
class SemanticComboBox extends SemanticRole {
  SemanticComboBox(SemanticsObject semanticsObject)
    : super.withBasics(
        EngineSemanticsRole.comboBox,
        semanticsObject,
        preferredLabelRepresentation: LabelRepresentation.ariaLabel,
      ) {
    setAriaRole('combobox');
    setAttribute('aria-expanded', 'false');
    setAttribute('aria-autocomplete', 'list');
    setAttribute('aria-activedescendant', '');
  }

  @override
  void update() {
    super.update();
    if (semanticsObject.isExpanded) {
      setAttribute('aria-expanded', 'true');
      final Map<int, SemanticsObject> tree = semanticsObject.owner.semanticsTree;
      List<int> ids = [];
      int root = semanticsObject.id;
      List<int> queue = [];
      if (tree[root]?.childrenInTraversalOrder != null) {
        queue.addAll(tree[root]!.childrenInTraversalOrder!);
      }
      while (queue.isNotEmpty) {
        int child = queue.removeAt(0);

        if (tree[child] != null && tree[child]?.hasLabel != null && tree[child]!.hasLabel!) {
          ids.add(child);
        }
        if (tree[child]?.childrenInTraversalOrder != null) {
          queue.addAll(tree[child]!.childrenInTraversalOrder!);
        }
      }
      for (int id in ids) {
        if (tree[id]!.label! == semanticsObject.label) {
          setAttribute('aria-activedescendant', 'flt-semantic-node-$id');
        }
      }
    } else {
      setAttribute('aria-expanded', 'false');
      setAttribute('aria-activedescendant', '');
    }
  }

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
}
