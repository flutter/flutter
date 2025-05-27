// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'label_and_value.dart';
import 'semantics.dart';

/// Indicates a complementary element.
///
/// Uses aria complementary role to convey this semantic information to the element.
///
/// Screen-readers takes advantage of "aria-label" to describe the visual.
class SemanticComplementary extends SemanticRole {
  SemanticComplementary(SemanticsObject semanticsObject)
    : super.withBasics(
        EngineSemanticsRole.complementary,
        semanticsObject,
        preferredLabelRepresentation: LabelRepresentation.ariaLabel,
      ) {
    setAriaRole('complementary');
  }

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
}

/// Indicates a content info element.
///
/// Uses aria contentinfo role to convey this semantic information to the element.
///
/// Screen-readers takes advantage of "aria-label" to describe the visual.
class SemanticContentInfo extends SemanticRole {
  SemanticContentInfo(SemanticsObject semanticsObject)
    : super.withBasics(
        EngineSemanticsRole.contentInfo,
        semanticsObject,
        preferredLabelRepresentation: LabelRepresentation.ariaLabel,
      ) {
    setAriaRole('contentinfo');
  }

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
}

/// Indicates a main element.
///
/// Uses aria main role to convey this semantic information to the element.
///
/// Screen-readers takes advantage of "aria-label" to describe the visual.
class SemanticMain extends SemanticRole {
  SemanticMain(SemanticsObject semanticsObject)
    : super.withBasics(
        EngineSemanticsRole.main,
        semanticsObject,
        preferredLabelRepresentation: LabelRepresentation.ariaLabel,
      ) {
    setAriaRole('main');
  }

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
}

/// Indicates a navigation element.
///
/// Uses aria navigation role to convey this semantic information to the element.
///
/// Screen-readers takes advantage of "aria-label" to describe the visual.
class SemanticNavigation extends SemanticRole {
  SemanticNavigation(SemanticsObject semanticsObject)
    : super.withBasics(
        EngineSemanticsRole.navigation,
        semanticsObject,
        preferredLabelRepresentation: LabelRepresentation.ariaLabel,
      ) {
    setAriaRole('navigation');
  }

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
}

/// Indicates a region element.
///
/// Uses aria region role to convey this semantic information to the element.
///
/// Screen-readers takes advantage of "aria-label" to describe the visual.
class SemanticRegion extends SemanticRole {
  SemanticRegion(SemanticsObject semanticsObject)
    : super.withBasics(
        EngineSemanticsRole.region,
        semanticsObject,
        preferredLabelRepresentation: LabelRepresentation.ariaLabel,
      ) {
    setAriaRole('region');
  }

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
}
