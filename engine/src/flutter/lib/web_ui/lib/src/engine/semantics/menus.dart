// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/ui.dart' as ui;

import 'dart:typed_data';
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
    if (semanticsObject.hasExpandedState) {
      setAttribute('aria-haspopup', 'menu');
    }
    addTappable();
  }

  @override
  void update() {
    super.update();
    if (semanticsObject.isFlagsDirty) {
      addDisabledBehavior();
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
  }

  @override
  void update() {
    super.update();

    if (semanticsObject.isFlagsDirty) {
      addCheckedBehavior();
      addDisabledBehavior();
    }
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
  }

  @override
  void update() {
    super.update();
    if (semanticsObject.isFlagsDirty) {
      addCheckedBehavior();
      addDisabledBehavior();
    }
  }

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
}
