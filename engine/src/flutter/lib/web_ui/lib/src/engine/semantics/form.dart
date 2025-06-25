// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../dom.dart';
import '../semantics.dart';

/// Indicates a form.
///
/// Uses aria form role to convey this semantic information to the element.
///
/// Screen-readers take advantage of "aria-label" to describe the visual.
class SemanticForm extends SemanticRole {
  SemanticForm(SemanticsObject semanticsObject)
    : super.withBasics(
        EngineSemanticsRole.form,
        semanticsObject,
        preferredLabelRepresentation: LabelRepresentation.ariaLabel,
      ) {}

  @override
  DomElement createElement() {
    final DomElement element = domDocument.createElement('form');
    return element;
  }

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
}
