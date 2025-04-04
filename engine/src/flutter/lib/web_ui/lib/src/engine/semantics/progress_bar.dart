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

    // Get the min and max values from semantics object.
    final double minValue = semanticsObject.minValue ?? 0.0;
    final double maxValue = semanticsObject.maxValue ?? 100.0;

    // Set ARIA attributes for min, max and current value.
    setAttribute('aria-valuemin', minValue.toStringAsFixed(2));
    setAttribute('aria-valuemax', maxValue.toStringAsFixed(2));

    if (semanticsObject.value != null) {
      setAttribute('aria-valuenow', semanticsObject.value!);
    }
  }

  @override
  void update() {
    super.update();

    final double minValue = semanticsObject.minValue ?? 0.0;
    final double maxValue = semanticsObject.maxValue ?? 100.0;

    if (semanticsObject.isMinValueDirty) {
      setAttribute('aria-valuemin', minValue.toStringAsFixed(2));
    }

    if (semanticsObject.isMaxValueDirty) {
      setAttribute('aria-valuemax', maxValue.toStringAsFixed(2));
    }

    if (semanticsObject.value != null) {
      setAttribute('aria-valuenow', semanticsObject.value!);
    }
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
      );

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
}
