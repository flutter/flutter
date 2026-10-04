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
      final String value = semanticsObject.value!;
      final double? doubleValue = double.tryParse(value);

      if (doubleValue != null) {
        setAttribute('aria-valuenow', value);
      } else if (value.endsWith('%')) {
        final double? percentage = double.tryParse(value.substring(0, value.length - 1));
        if (percentage != null) {
          final double? min = double.tryParse(semanticsObject.minValue ?? '');
          final double? max = double.tryParse(semanticsObject.maxValue ?? '');
          if (min != null && max != null) {
            final double calculatedValue = min + (percentage / 100.0) * (max - min);
            setAttribute('aria-valuenow', calculatedValue.toString());
          }
        }
        setAttribute('aria-valuetext', value);
      } else {
        setAttribute('aria-valuetext', value);
      }
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
