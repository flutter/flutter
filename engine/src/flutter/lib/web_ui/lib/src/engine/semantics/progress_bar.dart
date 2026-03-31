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
class SemanticsProgressBar extends SemanticRole {
  SemanticsProgressBar(SemanticsObject semanticsObject)
    : super.withBasics(
        EngineSemanticsRole.progressBar,
        semanticsObject,
        preferredLabelRepresentation: LabelRepresentation.ariaLabel,
      ) {
    setAriaRole('progressbar');
    _updateAriaAttributes();
  }

  void _updateAriaAttributes() {
    // Set ARIA attributes for min, max and current value.
    if (semanticsObject.minValue?.isNotEmpty ?? false) {
      setAttribute('aria-valuemin', semanticsObject.minValue!);
    }
    if (semanticsObject.maxValue?.isNotEmpty ?? false) {
      setAttribute('aria-valuemax', semanticsObject.maxValue!);
    }
    if (semanticsObject.value?.isNotEmpty ?? false) {
      setAttribute('aria-valuenow', semanticsObject.value!);
    }
  }

  @override
  void update() {
    super.update();
    _updateAriaAttributes();
  }

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
}

/// Indicates a loading spinner element.
class SemanticsLoadingSpinner extends SemanticRole {
  SemanticsLoadingSpinner(SemanticsObject semanticsObject)
    : super.withBasics(
        EngineSemanticsRole.loadingSpinner,
        semanticsObject,
        preferredLabelRepresentation: LabelRepresentation.ariaLabel,
      );

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
}
