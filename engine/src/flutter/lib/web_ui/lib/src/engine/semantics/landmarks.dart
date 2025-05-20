// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/ui.dart' as ui;

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
  void update() {
    super.update();

    Set<int> complementaryIds = _sameRoleIds(semanticsObject);

    if (complementaryIds.length > 1) {
      _updateUniqueLabels(complementaryIds, semanticsObject);
    } else if (semanticsObject.label != null) {
      setAttribute('aria-label', semanticsObject.label!);
    }
  }

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
}

Set<int> _sameRoleIds(SemanticsObject semanticsObject) {
  final Map<int, SemanticsObject> tree = semanticsObject.owner.semanticsTree;
  Set<int> sameRoleIds = {};
  for (final int id in tree.keys) {
    if (tree[id]?.role == semanticsObject.role) {
      sameRoleIds.add(id);
    }
  }
  return sameRoleIds;
}

void _updateUniqueLabels(Set<int> ids, SemanticsObject semanticsObject) {
  final Map<int, SemanticsObject> tree = semanticsObject.owner.semanticsTree;
  for (final int id in ids) {
    String label = tree[id]?.label ?? '';
    if (label == '') {
      label = 'flt-semantic-node-$id';
    }
    tree[id]?.semanticRole?.setAttribute('aria-label', label);
  }
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
  void update() {
    super.update();

    Set<int> contentInfoIds = _sameRoleIds(semanticsObject);

    if (contentInfoIds.length > 1) {
      _updateUniqueLabels(contentInfoIds, semanticsObject);
    } else if (semanticsObject.label != null) {
      setAttribute('aria-label', semanticsObject.label!);
    }
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
  void update() {
    super.update();

    Set<int> mainIds = _sameRoleIds(semanticsObject);

    if (mainIds.length > 1) {
      _updateUniqueLabels(mainIds, semanticsObject);
    } else if (semanticsObject.label != null) {
      setAttribute('aria-label', semanticsObject.label!);
    }
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
  void update() {
    super.update();

    Set<int> navigationIds = _sameRoleIds(semanticsObject);

    if (navigationIds.length > 1) {
      _updateUniqueLabels(navigationIds, semanticsObject);
    } else if (semanticsObject.label != null) {
      setAttribute('aria-label', semanticsObject.label!);
    }
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
  void update() {
    super.update();
    Set<int> regionIds = _sameRoleIds(semanticsObject);
    final Map<int, SemanticsObject> tree = semanticsObject.owner.semanticsTree;

    if (regionIds.length > 1) {
      _updateUniqueLabels(regionIds, semanticsObject);
    } else {
      setAttribute('aria-label', semanticsObject.label ?? '');
    }
  }

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
}
