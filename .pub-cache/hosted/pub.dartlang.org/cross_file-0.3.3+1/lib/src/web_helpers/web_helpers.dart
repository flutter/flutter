// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html';

/// Create anchor element with download attribute
AnchorElement createAnchorElement(String href, String? suggestedName) {
  final AnchorElement element = AnchorElement(href: href);

  if (suggestedName == null) {
    element.download = 'download';
  } else {
    element.download = suggestedName;
  }

  return element;
}

/// Add an element to a container and click it
void addElementToContainerAndClick(Element container, Element element) {
  // Add the element and click it
  // All previous elements will be removed before adding the new one
  container.children.add(element);
  element.click();
}

/// Initializes a DOM container where elements can be injected.
Element ensureInitialized(String id) {
  Element? target = querySelector('#$id');
  if (target == null) {
    final Element targetElement = Element.tag('flt-x-file')..id = id;

    querySelector('body')!.children.add(targetElement);
    target = targetElement;
  }
  return target;
}

/// Determines if the browser is Safari from its vendor string.
/// (This is the same check used in flutter/engine)
bool isSafari() {
  return window.navigator.vendor == 'Apple Computer, Inc.';
}
