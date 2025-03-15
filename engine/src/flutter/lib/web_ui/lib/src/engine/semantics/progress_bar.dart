// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'label_and_value.dart';
import 'semantics.dart';

/// Indicates a progress bar element.
///
/// Uses aria progressbar role to convey this semantic information to the element.
///
/// Screen-readers take advantage of "aria-label" to describe the visual.
class SementicsProgressBar extends SemanticRole {
  SementicsProgressBar(SemanticsObject semanticsObject)
    : super.withBasics(
        EngineSemanticsRole.progressBar,
        semanticsObject,
        preferredLabelRepresentation: LabelRepresentation.ariaLabel,
      ) {
    setAriaRole('progressbar');
  }

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
}

/// Indicates a loading spinner element.
///
/// Uses aria loadingSpinner role to convey this semantic information to the element.
///
/// Screen-readers take advantage of "aria-label" to describe the visual.
class SementicsLoadingSpinner extends SemanticRole {
  SementicsLoadingSpinner(SemanticsObject semanticsObject)
    : super.withBasics(
        EngineSemanticsRole.loadingSpinner,
        semanticsObject,
        preferredLabelRepresentation: LabelRepresentation.ariaLabel,
      ) {
    setAriaRole('loadingSpinner');
  }

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
}
