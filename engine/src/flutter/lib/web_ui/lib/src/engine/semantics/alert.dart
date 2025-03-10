// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'label_and_value.dart';
import 'semantics.dart';

/// Renders a piece of alert.
///
/// Uses the ARIA role "alert".
class SemanticAlert extends SemanticRole {
  SemanticHeader(SemanticsObject semanticsObject)
      : super.withBasics(
    EngineSemanticsRole.alert,
    semanticsObject,
    preferredLabelRepresentation: LabelRepresentation.ariaLabel,
  );

  @override
  DomElement createElement() => createDomElement('header');

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
}
