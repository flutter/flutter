// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'label_and_value.dart';
import 'semantics.dart';
import 'route.dart';

/// Indicates the container as a pop dialog
///
/// Uses aria dialog role to convey this semantic information to the element.
///
/// Setting this role will also set aria-modal to true, which helps screen
/// reader better understand this section of screen.
///
/// Screen-readers takes advantage of "aria-label" to describe the visual.
class SemanticDialog extends SemanticRole with RouteLike {
  SemanticDialog(SemanticsObject semanticsObject)
    : super.withBasics(
        EngineSemanticsRole.dialog,
        semanticsObject,
        preferredLabelRepresentation: LabelRepresentation.ariaLabel,
      ) {
    setAriaRole('dialog');
    setAttribute('aria-modal', true);
  }

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
}

/// Indicates the container as an alert dialog
///
/// Uses aria alertdialog role to convey this semantic information to the element.
///
/// Setting this role will also set aria-modal to true, which helps screen
/// reader better understand this section of screen.
///
/// Screen-readers takes advantage of "aria-label" to describe the visual.
class SemanticAlertDialog extends SemanticRole with RouteLike {
  SemanticAlertDialog(SemanticsObject semanticsObject)
    : super.withBasics(
        EngineSemanticsRole.alertDialog,
        semanticsObject,
        preferredLabelRepresentation: LabelRepresentation.ariaLabel,
      ) {
    setAriaRole('alertdialog');
    setAttribute('aria-modal', true);
  }

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
}
