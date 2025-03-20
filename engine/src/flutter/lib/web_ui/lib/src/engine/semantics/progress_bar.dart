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

    // Progress indicators in Flutter use values between 0.0 and 1.0
    setAttribute('aria-valuemin', "0");
    setAttribute('aria-valuemax', "100");
    setAttribute('aria-valuenow', semanticsObject.value);
  }

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
}

/// Indicates a loading spinner element.
class SementicsLoadingSpinner extends SemanticRole {
  SementicsLoadingSpinner(SemanticsObject semanticsObject)
    : super.withBasics(
        EngineSemanticsRole.loadingSpinner,
        semanticsObject,
        preferredLabelRepresentation: LabelRepresentation.ariaLabel,
      ) {}

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
}
