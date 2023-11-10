// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../browser_detection.dart';
import '../dom.dart';
import '../text_editing/text_editing.dart';
import 'dom_manager.dart';

/// Manages the CSS styles of the Flutter View.
class StyleManager {
  static const String defaultFontStyle = 'normal';
  static const String defaultFontWeight = 'normal';
  static const double defaultFontSize = 14.0;
  static const String defaultFontFamily = 'sans-serif';
  static const String defaultCssFont = '$defaultFontStyle $defaultFontWeight ${defaultFontSize}px $defaultFontFamily';

  static void attachGlobalStyles({
    required DomNode node,
    required String styleId,
    required String? styleNonce,
    required String cssSelectorPrefix,
  }) {
    final DomHTMLStyleElement styleElement = createDomHTMLStyleElement(styleNonce);
    styleElement.id = styleId;
    // The style element must be appended to the DOM, or its `sheet` will be null later.
    node.appendChild(styleElement);
    applyGlobalCssRulesToSheet(
      styleElement,
      defaultCssFont: StyleManager.defaultCssFont,
      cssSelectorPrefix: cssSelectorPrefix,
    );
  }

  static void styleSceneHost(
    DomElement sceneHost, {
    bool debugShowSemanticsNodes = false,
  }) {
    assert(sceneHost.tagName.toLowerCase() == DomManager.sceneHostTagName.toLowerCase());
    // Don't allow the scene to receive pointer events.
    sceneHost.style.pointerEvents = 'none';
    // When debugging semantics, make the scene semi-transparent so that the
    // semantics tree is more prominent.
    if (debugShowSemanticsNodes) {
      sceneHost.style.opacity = '0.3';
    }
  }

  static void styleSemanticsHost(
    DomElement semanticsHost,
    double devicePixelRatio,
  ) {
    assert(semanticsHost.tagName.toLowerCase() == DomManager.semanticsHostTagName.toLowerCase());
    semanticsHost.style
      ..position = 'absolute'
      ..transformOrigin = '0 0 0';
    scaleSemanticsHost(semanticsHost, devicePixelRatio);
  }

  /// The framework specifies semantics in physical pixels, but CSS uses
  /// logical pixels. To compensate, an inverse scale is injected at the root
  /// level.
  static void scaleSemanticsHost(
    DomElement semanticsHost,
    double devicePixelRatio,
  ) {
    assert(semanticsHost.tagName.toLowerCase() == DomManager.semanticsHostTagName.toLowerCase());
    semanticsHost.style.transform = 'scale(${1 / devicePixelRatio})';
  }
}

/// Applies the required global CSS to an incoming [DomCSSStyleSheet] `sheet`.
@visibleForTesting
void applyGlobalCssRulesToSheet(
  DomHTMLStyleElement styleElement, {
  String cssSelectorPrefix = '',
  required String defaultCssFont,
}) {
  // TODO(web): use more efficient CSS selectors; descendant selectors are slow.
  // More info: https://csswizardry.com/2011/09/writing-efficient-css-selectors

  assert(styleElement.sheet != null);
  final DomCSSStyleSheet sheet = styleElement.sheet! as DomCSSStyleSheet;

  // Fixes #115216 by ensuring that our parameters only affect the flt-scene-host children.
  sheet.insertRule('''
    $cssSelectorPrefix ${DomManager.sceneHostTagName} {
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
