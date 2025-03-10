// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'label_and_value.dart';
import 'semantics.dart';

/// Renders a piece of alert.
///
/// Uses the ARIA role "alert".
///
/// An alert is similar to [SemanticStatus], but with higher priority.
class SemanticAlert extends SemanticRole {
  SemanticAlert(SemanticsObject semanticsObject)
    : super.withBasics(
        EngineSemanticsRole.alert,
        semanticsObject,
        preferredLabelRepresentation: LabelRepresentation.ariaLabel,
      );

  @override
  DomElement createElement() => createDomElement('alert');

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
}

/// Renders a piece of status.
///
/// Uses the ARIA role "status".
///
/// A status is usually a current status update, such as loading messages, that
/// does not justify to be a [SemanticAlert].
class SemanticStatus extends SemanticRole {
  SemanticStatus(SemanticsObject semanticsObject)
    : super.withBasics(
        EngineSemanticsRole.status,
        semanticsObject,
        preferredLabelRepresentation: LabelRepresentation.ariaLabel,
      );

  @override
  DomElement createElement() => createDomElement('status');

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
}
