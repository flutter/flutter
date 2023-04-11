// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'browser_detection.dart';
import 'dom.dart';
import 'embedder.dart';
import 'safe_browser_api.dart';
import 'text_editing/text_editing.dart';

/// The interface required to host a flutter app in the DOM, and its tests.
///
/// Consider this as the intersection in functionality between [DomShadowRoot]
/// (preferred Flutter rendering method) and [DomDocument] (fallback).
///
/// Not to be confused with [DomDocumentOrShadowRoot].
///
/// This also handles the stylesheet that is applied to the different types of
/// HostNodes; for ShadowDOM there's not much to do, but for ElementNodes, the
/// stylesheet is "namespaced" by the `flt-glass-pane` prefix, so it "only"
/// affects things that Flutter web owns.
abstract class HostNode {
  /// Returns an appropriate HostNode for the given [root].
  ///
  /// If `attachShadow` is supported, this returns a [ShadowDomHostNode], else
  /// this will fall-back to an [ElementHostNode].
  factory HostNode.create(DomElement root, String defaultFont) {
    if (getJsProperty<Object?>(root, 'attachShadow') != null) {
      return ShadowDomHostNode(root, defaultFont);
    } else {
      // attachShadow not available, fall back to ElementHostNode.
      return ElementHostNode(root, defaultFont);
    }
  }

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
  /// Build a HostNode by attaching a [DomShadowRoot] to the `root` element.
  ///
  /// This also calls [applyGlobalCssRulesToSheet], with the [defaultFont]
  /// to be used as the default font definition.
  ShadowDomHostNode(DomElement root, String defaultFont)
      : assert(root.isConnected ?? true,
            'The `root` of a ShadowDomHostNode must be connected to the Document object or a ShadowRoot.') {
    _shadow = root.attachShadow(<String, dynamic>{
      'mode': 'open',
      // This needs to stay false to prevent issues like this:
      // - https://github.com/flutter/flutter/issues/85759
      'delegatesFocus': false,
    });

    final DomHTMLStyleElement shadowRootStyleElement =
        createDomHTMLStyleElement();
    shadowRootStyleElement.id = 'flt-internals-stylesheet';
    // The shadowRootStyleElement must be appended to the DOM, or its `sheet` will be null later.
    _shadow.appendChild(shadowRootStyleElement);
    applyGlobalCssRulesToSheet(
      shadowRootStyleElement.sheet! as DomCSSStyleSheet,
      hasAutofillOverlay: browserHasAutofillOverlay(),
      defaultCssFont: defaultFont,
    );
  }

  late DomShadowRoot _shadow;

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
  /// Build a HostNode by attaching a child [DomElement] to the `root` element.
  ElementHostNode(DomElement root, String defaultFont) {
    // Append the stylesheet here, so this class is completely symmetric to the
    // ShadowDOM version.
    final DomHTMLStyleElement styleElement = createDomHTMLStyleElement();
    styleElement.id = 'flt-internals-stylesheet';
    // The styleElement must be appended to the DOM, or its `sheet` will be null later.
    root.appendChild(styleElement);
    applyGlobalCssRulesToSheet(
      styleElement.sheet! as DomCSSStyleSheet,
      hasAutofillOverlay: browserHasAutofillOverlay(),
      cssSelectorPrefix: FlutterViewEmbedder.flutterViewTagName,
      defaultCssFont: defaultFont,
    );

    _element = domDocument.createElement('flt-element-host-node');
    root.appendChild(_element);
  }

  late DomElement _element;

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

// Applies the required global CSS to an incoming [DomCSSStyleSheet] `sheet`.
void applyGlobalCssRulesToSheet(
  DomCSSStyleSheet sheet, {
  required bool hasAutofillOverlay,
  String cssSelectorPrefix = '',
  required String defaultCssFont,
}) {
  // TODO(web): use more efficient CSS selectors; descendant selectors are slow.
  // More info: https://csswizardry.com/2011/09/writing-efficient-css-selectors

  // These are intentionally outrageous font parameters to make sure that the
  // apps fully specify their text styles.
  //
  // Fixes #115216 by ensuring that our parameters only affect the flt-scene-host children.
  sheet.insertRule('''
    $cssSelectorPrefix flt-scene-host {
      color: red;
      font: $defaultCssFont;
    }
  ''', sheet.cssRules.length);

  // By default on iOS, Safari would highlight the element that's being tapped
  // on using gray background. This CSS rule disables that.
  if (isSafari) {
    sheet.insertRule('''
      $cssSelectorPrefix * {
      -webkit-tap-highlight-color: transparent;
    }
    ''', sheet.cssRules.length);
  }

  if (isFirefox) {
    // For firefox set line-height, otherwise text at same font-size will
    // measure differently in ruler.
    //
    // - See: https://github.com/flutter/flutter/issues/44803
    sheet.insertRule('''
      $cssSelectorPrefix flt-paragraph,
      $cssSelectorPrefix flt-span {
        line-height: 100%;
      }
    ''', sheet.cssRules.length);
  }

  // This undoes browser's default painting and layout attributes of range
  // input, which is used in semantics.
  sheet.insertRule('''
    $cssSelectorPrefix flt-semantics input[type=range] {
      appearance: none;
      -webkit-appearance: none;
      width: 100%;
      position: absolute;
      border: none;
      top: 0;
      right: 0;
      bottom: 0;
      left: 0;
    }
  ''', sheet.cssRules.length);

  if (isSafari) {
    sheet.insertRule('''
      $cssSelectorPrefix flt-semantics input[type=range]::-webkit-slider-thumb {
        -webkit-appearance: none;
      }
    ''', sheet.cssRules.length);
  }

  // The invisible semantic text field may have a visible cursor and selection
  // highlight. The following 2 CSS rules force everything to be transparent.
  sheet.insertRule('''
    $cssSelectorPrefix input::selection {
      background-color: transparent;
    }
  ''', sheet.cssRules.length);
  sheet.insertRule('''
    $cssSelectorPrefix textarea::selection {
      background-color: transparent;
    }
  ''', sheet.cssRules.length);

  sheet.insertRule('''
    $cssSelectorPrefix flt-semantics input,
    $cssSelectorPrefix flt-semantics textarea,
    $cssSelectorPrefix flt-semantics [contentEditable="true"] {
      caret-color: transparent;
    }
    ''', sheet.cssRules.length);

  // Hide placeholder text
  sheet.insertRule('''
    $cssSelectorPrefix .flt-text-editing::placeholder {
      opacity: 0;
    }
  ''', sheet.cssRules.length);

  // This CSS makes the autofill overlay transparent in order to prevent it
  // from overlaying on top of Flutter-rendered text inputs.
  // See: https://github.com/flutter/flutter/issues/118337.
  if (browserHasAutofillOverlay()) {
    sheet.insertRule('''
      $cssSelectorPrefix .transparentTextEditing:-webkit-autofill,
      $cssSelectorPrefix .transparentTextEditing:-webkit-autofill:hover,
      $cssSelectorPrefix .transparentTextEditing:-webkit-autofill:focus,
      $cssSelectorPrefix .transparentTextEditing:-webkit-autofill:active {
        opacity: 0 !important;
      }
    ''', sheet.cssRules.length);
  }

  // Removes password reveal icon for text inputs in Edge browsers.
  // Non-Edge browsers will crash trying to parse -ms-reveal CSS selector,
  // so we guard it behind an isEdge check.
  // Fixes: https://github.com/flutter/flutter/issues/83695
  if (isEdge) {
    // We try-catch this, because in testing, we fake Edge via the UserAgent,
    // so the below will throw an exception (because only real Edge understands
    // the ::-ms-reveal pseudo-selector).
    try {
      sheet.insertRule('''
        $cssSelectorPrefix input::-ms-reveal {
          display: none;
        }
        ''', sheet.cssRules.length);
    } on DomException catch (e) {
      // Browsers that don't understand ::-ms-reveal throw a DOMException
      // of type SyntaxError.
      domWindow.console.warn(e);
      // Add a fake rule if our code failed because we're under testing
      assert(() {
        sheet.insertRule('''
          $cssSelectorPrefix input.fallback-for-fakey-browser-in-ci {
            display: none;
          }
          ''', sheet.cssRules.length);
        return true;
      }());
    }
  }
}
