// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'label_and_value.dart';
import 'semantics.dart';

/// Renders a piece of alert.
///
/// Uses the ARIA role "alert".
///
/// An alert is similar to [SemanticStatus], but with a higher importantness.
/// For example, a form validation error text.
class SemanticAlert extends SemanticRole {
  SemanticAlert(SemanticsObject semanticsObject)
    : super.withBasics(
        EngineSemanticsRole.alert,
        semanticsObject,
        preferredLabelRepresentation: LabelRepresentation.ariaLabel,
      ) {
    setAriaRole('alert');
  }

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
}

/// Renders a piece of status.
///
/// Uses the ARIA role "status".
///
/// A status is typically used for status updates, such as loading messages,
/// which do not justify to be [SemanticAlert]s.
class SemanticStatus extends SemanticRole {
  SemanticStatus(SemanticsObject semanticsObject)
    : super.withBasics(
        EngineSemanticsRole.status,
        semanticsObject,
        preferredLabelRepresentation: LabelRepresentation.ariaLabel,
      ) {
    setAriaRole('status');
  }

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
}
