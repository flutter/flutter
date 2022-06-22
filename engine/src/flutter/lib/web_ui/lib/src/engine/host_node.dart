// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'browser_detection.dart';
import 'dom.dart';
import 'embedder.dart';
import 'text_editing/text_editing.dart';

/// The interface required to host a flutter app in the DOM, and its tests.
///
/// Consider this as the intersection in functionality between [DomShadowRoot]
/// (preferred Flutter rendering method) and [DomDocument] (fallback).
///
/// Not to be confused with [DomDocumentOrShadowRoot].
abstract class HostNode {
  /// Retrieves the [DomElement] that currently has focus.
  ///
  /// See:
  /// * [Document.activeElement](https://developer.mozilla.org/en-US/docs/Web/API/Document/activeElement)
  DomElement? get activeElement;

  /// Adds a node to the end of the child [nodes] list of this node.
  ///
  /// If the node already exists in this document, it will be removed from its
  /// current parent node, then added to this node.
  ///
  /// This method is more efficient than `nodes.add`, and is the preferred
  /// way of appending a child node.
  ///
  /// See:
  /// * [Node.appendChild](https://developer.mozilla.org/en-US/docs/Web/API/Node/appendChild)
  DomNode append(DomNode node);

  /// Appends all of an [Iterable<DomNode>] to this [HostNode].
  void appendAll(Iterable<DomNode> nodes);

  /// Returns true if this node contains the specified node.
  /// See:
  /// * [Node.contains](https://developer.mozilla.org/en-US/docs/Web/API/Node.contains)
  bool contains(DomNode? other);

  /// Returns the currently wrapped [DomNode].
  DomNode get node;

  /// Finds the first descendant element of this document that matches the
  /// specified group of selectors.
  ///
  /// [selectors] should be a string using CSS selector syntax.
  ///
  /// ```dart
  /// var element1 = document.querySelector('.className');
  /// var element2 = document.querySelector('#id');
  /// ```
  ///
  /// For details about CSS selector syntax, see the
  /// [CSS selector specification](http://www.w3.org/TR/css3-selectors/).
  ///
  /// See:
  /// * [Document.querySelector](https://developer.mozilla.org/en-US/docs/Web/API/Document/querySelector)
  DomElement? querySelector(String selectors);

  /// Finds all descendant elements of this document that match the specified
  /// group of selectors.
  ///
  /// [selectors] should be a string using CSS selector syntax.
  ///
  /// ```dart
  /// var items = document.querySelectorAll('.itemClassName');
  /// ```
  ///
  /// For details about CSS selector syntax, see the
  /// [CSS selector specification](http://www.w3.org/TR/css3-selectors/).
  ///
  /// See:
  /// * [Document.querySelectorAll](https://developer.mozilla.org/en-US/docs/Web/API/Document/querySelectorAll)
  Iterable<DomElement> querySelectorAll(String selectors);
}

/// A [HostNode] implementation, backed by a [DomShadowRoot].
///
/// This is the preferred flutter implementation, but it might not be supported
/// by all browsers yet.
///
/// The constructor might throw when calling `attachShadow`, if ShadowDOM is not
/// supported in the current environment. In this case, a fallback [ElementHostNode]
/// should be created instead.
class ShadowDomHostNode implements HostNode {
  late DomShadowRoot _shadow;

  /// Build a HostNode by attaching a [DomShadowRoot] to the `root` element.
  ///
  /// This also calls [applyGlobalCssRulesToSheet], defined in dom_renderer.
  ShadowDomHostNode(DomElement root) :
    assert(
    root.isConnected ?? true,
    'The `root` of a ShadowDomHostNode must be connected to the Document object or a ShadowRoot.',
    ) {
    _shadow = root.attachShadow(<String, dynamic>{
      'mode': 'open',
      // This needs to stay false to prevent issues like this:
      // - https://github.com/flutter/flutter/issues/85759
      'delegatesFocus': false,
    });

    final DomHTMLStyleElement shadowRootStyleElement = createDomHTMLStyleElement();
    // The shadowRootStyleElement must be appended to the DOM, or its `sheet` will be null later.
    _shadow.appendChild(shadowRootStyleElement);

    // TODO(dit): Apply only rules for the shadow root
    applyGlobalCssRulesToSheet(
      shadowRootStyleElement.sheet! as DomCSSStyleSheet,
      browserEngine: browserEngine,
      hasAutofillOverlay: browserHasAutofillOverlay(),
    );
  }

  @override
  DomElement? get activeElement => _shadow.activeElement;

  @override
  DomElement? querySelector(String selectors) {
    return _shadow.querySelector(selectors);
  }

  @override
  Iterable<DomElement> querySelectorAll(String selectors) {
    return _shadow.querySelectorAll(selectors);
  }

  @override
  DomNode append(DomNode node) {
    return _shadow.appendChild(node);
  }

  @override
  bool contains(DomNode? other) {
    return _shadow.contains(other);
  }

  @override
  DomNode get node => _shadow;

  @override
  void appendAll(Iterable<DomNode> nodes) => nodes.forEach(append);
}

/// A [HostNode] implementation, backed by a [DomElement].
///
/// This is a fallback implementation, in case [ShadowDomHostNode] fails when
/// being constructed.
class ElementHostNode implements HostNode {
  late DomElement _element;

  /// Build a HostNode by attaching a child [DomElement] to the `root` element.
  ElementHostNode(DomElement root) {
    _element = domDocument.createElement('flt-element-host-node');
    root.appendChild(_element);
  }

  @override
  DomElement? get activeElement => _element.ownerDocument?.activeElement;

  @override
  DomElement? querySelector(String selectors) {
    return _element.querySelector(selectors);
  }

  @override
  Iterable<DomElement> querySelectorAll(String selectors) {
    return _element.querySelectorAll(selectors);
  }

  @override
  DomNode append(DomNode node) {
    return _element.appendChild(node);
  }

  @override
  bool contains(DomNode? other) {
    return _element.contains(other);
  }

  @override
  DomNode get node => _element;

  @override
  void appendAll(Iterable<DomNode> nodes) => nodes.forEach(append);
}
