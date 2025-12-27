// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import '../dom.dart';
import 'label_and_value.dart';
import 'semantics.dart';

/// Indicates an interactive element inside a tablist that, when activated,
/// displays its associated tabpanel.
///
/// Uses aria tab role to convey this semantic information to the element.
///
/// Screen-readers take advantage of "aria-label" to describe the visual.
class SemanticTab extends SemanticRole {
  SemanticTab(SemanticsObject semanticsObject)
    : super.withBasics(
        EngineSemanticsRole.tab,
        semanticsObject,
        preferredLabelRepresentation: LabelRepresentation.ariaLabel,
      ) {
    setAriaRole('tab');
    addTappable();
  }

  @override
  DomElement createElement() {
    // When the tab has a link URL, render as an <a> element to enable
    // proper link functionality (right-click copy, SEO indexing) while
    // still using role="tab" for accessibility.
    if (semanticsObject.hasLinkUrl) {
      final DomElement element = domDocument.createElement('a');
      element.style.display = 'block';
      return element;
    }
    return super.createElement();
  }

  @override
  void update() {
    super.update();

    // Update the href attribute when the link URL changes.
    if (semanticsObject.isLinkUrlDirty) {
      if (semanticsObject.hasLinkUrl) {
        element.setAttribute('href', semanticsObject.linkUrl!);
      } else {
        element.removeAttribute('href');
      }
    }
  }

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
}

/// Indicates the main display for a tab when activated.
///
/// Uses aria tabpanel role to convey this semantic information to the element.
///
/// Screen-readers take advantage of "aria-label" to describe the visual.
class SemanticTabPanel extends SemanticRole {
  SemanticTabPanel(SemanticsObject semanticsObject)
    : super.withBasics(
        EngineSemanticsRole.tabPanel,
        semanticsObject,
        preferredLabelRepresentation: LabelRepresentation.ariaLabel,
      ) {
    setAriaRole('tabpanel');
  }

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
}

/// Indicates a container that contains multiple tabs.
///
/// Uses aria tablist role to convey this semantic information to the element.
///
/// Screen-readers take advantage of "aria-label" to describe the visual.
class SemanticTabList extends SemanticRole {
  SemanticTabList(SemanticsObject semanticsObject)
    : super.withBasics(
        EngineSemanticsRole.tabList,
        semanticsObject,
        preferredLabelRepresentation: LabelRepresentation.ariaLabel,
      ) {
    setAriaRole('tablist');
  }

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
}
