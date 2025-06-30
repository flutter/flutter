// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/ui.dart' as ui;

import 'label_and_value.dart';
import 'semantics.dart';

/// Indicates a menu element.
///
/// Uses aria menu role to convey this semantic information to the element.
///
/// Screen-readers takes advantage of "aria-label" to describe the visual.
class SemanticMenu extends SemanticRole {
  SemanticMenu(SemanticsObject semanticsObject)
    : super.withBasics(
        EngineSemanticsRole.menu,
        semanticsObject,
        preferredLabelRepresentation: LabelRepresentation.ariaLabel,
      ) {
    setAriaRole('menu');
  }

  @override
  void update() {
    super.update();
    // Menu items in DropdownButton, PopupMenuButton and MenuAnchor are not the
    // immediate children of the menu, so we need to set `aria-owns` on menu.
    // When the menu is open, the tree is still the old one without the menu
    // item information, so `addOneTimePostUpdateCallback` is called here to get
    // the latest tree info.
    semanticsObject.owner.addOneTimePostUpdateCallback(_updateMenuItemId);
  }

  bool _isMenuItem(SemanticsObject semanticsObject) {
    return semanticsObject.role == ui.SemanticsRole.menuItem ||
        semanticsObject.role == ui.SemanticsRole.menuItemCheckbox ||
        semanticsObject.role == ui.SemanticsRole.menuItemRadio;
  }

  // Starting from the current semantics node, this method traverses the
  // semantics tree and collects the menu items by checking whether the role of
  // the node is [menuItem], then set `aria-owns` attribute to them.
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
      if (tree[child] != null && _isMenuItem(tree[child]!)) {
        ids.add(child);
      } else {
        if (tree[child]?.childrenInTraversalOrder != null) {
          queue.addAll(tree[child]!.childrenInTraversalOrder!);
        }
      }
    }

    final String attributeValue = ids.map((id) => '$kFlutterSemanticNodePrefix$id').join(' ');
    setAttribute('aria-owns', attributeValue);
  }

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
}

/// Indicates a menu bar element.
///
/// Uses aria menubar role to convey this semantic information to the element.
///
/// Screen-readers takes advantage of "aria-label" to describe the visual.
class SemanticMenuBar extends SemanticRole {
  SemanticMenuBar(SemanticsObject semanticsObject)
    : super.withBasics(
        EngineSemanticsRole.menuBar,
        semanticsObject,
        preferredLabelRepresentation: LabelRepresentation.ariaLabel,
      ) {
    setAriaRole('menubar');
  }

  @override
  void update() {
    super.update();
    // Menu items in Menu bar are not the immediate children of the menu, so we
    // need to set `aria-owns` on menu bar. When the menu is open, the tree is
    // still the old one without the menu item information, so
    // `addOneTimePostUpdateCallback` is called to get the latest tree info.
    semanticsObject.owner.addOneTimePostUpdateCallback(_updateMenuItemId);
  }

  bool _isMenuItem(SemanticsObject semanticsObject) {
    return semanticsObject.role == ui.SemanticsRole.menuItem ||
        semanticsObject.role == ui.SemanticsRole.menuItemCheckbox ||
        semanticsObject.role == ui.SemanticsRole.menuItemRadio;
  }

  // Starting from the current semantics node, this method traverses the
  // semantics tree and collects the menu items by checking whether the role of
  // the node is [menuItem], then set `aria-owns` attribute to them.
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
      if (tree[child] != null && _isMenuItem(tree[child]!)) {
        ids.add(child);
      } else {
        if (tree[child]?.childrenInTraversalOrder != null) {
          queue.addAll(tree[child]!.childrenInTraversalOrder!);
        }
      }
    }

    final String attributeValue = ids.map((id) => '$kFlutterSemanticNodePrefix$id').join(' ');
    setAttribute('aria-owns', attributeValue);
  }

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
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
