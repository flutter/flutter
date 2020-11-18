// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
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

  /// Fires when browser language preferences change.
  static const html.EventStreamProvider<html.Event> languageChangeEvent =
      const html.EventStreamProvider<html.Event>('languagechange');

  /// Listens to window resize events.
  StreamSubscription<html.Event>? _resizeSubscription;

  /// Listens to window locale events.
  StreamSubscription<html.Event>? _localeSubscription;

  /// Contains Flutter-specific CSS rules, such as default margins and
  /// paddings.
  html.StyleElement? _styleElement;

  /// Configures the screen, such as scaling.
  html.MetaElement? _viewportMeta;

  /// The canvaskit script, downloaded from a CDN. Only created if
  /// [useCanvasKit] is set to true.
  html.ScriptElement? get canvasKitScript => _canvasKitScript;
  html.ScriptElement? _canvasKitScript;

  /// The element that contains the [sceneElement].
  ///
  /// This element is created and inserted in the HTML DOM once. It is never
  /// removed or moved. However the [sceneElement] may be replaced inside it.
  ///
  /// This element precedes the [glassPaneElement] so that it never receives
  /// input events. All input events are processed by [glassPaneElement] and the
  /// semantics tree.
  html.Element? get sceneHostElement => _sceneHostElement;
  html.Element? _sceneHostElement;

  /// The last scene element rendered by the [render] method.
  html.Element? get sceneElement => _sceneElement;
  html.Element? _sceneElement;

  /// This is state persistant across hot restarts that indicates what
  /// to clear.  We delay removal of old visible state to make the
  /// transition appear smooth.
  static const String _staleHotRestartStore = '__flutter_state';
  List<html.Element?>? _staleHotRestartState;

  /// Used to decide if the browser tab still has the focus.
  ///
  /// This information is useful for deciding on the blur behavior.
  /// See [DefaultTextEditingStrategy].
  ///
  /// This getter calls the `hasFocus` method of the `Document` interface.
  /// See for more details:
  /// https://developer.mozilla.org/en-US/docs/Web/API/Document/hasFocus
  bool? get windowHasFocus => js_util.callMethod(html.document, 'hasFocus', <dynamic>[]);

  void _setupHotRestart() {
    // This persists across hot restarts to clear stale DOM.
    _staleHotRestartState =
        js_util.getProperty(html.window, _staleHotRestartStore);
    if (_staleHotRestartState == null) {
      _staleHotRestartState = <html.Element?>[];
      js_util.setProperty(
          html.window, _staleHotRestartStore, _staleHotRestartState);
    }

    registerHotRestartListener(() {
      _resizeSubscription?.cancel();
      _localeSubscription?.cancel();
      _staleHotRestartState!.addAll(<html.Element?>[
        _glassPaneElement,
        _styleElement,
        _viewportMeta,
        _canvasKitScript,
      ]);
    });
  }

  void _clearOnHotRestart() {
    if (_staleHotRestartState!.isNotEmpty) {
      for (html.Element? element in _staleHotRestartState!) {
        element?.remove();
      }
      _staleHotRestartState!.clear();
    }
  }

  /// We don't want to unnecessarily move DOM nodes around. If a DOM node is
  /// already in the right place, skip DOM mutation. This is both faster and
  /// more correct, because moving DOM nodes loses internal state, such as
  /// text selection.
  void renderScene(html.Element? sceneElement) {
    if (sceneElement != _sceneElement) {
      _sceneElement?.remove();
      _sceneElement = sceneElement;
      append(_sceneHostElement!, sceneElement!);
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
  html.Element? get glassPaneElement => _glassPaneElement;
  html.Element? _glassPaneElement;

  final html.Element rootElement = html.document.body!;

  void addElementClass(html.Element element, String className) {
    element.classes.add(className);
  }

  html.Element createElement(String tagName, {html.Element? parent}) {
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

  static void setElementStyle(html.Element element, String name, String? value) {
    if (value == null) {
      element.style.removeProperty(name);
    } else {
      element.style.setProperty(name, value);
    }
  }

  static void setElementTransform(html.Element element, String transformValue) {
    js_util.setProperty(js_util.getProperty(element, 'style'), 'transform',
        transformValue);
  }

  void setText(html.Element element, String text) {
    element.text = text;
  }

  void removeAllChildren(html.Element element) {
    element.children.clear();
  }

  html.Element? getParent(html.Element element) => element.parent;

  void setTitle(String title) {
    html.document.title = title;
  }

  void setThemeColor(ui.Color color) {
    html.MetaElement? theme = html.document.querySelector('#flutterweb-theme') as html.MetaElement?;
    if (theme == null) {
      theme = html.MetaElement()
        ..id = 'flutterweb-theme'
        ..name = 'theme-color';
      html.document.head!.append(theme);
    }
    theme.content = colorToCssString(color)!;
  }

  static const String defaultFontStyle = 'normal';
  static const String defaultFontWeight = 'normal';
  static const double defaultFontSize = 14;
  static const String defaultFontFamily = 'sans-serif';
  static const String defaultCssFont =
      '$defaultFontStyle $defaultFontWeight ${defaultFontSize}px $defaultFontFamily';

  void reset() {
    _styleElement?.remove();
    _styleElement = html.StyleElement();
    html.document.head!.append(_styleElement!);
    final html.CssStyleSheet sheet = _styleElement!.sheet as html.CssStyleSheet;
    final bool isWebKit = browserEngine == BrowserEngine.webkit;
    final bool isFirefox = browserEngine == BrowserEngine.firefox;
    // TODO(butterfly): use more efficient CSS selectors; descendant selectors
    //                  are slow. More info:
    //
    //                  https://csswizardry.com/2011/09/writing-efficient-css-selectors/

    // This undoes browser's default layout attributes for paragraphs. We
    // compute paragraph layout ourselves.
    if (isFirefox) {
      // For firefox set line-height, otherwise textx at same font-size will
      // measure differently in ruler.
      sheet.insertRule(
          'flt-ruler-host p, flt-scene p '
          '{ margin: 0; line-height: 100%;}',
          sheet.cssRules.length);
    } else {
      sheet.insertRule(
          'flt-ruler-host p, flt-scene p '
          '{ margin: 0; }',
          sheet.cssRules.length);
    }

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

    if (isWebKit) {
      sheet.insertRule(
          'flt-semantics input[type=range]::-webkit-slider-thumb {'
          '  -webkit-appearance: none;'
          '}',
          sheet.cssRules.length);
    }

    if (isFirefox) {
      sheet.insertRule(
          'input::-moz-selection {'
          '  background-color: transparent;'
          '}',
          sheet.cssRules.length);
      sheet.insertRule(
          'textarea::-moz-selection {'
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
      sheet.insertRule(
          'textarea::selection {'
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
    if (isWebKit) {
      sheet.insertRule('''
flt-glass-pane * {
  -webkit-tap-highlight-color: transparent;
}
''', sheet.cssRules.length);
    }

    // This css prevents an autofill overlay brought by the browser during
    // text field autofill by delaying the transition effect.
    // See: https://github.com/flutter/flutter/issues/61132.
    if(browserHasAutofillOverlay()) {
        sheet.insertRule('''
.transparentTextEditing:-webkit-autofill,
.transparentTextEditing:-webkit-autofill:hover,
.transparentTextEditing:-webkit-autofill:focus,
.transparentTextEditing:-webkit-autofill:active {
    -webkit-transition-delay: 99999s;
}
''', sheet.cssRules.length);
    }


    final html.BodyElement bodyElement = html.document.body!;
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
    // apps fully specify their text styles.
    setElementStyle(bodyElement, 'font', defaultCssFont);
    setElementStyle(bodyElement, 'color', 'red');

    // TODO(flutter_web): Disable spellcheck until changes in the framework and
    // engine are complete.
    bodyElement.spellcheck = false;

    for (html.Element viewportMeta
        in html.document.head!.querySelectorAll('meta[name="viewport"]')) {
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
    html.document.head!.append(_viewportMeta!);

    // IMPORTANT: the glass pane element must come after the scene element in the DOM node list so
    //            it can intercept input events.
    _glassPaneElement?.remove();
    final html.Element glassPaneElement = createElement('flt-glass-pane');
    _glassPaneElement = glassPaneElement;
    glassPaneElement.style
      ..position = 'absolute'
      ..top = '0'
      ..right = '0'
      ..bottom = '0'
      ..left = '0';
    bodyElement.append(glassPaneElement);

    _sceneHostElement = createElement('flt-scene-host');

    // Don't allow the scene to receive pointer events.
    _sceneHostElement!.style.pointerEvents = 'none';

    glassPaneElement.append(_sceneHostElement!);

    final html.Element _accesibilityPlaceholder = EngineSemanticsOwner
        .instance.semanticsHelper
        .prepareAccessibilityPlaceholder();

    // Insert the semantics placeholder after the scene host. For all widgets
    // in the scene, except for platform widgets, the scene host will pass the
    // pointer events through to the semantics tree. However, for platform
    // views, the pointer events will not pass through, and will be handled
    // by the platform view.
    glassPaneElement
        .insertBefore(_accesibilityPlaceholder, _sceneHostElement);

    PointerBinding.initInstance(glassPaneElement);

    // Hide the DOM nodes used to render the scene from accessibility, because
    // the accessibility tree is built from the SemanticsNode tree as a parallel
    // DOM tree.
    setElementAttribute(_sceneHostElement!, 'aria-hidden', 'true');

    if (html.window.visualViewport == null && isWebKit) {
      // Safari sometimes gives us bogus innerWidth/innerHeight values when the
      // page loads. When it changes the values to correct ones it does not
      // notify of the change via `onResize`. As a workaround, we setup a
      // temporary periodic timer that polls innerWidth and triggers the
      // resizeListener so that the framework can react to the change.
      //
      // Safari 13 has implemented visualViewport API so it doesn't need this
      // timer.
      //
      // VisualViewport API is not enabled in Firefox as well. On the other hand
      // Firefox returns correct values for innerHeight, innerWidth.
      // Firefox also triggers html.window.onResize therefore we don't need this
      // timer setup for Firefox.
      final int initialInnerWidth = html.window.innerWidth!;
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

    if (useCanvasKit) {
      _canvasKitScript?.remove();
      _canvasKitScript = html.ScriptElement();
      _canvasKitScript!.src = canvasKitBaseUrl + 'canvaskit.js';
      html.document.head!.append(_canvasKitScript!);
    }

    if (html.window.visualViewport != null) {
      _resizeSubscription =
          html.window.visualViewport!.onResize.listen(_metricsDidChange);
    } else {
      _resizeSubscription = html.window.onResize.listen(_metricsDidChange);
    }
    _localeSubscription = languageChangeEvent.forTarget(html.window)
      .listen(_languageDidChange);
    EnginePlatformDispatcher.instance._updateLocales();
  }

  /// Called immediately after browser window metrics change.
  ///
  /// When there is a text editing going on in mobile devices, do not change
  /// the physicalSize, change the [window.viewInsets]. See:
  /// https://api.flutter.dev/flutter/dart-ui/FlutterView/viewInsets.html
  /// https://api.flutter.dev/flutter/dart-ui/FlutterView/physicalSize.html
  ///
  /// Note: always check for rotations for a mobile device. Update the physical
  /// size if the change is caused by a rotation.
  void _metricsDidChange(html.Event? event) {
    if(isMobile && !window.isRotation() && textEditing.isEditing) {
      window.computeOnScreenKeyboardInsets();
      EnginePlatformDispatcher.instance.invokeOnMetricsChanged();
    } else {
      window._computePhysicalSize();
      // When physical size changes this value has to be recalculated.
      window.computeOnScreenKeyboardInsets();
      EnginePlatformDispatcher.instance.invokeOnMetricsChanged();
    }
  }

  /// Called immediately after browser window language change.
  void _languageDidChange(html.Event event) {
    EnginePlatformDispatcher.instance._updateLocales();
    if (ui.window.onLocaleChanged != null) {
      ui.window.onLocaleChanged!();
    }
  }

  void focus(html.Element element) {
    element.focus();
  }

  /// Removes all children of a DOM node.
  void clearDom(html.Node node) {
    while (node.lastChild != null) {
      node.lastChild!.remove();
    }
  }

  static bool? _ellipseFeatureDetected;

  /// Draws CanvasElement ellipse with fallback.
  static void ellipse(html.CanvasRenderingContext2D context,
      double centerX, double centerY, double radiusX, double radiusY,
      double rotation, double startAngle, double endAngle, bool antiClockwise) {
    _ellipseFeatureDetected ??= js_util.getProperty(context, 'ellipse') != null;
    if (_ellipseFeatureDetected!) {
      context.ellipse(centerX, centerY, radiusX, radiusY,
          rotation, startAngle, endAngle, antiClockwise);
    } else {
      context.save();
      context.translate(centerX, centerY);
      context.rotate(rotation);
      context.scale(radiusX, radiusY);
      context.arc(0, 0, 1, startAngle, endAngle, antiClockwise);
      context.restore();
    }
  }

  static const String orientationLockTypeAny = 'any';
  static const String orientationLockTypeNatural = 'natural';
  static const String orientationLockTypeLandscape = 'landscape';
  static const String orientationLockTypePortrait = 'portrait';
  static const String orientationLockTypePortraitPrimary = 'portrait-primary';
  static const String orientationLockTypePortraitSecondary = 'portrait-secondary';
  static const String orientationLockTypeLandscapePrimary = 'landscape-primary';
  static const String orientationLockTypeLandscapeSecondary = 'landscape-secondary';

  /// Sets preferred screen orientation.
  ///
  /// Specifies the set of orientations the application interface can be
  /// displayed in.
  ///
  /// The [orientations] argument is a list of DeviceOrientation values.
  /// The empty list uses Screen unlock api and causes the application to
  /// defer to the operating system default.
  ///
  /// See w3c screen api: https://www.w3.org/TR/screen-orientation/
  Future<bool> setPreferredOrientation(List<dynamic>? orientations) {
    final html.Screen screen = html.window.screen!;
    if (!_unsafeIsNull(screen)) {
      final html.ScreenOrientation? screenOrientation =
          screen.orientation;
      if (!_unsafeIsNull(screenOrientation)) {
        if (orientations!.isEmpty) {
          screenOrientation!.unlock();
          return Future.value(true);
        } else {
          String? lockType = _deviceOrientationToLockType(orientations.first);
          if (lockType != null) {
            final Completer<bool> completer = Completer<bool>();
            try {
              screenOrientation!.lock(lockType).then((dynamic _) {
                completer.complete(true);
              }).catchError((dynamic error) {
                // On Chrome desktop an error with 'not supported on this device
                // error' is fired.
                completer.complete(false);
              });
            } catch (_) {
              return Future.value(false);
            }
            return completer.future;
          }
        }
      }
    }
    // API is not supported on this browser return false.
    return Future.value(false);
  }

  // Converts device orientation to w3c OrientationLockType enum.
  static String? _deviceOrientationToLockType(String deviceOrientation) {
    switch(deviceOrientation) {
      case 'DeviceOrientation.portraitUp':
        return orientationLockTypePortraitPrimary;
      case 'DeviceOrientation.landscapeLeft':
        return orientationLockTypePortraitSecondary;
      case 'DeviceOrientation.portraitDown':
        return orientationLockTypeLandscapePrimary;
      case 'DeviceOrientation.landscapeRight':
        return orientationLockTypeLandscapeSecondary;
      default:
        return null;
    }
  }

  /// The element corresponding to the only child of the root surface.
  html.Element? get _rootApplicationElement {
    final html.Element lastElement = rootElement.children.last;
    for (html.Element child in lastElement.children) {
      if (child.tagName == 'FLT-SCENE') {
        return child;
      }
    }
    return null;
  }

  /// Provides haptic feedback.
  void vibrate(int durationMs) {
    final html.Navigator navigator = html.window.navigator;
    if (js_util.hasProperty(navigator, 'vibrate')) {
      js_util.callMethod(navigator, 'vibrate', <num>[durationMs]);
    }
  }

  String get currentHtml => _rootApplicationElement?.outerHtml ?? '';

  DebugDomRendererFrameStatistics? _debugFrameStatistics;

  DebugDomRendererFrameStatistics? debugFlushFrameStatistics() {
    if (!assertionsEnabled) {
      throw Exception('This code should not be reachable in production.');
    }
    final DebugDomRendererFrameStatistics? current = _debugFrameStatistics;
    _debugFrameStatistics = DebugDomRendererFrameStatistics();
    return current;
  }

  void debugRulerCacheHit() => _debugFrameStatistics!.paragraphRulerCacheHits++;
  void debugRulerCacheMiss() =>
      _debugFrameStatistics!.paragraphRulerCacheMisses++;
  void debugRichTextLayout() => _debugFrameStatistics!.richTextLayouts++;
  void debugPlainTextLayout() => _debugFrameStatistics!.plainTextLayouts++;
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
