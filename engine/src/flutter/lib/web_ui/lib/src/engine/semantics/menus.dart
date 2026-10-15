// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/ui.dart' as ui;

import 'label_and_value.dart';
import 'semantics.dart';

abstract class _SemanticMenuContainerBase extends SemanticRole {
  _SemanticMenuContainerBase(super.kind, super.semanticsObject, String ariaRole)
    : super.withBasics(preferredLabelRepresentation: LabelRepresentation.ariaLabel) {
    setAriaRole(ariaRole);
  }

  @override
  void update() {
    super.update();
    // Menu items in DropdownButton, PopupMenuButton, MenuAnchor, and MenuBar are
    // not immediate children of the menu container, so set `aria-owns` after the
    // semantics tree is finalized via `addOneTimePostUpdateCallback`.
    semanticsObject.owner.addOneTimePostUpdateCallback(_updateMenuItemId);
  }

  bool _isMenuItem(SemanticsObject semanticsObject) {
    return semanticsObject.role == ui.SemanticsRole.menuItem ||
        semanticsObject.role == ui.SemanticsRole.menuItemCheckbox ||
        semanticsObject.role == ui.SemanticsRole.menuItemRadio;
  }

  // Starting from the current semantics node, traverses the semantics tree,
  // collects descendant menu items, and sets `aria-owns`.
  void _updateMenuItemId() {
    final Map<int, SemanticsObject> tree = semanticsObject.owner.semanticsTree;
    final List<int> ids = [];
    final int root = semanticsObject.id;
    final List<int> queue = [];
    if (tree[root]?.childrenInTraversalOrder != null) {
      queue.addAll(tree[root]!.childrenInTraversalOrder!);
    }
    while (queue.isNotEmpty) {
      final int child = queue.removeAt(0);
      final SemanticsObject? node = tree[child];
      if (node != null && _isMenuItem(node)) {
        ids.add(child);
      } else if (node != null) {
        if (node.childrenInTraversalOrder != null) {
          queue.addAll(node.childrenInTraversalOrder!);
        }
      }
    }

    final String attributeValue = ids.map((id) => '$kFlutterSemanticNodePrefix$id').join(' ');
    setAttribute('aria-owns', attributeValue);
  }

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
}

/// Indicates a menu element.
///
/// Uses aria menu role to convey this semantic information to the element.
///
/// Screen-readers takes advantage of "aria-label" to describe the visual.
class SemanticMenu extends _SemanticMenuContainerBase {
  SemanticMenu(SemanticsObject semanticsObject)
    : super(EngineSemanticsRole.menu, semanticsObject, 'menu');
}

/// Indicates a menu bar element.
///
/// Uses aria menubar role to convey this semantic information to the element.
///
/// Screen-readers takes advantage of "aria-label" to describe the visual.
class SemanticMenuBar extends _SemanticMenuContainerBase {
  SemanticMenuBar(SemanticsObject semanticsObject)
    : super(EngineSemanticsRole.menuBar, semanticsObject, 'menubar');
}

/// Indicates a menu item element.
///
/// Uses aria menuitem role to convey this semantic information to the element.
///
/// Screen-readers takes advantage of "aria-label" to describe the visual.
class SemanticMenuItem extends SemanticRole {
  SemanticMenuItem(SemanticsObject semanticsObject)
    : super.withBasics(
        EngineSemanticsRole.menuItem,
        semanticsObject,
        preferredLabelRepresentation: LabelRepresentation.ariaLabel,
      ) {
    setAriaRole('menuitem');
    addDisabledBehavior();
    addTappable();
  }

  @override
  void update() {
    super.update();
    if (semanticsObject.hasExpandedState) {
      setAttribute('aria-haspopup', 'menu');
    } else {
      removeAttribute('aria-haspopup');
    }
  }

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
}

/// Indicates a menu item element with a checkbox.
///
/// Uses aria menuitemcheckbox role to convey this semantic information to the element.
///
/// Screen-readers takes advantage of "aria-label" to describe the visual.
class SemanticMenuItemCheckbox extends SemanticRole {
  SemanticMenuItemCheckbox(SemanticsObject semanticsObject)
    : super.withBasics(
        EngineSemanticsRole.menuItemCheckbox,
        semanticsObject,
        preferredLabelRepresentation: LabelRepresentation.ariaLabel,
      ) {
    setAriaRole('menuitemcheckbox');
    addCheckedBehavior();
    addDisabledBehavior();
  }

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
}

/// Indicates a menu item element with a radio button.
///
/// Uses aria menuitemradio role to convey this semantic information to the element.
///
/// Screen-readers takes advantage of "aria-label" to describe the visual.
class SemanticMenuItemRadio extends SemanticRole {
  SemanticMenuItemRadio(SemanticsObject semanticsObject)
    : super.withBasics(
        EngineSemanticsRole.menuItemRadio,
        semanticsObject,
        preferredLabelRepresentation: LabelRepresentation.ariaLabel,
      ) {
    setAriaRole('menuitemradio');
    addCheckedBehavior();
    addDisabledBehavior();
  }

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
}
