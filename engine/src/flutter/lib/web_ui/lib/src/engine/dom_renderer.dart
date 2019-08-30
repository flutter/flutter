// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

class DomRenderer {
  DomRenderer() {
    if (assertionsEnabled) {
      _debugFrameStatistics = DebugDomRendererFrameStatistics();
    }

    reset();

    TextMeasurementService.initialize(rulerCacheCapacity: 10);

    assert(() {
      _setupHotRestart();
      return true;
    }());
  }

  static const int vibrateLongPress = 50;
  static const int vibrateLightImpact = 10;
  static const int vibrateMediumImpact = 20;
  static const int vibrateHeavyImpact = 30;
  static const int vibrateSelectionClick = 10;

  /// Listens to window resize events.
  StreamSubscription<html.Event> _resizeSubscription;

  /// Contains Flutter-specific CSS rules, such as default margins and
  /// paddings.
  html.StyleElement _styleElement;

  /// Configures the screen, such as scaling.
  html.MetaElement _viewportMeta;

  /// The canvaskit script, downloaded from a CDN. Only created if
  /// [experimentalUseSkia] is set to true.
  html.ScriptElement get canvasKitScript => _canvasKitScript;
  html.ScriptElement _canvasKitScript;

  /// The element that contains the [sceneElement].
  ///
  /// This element is created and inserted in the HTML DOM once. It is never
  /// removed or moved. However the [sceneElement] may be replaced inside it.
  ///
  /// This element precedes the [glassPaneElement] so that it never receives
  /// input events. All input events are processed by [glassPaneElement] and the
  /// semantics tree.
  html.Element get sceneHostElement => _sceneHostElement;
  html.Element _sceneHostElement;

  /// The last scene element rendered by the [render] method.
  html.Element get sceneElement => _sceneElement;
  html.Element _sceneElement;

  /// This is state persistant across hot restarts that indicates what
  /// to clear.  We delay removal of old visible state to make the
  /// transition appear smooth.
  static const String _staleHotRestartStore = '__flutter_state';
  List<html.Element> _staleHotRestartState;

  void _setupHotRestart() {
    // This persists across hot restarts to clear stale DOM.
    _staleHotRestartState =
        js_util.getProperty(html.window, _staleHotRestartStore);
    if (_staleHotRestartState == null) {
      _staleHotRestartState = <html.Element>[];
      js_util.setProperty(
          html.window, _staleHotRestartStore, _staleHotRestartState);
    }

    registerHotRestartListener(() {
      _resizeSubscription?.cancel();
      _staleHotRestartState.addAll(<html.Element>[
        _glassPaneElement,
        _styleElement,
        _viewportMeta,
        _canvasKitScript,
      ]);
    });
  }

  void _clearOnHotRestart() {
    if (_staleHotRestartState.isNotEmpty) {
      for (html.Element element in _staleHotRestartState) {
        element?.remove();
      }
      _staleHotRestartState.clear();
    }
  }

  /// We don't want to unnecessarily move DOM nodes around. If a DOM node is
  /// already in the right place, skip DOM mutation. This is both faster and
  /// more correct, because moving DOM nodes loses internal state, such as
  /// text selection.
  void renderScene(html.Element sceneElement) {
    if (sceneElement != _sceneElement) {
      _sceneElement?.remove();
      _sceneElement = sceneElement;
      append(_sceneHostElement, sceneElement);
    }
    assert(() {
      _clearOnHotRestart();
      return true;
    }());
  }

  /// The element that captures input events, such as pointer events.
  ///
  /// If semantics is enabled this element also contains the semantics DOM tree,
  /// which captures semantics input events. The semantics DOM tree must be a
  /// child of the glass pane element so that events bubble up to the glass pane
  /// if they are not handled by semantics.
  html.Element get glassPaneElement => _glassPaneElement;
  html.Element _glassPaneElement;

  final html.Element rootElement = html.document.body;

  void addElementClass(html.Element element, String className) {
    element.classes.add(className);
  }

  void attachBeforeElement(
      html.Element parent, html.Element before, html.Element newElement) {
    assert(parent != null);
    if (parent != null) {
      assert(() {
        if (before == null) {
          return true;
        }
        if (before.parent != parent) {
          throw Exception(
            'attachBeforeElement was called with `before` element that\'s '
            'not a child of the `parent` element:\n'
            '  before: $before\n'
            '  parent: $parent',
          );
        }
        return true;
      }());
      parent.insertBefore(newElement, before);
    }
  }

  html.Element createElement(String tagName, {html.Element parent}) {
    final html.Element element = html.document.createElement(tagName);
    parent?.append(element);
    return element;
  }

  void append(html.Element parent, html.Element child) {
    parent.append(child);
  }

  void appendText(html.Element parent, String text) {
    parent.appendText(text);
  }

  void detachElement(html.Element element) {
    element.remove();
  }

  void removeElementClass(html.Element element, String className) {
    element.classes.remove(className);
  }

  void setElementAttribute(html.Element element, String name, String value) {
    element.setAttribute(name, value);
  }

  void setElementProperty(html.Element element, String name, Object value) {
    js_util.setProperty(element, name, value);
  }

  void setElementStyle(html.Element element, String name, String value) {
    if (value == null) {
      element.style.removeProperty(name);
    } else {
      element.style.setProperty(name, value);
    }
  }

  void setText(html.Element element, String text) {
    element.text = text;
  }

  void removeAllChildren(html.Element element) {
    element.children.clear();
  }

  html.Element getParent(html.Element element) => element.parent;

  void setTitle(String title) {
    html.document.title = title;
  }

  void setThemeColor(ui.Color color) {
    html.MetaElement theme = html.document.querySelector('#flutterweb-theme');
    if (theme == null) {
      theme = html.MetaElement()
        ..id = 'flutterweb-theme'
        ..name = 'theme-color';
      html.document.head.append(theme);
    }
    theme.content = color.toCssString();
  }

  static const String defaultFontStyle = 'normal';
  static const String defaultFontWeight = 'normal';
  static const String defaultFontSize = '14px';
  static const String defaultFontFamily = 'sans-serif';
  static const String defaultCssFont =
      '$defaultFontStyle $defaultFontWeight $defaultFontSize $defaultFontFamily';

  void reset() {
    _styleElement?.remove();
    _styleElement = html.StyleElement();
    html.document.head.append(_styleElement);
    final html.CssStyleSheet sheet = _styleElement.sheet;

    // TODO(butterfly): use more efficient CSS selectors; descendant selectors
    //                  are slow. More info:
    //
    //                  https://csswizardry.com/2011/09/writing-efficient-css-selectors/

    // This undoes browser's default layout attributes for paragraphs. We
    // compute paragraph layout ourselves.
    sheet.insertRule('''
flt-ruler-host p, flt-scene p {
  margin: 0;
}''', sheet.cssRules.length);

    // This undoes browser's default painting and layout attributes of range
    // input, which is used in semantics.
    sheet.insertRule('''
flt-semantics input[type=range] {
  appearance: none;
  -webkit-appearance: none;
  width: 100%;
  position: absolute;
  border: none;
  top: 0;
  right: 0;
  bottom: 0;
  left: 0;
}''', sheet.cssRules.length);

    if (browserEngine == BrowserEngine.webkit) {
      sheet.insertRule(
          'flt-semantics input[type=range]::-webkit-slider-thumb {'
          '  -webkit-appearance: none;'
          '}',
          sheet.cssRules.length);
    }

    if (browserEngine == BrowserEngine.firefox) {
      sheet.insertRule(
          'input::-moz-selection {'
          '  background-color: transparent;'
          '}',
          sheet.cssRules.length);
    } else {
      // On iOS, the invisible semantic text field has a visible cursor and
      // selection highlight. The following 2 CSS rules force everything to be
      // transparent.
      sheet.insertRule(
          'input::selection {'
          '  background-color: transparent;'
          '}',
          sheet.cssRules.length);
    }
    sheet.insertRule('''
flt-semantics input,
flt-semantics textarea,
flt-semantics [contentEditable="true"] {
  caret-color: transparent;
}
''', sheet.cssRules.length);

    // By default on iOS, Safari would highlight the element that's being tapped
    // on using gray background. This CSS rule disables that.
    if (browserEngine == BrowserEngine.webkit) {
      sheet.insertRule('''
flt-glass-pane * {
  -webkit-tap-highlight-color: transparent;
}
''', sheet.cssRules.length);
    }

    final html.BodyElement bodyElement = html.document.body;
    setElementStyle(bodyElement, 'position', 'fixed');
    setElementStyle(bodyElement, 'top', '0');
    setElementStyle(bodyElement, 'right', '0');
    setElementStyle(bodyElement, 'bottom', '0');
    setElementStyle(bodyElement, 'left', '0');
    setElementStyle(bodyElement, 'overflow', 'hidden');
    setElementStyle(bodyElement, 'padding', '0');
    setElementStyle(bodyElement, 'margin', '0');

    // TODO(yjbanov): fix this when we support KVM I/O. Currently we scroll
    //                using drag, and text selection interferes.
    setElementStyle(bodyElement, 'user-select', 'none');
    setElementStyle(bodyElement, '-webkit-user-select', 'none');
    setElementStyle(bodyElement, '-ms-user-select', 'none');
    setElementStyle(bodyElement, '-moz-user-select', 'none');

    // This is required to prevent the browser from doing any native touch
    // handling. If we don't do this, the browser doesn't report 'pointermove'
    // events properly.
    setElementStyle(bodyElement, 'touch-action', 'none');

    // These are intentionally outrageous font parameters to make sure that the
    // apps fully specifies their text styles.
    setElementStyle(bodyElement, 'font', defaultCssFont);
    setElementStyle(bodyElement, 'color', 'red');

    // TODO(flutter_web): send the location during the scroll for more frequent
    // location updates from the framework. Remove spellcheck=false property.
    /// The spell check is being disabled for now.
    ///
    /// Flutter web is positioning the input box on top of editable widget.
    /// This location is updated only in the paint phase of the widget.
    /// It is wrong during the scroll. It is not important for text editing
    /// since the content is already invisible. On the other hand, the red
    /// indicator for spellcheck gets confusing due to the wrong positioning.
    /// We are disabling spellcheck until the location starts getting updated
    /// via scroll. This is possible since we can listen to the scroll on
    /// Flutter.
    /// See [HybridTextEditing].
    bodyElement.spellcheck = false;

    for (html.Element viewportMeta
        in html.document.head.querySelectorAll('meta[name="viewport"]')) {
      if (assertionsEnabled) {
        // Filter out the meta tag that we ourselves placed on the page. This is
        // to avoid UI flicker during hot restart. Hot restart will clean up the
        // old meta tag synchronously with the first post-restart frame.
        if (!viewportMeta.hasAttribute('flt-viewport')) {
          print(
            'WARNING: found an existing <meta name="viewport"> tag. Flutter '
            'Web uses its own viewport configuration for better compatibility '
            'with Flutter. This tag will be replaced.',
          );
        }
      }
      viewportMeta.remove();
    }

    // This removes a previously created meta tag. Note, however, that this does
    // not remove the meta tag during hot restart. Hot restart resets all static
    // variables, so this will be null upon hot restart. Instead, this tag is
    // removed by _clearOnHotRestart.
    _viewportMeta?.remove();
    _viewportMeta = html.MetaElement()
      ..setAttribute('flt-viewport', '')
      ..name = 'viewport'
      ..content = 'width=device-width, initial-scale=1.0, '
          'maximum-scale=1.0, user-scalable=no';
    html.document.head.append(_viewportMeta);

    // IMPORTANT: the glass pane element must come after the scene element in the DOM node list so
    //            it can intercept input events.
    _glassPaneElement?.remove();
    _glassPaneElement = createElement('flt-glass-pane');
    _glassPaneElement.style
      ..position = 'absolute'
      ..top = '0'
      ..right = '0'
      ..bottom = '0'
      ..left = '0';
    bodyElement.append(_glassPaneElement);

    _sceneHostElement = createElement('flt-scene-host');

    // Don't allow the scene to receive pointer events.
    _sceneHostElement.style.pointerEvents = 'none';

    _glassPaneElement.append(_sceneHostElement);

    EngineSemanticsOwner.instance.autoEnableOnTap(this);
    PointerBinding(this);

    // Hide the DOM nodes used to render the scene from accessibility, because
    // the accessibility tree is built from the SemanticsNode tree as a parallel
    // DOM tree.
    setElementAttribute(_sceneHostElement, 'aria-hidden', 'true');

    // We treat browser pixels as device pixels because pointer events,
    // position, and sizes all use browser pixel as the unit (i.e. "px" in CSS).
    // Therefore, as far as the framework is concerned the device pixel ratio
    // is 1.0.
    window.debugOverrideDevicePixelRatio(1.0);

    if (browserEngine == BrowserEngine.webkit) {
      // Safari sometimes gives us bogus innerWidth/innerHeight values when the
      // page loads. When it changes the values to correct ones it does not
      // notify of the change via `onResize`. As a workaround, we setup a
      // temporary periodic timer that polls innerWidth and triggers the
      // resizeListener so that the framework can react to the change.
      final int initialInnerWidth = html.window.innerWidth;
      // Counts how many times we checked screen size. We check up to 5 times.
      int checkCount = 0;
      Timer.periodic(const Duration(milliseconds: 100), (Timer t) {
        checkCount += 1;
        if (initialInnerWidth != html.window.innerWidth) {
          // Window size changed. Notify.
          t.cancel();
          _metricsDidChange(null);
        } else if (checkCount > 5) {
          // Checked enough times. Stop.
          t.cancel();
        }
      });
    }

    if (experimentalUseSkia) {
      _canvasKitScript?.remove();
      _canvasKitScript = html.ScriptElement();
      _canvasKitScript.src = canvasKitBaseUrl + 'canvaskit.js';
      html.document.head.append(_canvasKitScript);
    }

    _resizeSubscription = html.window.onResize.listen(_metricsDidChange);
  }

  /// Called immediately after browser window metrics change.
  void _metricsDidChange(html.Event event) {
    if (ui.window.onMetricsChanged != null) {
      ui.window.onMetricsChanged();
    }
  }

  void focus(html.Element element) {
    element.focus();
  }

  /// Removes all children of a DOM node.
  void clearDom(html.Node node) {
    while (node.lastChild != null) {
      node.lastChild.remove();
    }
  }

  /// The element corresponding to the only child of the root surface.
  html.Element get _rootApplicationElement {
    final html.Element lastElement = rootElement.children.last;
    return lastElement.children.singleWhere((html.Element element) {
      return element.tagName == 'FLT-SCENE';
    }, orElse: () => null);
  }

  /// Provides haptic feedback.
  void vibrate(int durationMs) {
    final html.Navigator navigator = html.window.navigator;
    if (js_util.hasProperty(navigator, 'vibrate')) {
      js_util.callMethod(navigator, 'vibrate', <num>[durationMs]);
    }
  }

  String get currentHtml => _rootApplicationElement?.outerHtml ?? '';

  DebugDomRendererFrameStatistics _debugFrameStatistics;

  DebugDomRendererFrameStatistics debugFlushFrameStatistics() {
    if (!assertionsEnabled) {
      throw Exception('This code should not be reachable in production.');
    }
    final DebugDomRendererFrameStatistics current = _debugFrameStatistics;
    _debugFrameStatistics = DebugDomRendererFrameStatistics();
    return current;
  }

  void debugRulerCacheHit() => _debugFrameStatistics.paragraphRulerCacheHits++;
  void debugRulerCacheMiss() =>
      _debugFrameStatistics.paragraphRulerCacheMisses++;
  void debugRichTextLayout() => _debugFrameStatistics.richTextLayouts++;
  void debugPlainTextLayout() => _debugFrameStatistics.plainTextLayouts++;
}

/// Miscellaneous statistics collecting during a single frame's execution.
///
/// This is useful when profiling the app. This class should only be used when
/// assertions are enabled and therefore is not suitable for collecting any
/// time measurements. It is mostly useful for counting certain events.
class DebugDomRendererFrameStatistics {
  /// The number of times we reused a previously initialized paragraph ruler to
  /// measure a paragraph of text.
  int paragraphRulerCacheHits = 0;

  /// The number of times we had to create a new paragraph ruler to measure a
  /// paragraph of text.
  int paragraphRulerCacheMisses = 0;

  /// The number of times we used a paragraph ruler to measure a paragraph of
  /// text.
  int get totalParagraphRulerAccesses =>
      paragraphRulerCacheHits + paragraphRulerCacheMisses;

  /// The number of times a paragraph of rich text was laid out this frame.
  int richTextLayouts = 0;

  /// The number of times a paragraph of plain text was laid out this frame.
  int plainTextLayouts = 0;

  @override
  String toString() {
    return '''
Frame statistics:
  Paragraph ruler cache hits: $paragraphRulerCacheHits
  Paragraph ruler cache misses: $paragraphRulerCacheMisses
  Paragraph ruler accesses: $totalParagraphRulerAccesses
  Rich text layouts: $richTextLayouts
  Plain text layouts: $plainTextLayouts
'''
        .trim();
  }
}

// TODO(yjbanov): Replace this with an explicit initialization function. The
//                lazy initialization of statics makes it very unpredictable, as
//                the constructor has side-effects.
/// Singleton DOM renderer.
final DomRenderer domRenderer = DomRenderer();
