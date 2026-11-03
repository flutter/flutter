// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'label_and_value.dart';
import 'semantics.dart';

/// Indicates a list container.
///
/// Uses aria list role to convey this semantic information to the element.
///
/// Screen-readers take advantage of "aria-label" to describe the visual.
class SemanticList extends SemanticRole {
  SemanticList(SemanticsObject semanticsObject)
    : super.withBasics(
        EngineSemanticsRole.list,
        semanticsObject,
        preferredLabelRepresentation: LabelRepresentation.ariaLabel,
      ) {
    setAriaRole('list');
  }

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
}

/// Indicates an item in a list.
///
/// Uses aria listitem role to convey this semantic information to the element.
///
/// Screen-readers take advantage of "aria-label" to describe the visual.
class SemanticListItem extends SemanticRole {
  SemanticListItem(SemanticsObject semanticsObject)
    : super.withBasics(
        EngineSemanticsRole.listItem,
        semanticsObject,
        preferredLabelRepresentation: LabelRepresentation.ariaLabel,
      ) {
    setAriaRole('listitem');
  }

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
}

/// Indicates a listbox container.
///
/// Uses aria listbox role to convey this semantic information to the element.
class SemanticListBox extends SemanticRole {
  SemanticListBox(SemanticsObject semanticsObject)
    : super.withBasics(
        EngineSemanticsRole.listBox,
        semanticsObject,
        preferredLabelRepresentation: LabelRepresentation.ariaLabel,
      ) {
    setAriaRole('listbox');
  }

  @override
  void update() {
    super.update();
    if (!semanticsObject.hasLabel) {
      setAttribute('aria-label', 'Options');
    }
  }

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
}

/// Indicates a selectable option inside a listbox.
///
/// Uses aria option role to convey this semantic information to the element.
class SemanticOption extends SemanticRole {
  SemanticOption(SemanticsObject semanticsObject)
    : super.withBasics(
        EngineSemanticsRole.option,
        semanticsObject,
        preferredLabelRepresentation: LabelRepresentation.ariaLabel,
      ) {
    setAriaRole('option');
    addTappable();
  }

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
}
