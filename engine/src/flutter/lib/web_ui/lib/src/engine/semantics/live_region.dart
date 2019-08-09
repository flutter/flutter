// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

/// Manages semantics configurations that represent live regions.
///
/// "aria-live" attribute is added to communicate the live region to the
/// assistive technology.
///
/// The usage of "aria-live" is browser-dependent.
///
/// VoiceOver only supports "aria-live" with "polite" politeness setting. When
/// the inner html content is changed. It doesn't read the "aria-label".
///
/// When there is an aria-live attribute added, assistive technologies read the
/// label of the element. See [LabelAndValue]. If there is no label provided
/// no content will be read, therefore DOM is cleaned.
class LiveRegion extends RoleManager {
  LiveRegion(SemanticsObject semanticsObject)
      : super(Role.labelAndValue, semanticsObject);

  @override
  void update() {
    if (semanticsObject.hasLabel) {
      semanticsObject.element.setAttribute('aria-live', 'polite');
    } else {
      _cleanupDom();
    }
  }

  void _cleanupDom() {
    semanticsObject.element.attributes.remove('aria-live');
  }

  @override
  void dispose() {
    _cleanupDom();
  }
}
