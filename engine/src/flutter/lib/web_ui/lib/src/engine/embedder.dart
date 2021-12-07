// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:html' as html;

import 'package:ui/ui.dart' as ui;

import '../engine.dart' show buildMode, registerHotRestartListener;
import 'browser_detection.dart';
import 'canvaskit/initialization.dart';
import 'configuration.dart';
import 'host_node.dart';
import 'keyboard_binding.dart';
import 'platform_dispatcher.dart';
import 'pointer_binding.dart';
import 'safe_browser_api.dart';
import 'semantics.dart';
import 'text_editing/text_editing.dart';
import 'util.dart';
import 'window.dart';

/// Controls the placement and lifecycle of a Flutter view on the web page.
///
/// Manages several top-level elements that host Flutter-generated content,
/// including:
///
/// - [glassPaneElement], the root element of a Flutter view.
/// - [glassPaneShadow], the shadow root used to isolate Flutter-rendered
///   content from the surrounding page content, including from the platform
///   views.
/// - [sceneElement], the element that hosts Flutter layers and pictures, and
///   projects platform views.
/// - [sceneHostElement], the anchor that provides a stable location in the DOM
///   tree for the [sceneElement].
/// - [semanticsHostElement], hosts the ARIA-annotated semantics tree.
class FlutterViewEmbedder {
  FlutterViewEmbedder() {
    reset();
    assert(() {
      _setupHotRestart();
      return true;
    }());
  }

  // The tag name for the root view of the flutter app (glass-pane)
  static const String _glassPaneTagName = 'flt-glass-pane';

  /// Fires when browser language preferences change.
  static const html.EventStreamProvider<html.Event> languageChangeEvent =
      html.EventStreamProvider<html.Event>('languagechange');

  /// Listens to window resize events.
  StreamSubscription<html.Event>? _resizeSubscription;

  /// Listens to window locale events.
  StreamSubscription<html.Event>? _localeSubscription;

  /// Contains Flutter-specific CSS rules, such as default margins and
  /// paddings.
  html.StyleElement? _styleElement;

  /// Configures the screen, such as scaling.
  html.MetaElement? _viewportMeta;

  /// The element that contains the [sceneElement].
  ///
  /// This element is created and inserted in the HTML DOM once. It is never
  /// removed or moved. However the [sceneElement] may be replaced inside it.
  ///
  /// This element is inserted after the [semanticsHostElement] so that
  /// platform views take precedence in DOM event handling.
  html.Element? get sceneHostElement => _sceneHostElement;
  html.Element? _sceneHostElement;

  /// A child element of body outside the shadowroot that hosts
  /// global resources such svg filters and clip paths when using webkit.
  html.Element? _resourcesHost;

  /// The element that contains the semantics tree.
  ///
  /// This element is created and inserted in the HTML DOM once. It is never
  /// removed or moved.
  ///
  /// We render semantics inside the glasspane for proper focus and event
  /// handling. If semantics is behind the glasspane, the phone will disable
  /// focusing by touch, only by tabbing around the UI. If semantics is in
  /// front of glasspane, then DOM event won't bubble up to the glasspane so
  /// it can forward events to the framework.
  ///
  /// This element is inserted before the [semanticsHostElement] so that
  /// platform views take precedence in DOM event handling.
  html.Element? get semanticsHostElement => _semanticsHostElement;
  html.Element? _semanticsHostElement;

  /// The last scene element rendered by the [render] method.
  html.Element? get sceneElement => _sceneElement;
  html.Element? _sceneElement;

  /// This is state persistent across hot restarts that indicates what
  /// to clear.  We delay removal of old visible state to make the
  /// transition appear smooth.
  static const String _staleHotRestartStore = '__flutter_state';
  List<html.Element?>? _staleHotRestartState;

  void _setupHotRestart() {
    // This persists across hot restarts to clear stale DOM.
    _staleHotRestartState = getJsProperty<List<html.Element?>?>(html.window, _staleHotRestartStore);
    if (_staleHotRestartState == null) {
      _staleHotRestartState = <html.Element?>[];
      setJsProperty(
          html.window, _staleHotRestartStore, _staleHotRestartState);
    }

    registerHotRestartListener(() {
      _resizeSubscription?.cancel();
      _localeSubscription?.cancel();
      _staleHotRestartState!.addAll(<html.Element?>[
        _glassPaneElement,
        _styleElement,
        _viewportMeta,
      ]);
    });
  }

  void _clearOnHotRestart() {
    if (_staleHotRestartState!.isNotEmpty) {
      for (final html.Element? element in _staleHotRestartState!) {
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
      _sceneHostElement!.append(sceneElement!);
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

  /// The [HostNode] of the [glassPaneElement], which contains the whole Flutter app.
  HostNode? get glassPaneShadow => _glassPaneShadow;
  HostNode? _glassPaneShadow;

  final html.Element rootElement = html.document.body!;

  static const String defaultFontStyle = 'normal';
  static const String defaultFontWeight = 'normal';
  static const double defaultFontSize = 14;
  static const String defaultFontFamily = 'sans-serif';
  static const String defaultCssFont =
      '$defaultFontStyle $defaultFontWeight ${defaultFontSize}px $defaultFontFamily';

  void reset() {
    final bool isWebKit = browserEngine == BrowserEngine.webkit;

    _styleElement?.remove();
    _styleElement = html.StyleElement();
    _resourcesHost?.remove();
    _resourcesHost = null;
    html.document.head!.append(_styleElement!);
    final html.CssStyleSheet sheet = _styleElement!.sheet! as html.CssStyleSheet;
    applyGlobalCssRulesToSheet(
      sheet,
      browserEngine: browserEngine,
      hasAutofillOverlay: browserHasAutofillOverlay(),
    );

    final html.BodyElement bodyElement = html.document.body!;

    bodyElement.setAttribute(
      'flt-renderer',
      '${useCanvasKit ? 'canvaskit' : 'html'} (${FlutterConfiguration.flutterWebAutoDetect ? 'auto-selected' : 'requested explicitly'})',
    );
    bodyElement.setAttribute('flt-build-mode', buildMode);

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

    // TODO(mdebbar): Disable spellcheck until changes in the framework and
    // engine are complete.
    bodyElement.spellcheck = false;

    for (final html.Element viewportMeta
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
    final html.Element glassPaneElement = html.document.createElement(_glassPaneTagName);
    _glassPaneElement = glassPaneElement;
    glassPaneElement.style
      ..position = 'absolute'
      ..top = '0'
      ..right = '0'
      ..bottom = '0'
      ..left = '0';

    // This must be appended to the body, so we can create a host node properly.
    bodyElement.append(glassPaneElement);

    // Create a [HostNode] under the glass pane element, and attach everything
    // there, instead of directly underneath the glass panel.
    final HostNode glassPaneElementHostNode = _createHostNode(glassPaneElement);
    _glassPaneShadow = glassPaneElementHostNode;

    // Don't allow the scene to receive pointer events.
    _sceneHostElement = html.document.createElement('flt-scene-host')
      ..style.pointerEvents = 'none';

    final html.Element semanticsHostElement =
        html.document.createElement('flt-semantics-host');
    semanticsHostElement.style
      ..position = 'absolute'
      ..transformOrigin = '0 0 0';
    _semanticsHostElement = semanticsHostElement;
    updateSemanticsScreenProperties();

    final html.Element _accessibilityPlaceholder = EngineSemanticsOwner
        .instance.semanticsHelper
        .prepareAccessibilityPlaceholder();

    glassPaneElementHostNode.nodes.addAll(<html.Node>[
      semanticsHostElement,
      _accessibilityPlaceholder,
      _sceneHostElement!,
    ]);

    // When debugging semantics, make the scene semi-transparent so that the
    // semantics tree is visible.
    if (configuration.debugShowSemanticsNodes) {
      _sceneHostElement!.style.opacity = '0.3';
    }

    PointerBinding.initInstance(glassPaneElement);
    KeyboardBinding.initInstance(glassPaneElement);

    // Hide the DOM nodes used to render the scene from accessibility, because
    // the accessibility tree is built from the SemanticsNode tree as a parallel
    // DOM tree.
    _sceneHostElement!.setAttribute('aria-hidden', 'true');

    if (html.window.visualViewport == null && isWebKit) {
      // Older Safari versions sometimes give us bogus innerWidth/innerHeight
      // values when the page loads. When it changes the values to correct ones
      // it does not notify of the change via `onResize`. As a workaround, we
      // set up a temporary periodic timer that polls innerWidth and triggers
      // the resizeListener so that the framework can react to the change.
      //
      // Safari 13 has implemented visualViewport API so it doesn't need this
      // timer.
      //
      // VisualViewport API is not enabled in Firefox as well. On the other hand
      // Firefox returns correct values for innerHeight, innerWidth.
      // Firefox also triggers html.window.onResize therefore we don't need this
      // timer to be set up for Firefox.
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

    if (html.window.visualViewport != null) {
      _resizeSubscription =
          html.window.visualViewport!.onResize.listen(_metricsDidChange);
    } else {
      _resizeSubscription = html.window.onResize.listen(_metricsDidChange);
    }
    _localeSubscription =
        languageChangeEvent.forTarget(html.window).listen(_languageDidChange);
    EnginePlatformDispatcher.instance.updateLocales();
  }

  // Creates a [HostNode] into a `root` [html.Element].
  HostNode _createHostNode(html.Element root) {
    if (getJsProperty<Object?>(root, 'attachShadow') != null) {
      return ShadowDomHostNode(root);
    } else {
      // attachShadow not available, fall back to ElementHostNode.
      return ElementHostNode(root);
    }
  }

  /// The framework specifies semantics in physical pixels, but CSS uses
  /// logical pixels. To compensate, we inject an inverse scale at the root
  /// level.
  void updateSemanticsScreenProperties() {
    _semanticsHostElement!.style.transform =
        'scale(${1 / html.window.devicePixelRatio})';
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
    updateSemanticsScreenProperties();
    if (isMobile && !window.isRotation() && textEditing.isEditing) {
      window.computeOnScreenKeyboardInsets(true);
      EnginePlatformDispatcher.instance.invokeOnMetricsChanged();
    } else {
      window.computePhysicalSize();
      // When physical size changes this value has to be recalculated.
      window.computeOnScreenKeyboardInsets(false);
      EnginePlatformDispatcher.instance.invokeOnMetricsChanged();
    }
  }

  /// Called immediately after browser window language change.
  void _languageDidChange(html.Event event) {
    EnginePlatformDispatcher.instance.updateLocales();
    if (ui.window.onLocaleChanged != null) {
      ui.window.onLocaleChanged!();
    }
  }

  static const String orientationLockTypeAny = 'any';
  static const String orientationLockTypeNatural = 'natural';
  static const String orientationLockTypeLandscape = 'landscape';
  static const String orientationLockTypePortrait = 'portrait';
  static const String orientationLockTypePortraitPrimary = 'portrait-primary';
  static const String orientationLockTypePortraitSecondary =
      'portrait-secondary';
  static const String orientationLockTypeLandscapePrimary = 'landscape-primary';
  static const String orientationLockTypeLandscapeSecondary =
      'landscape-secondary';

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
  Future<bool> setPreferredOrientation(List<dynamic> orientations) {
    final html.Screen screen = html.window.screen!;
    if (!unsafeIsNull(screen)) {
      final html.ScreenOrientation? screenOrientation = screen.orientation;
      if (!unsafeIsNull(screenOrientation)) {
        if (orientations.isEmpty) {
          screenOrientation!.unlock();
          return Future<bool>.value(true);
        } else {
          final String? lockType =
              _deviceOrientationToLockType(orientations.first as String?);
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
              return Future<bool>.value(false);
            }
            return completer.future;
          }
        }
      }
    }
    // API is not supported on this browser return false.
    return Future<bool>.value(false);
  }

  // Converts device orientation to w3c OrientationLockType enum.
  static String? _deviceOrientationToLockType(String? deviceOrientation) {
    switch (deviceOrientation) {
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
    for (final html.Element child in lastElement.children) {
      if (child.tagName == 'FLT-SCENE') {
        return child;
      }
    }
    return null;
  }

  /// Add an element as a global resource to be referenced by CSS.
  ///
  /// This call create a global resource host element on demand and either
  /// place it as first element of body(webkit), or as a child of
  /// glass pane element for other browsers to make sure url resolution
  /// works correctly when content is inside a shadow root.
  void addResource(html.Element element) {
    final bool isWebKit = browserEngine == BrowserEngine.webkit;
    if (_resourcesHost == null) {
      _resourcesHost = html.DivElement()
        ..style.visibility = 'hidden';
      if (isWebKit) {
        final html.Node bodyNode = html.document.body!;
        bodyNode.insertBefore(_resourcesHost!, bodyNode.firstChild);
      } else {
        _glassPaneShadow!.node.insertBefore(
            _resourcesHost!, _glassPaneShadow!.node.firstChild);
      }
    }
    _resourcesHost!.append(element);
  }

  /// Removes a global resource element.
  void removeResource(html.Element? element) {
    if (element == null) {
      return;
    }
    assert(element.parent == _resourcesHost);
    element.remove();
  }

  String get currentHtml => _rootApplicationElement?.outerHtml ?? '';
}

// Applies the required global CSS to an incoming [html.CssStyleSheet] `sheet`.
void applyGlobalCssRulesToSheet(
  html.CssStyleSheet sheet, {
  required BrowserEngine browserEngine,
  required bool hasAutofillOverlay,
  String glassPaneTagName = FlutterViewEmbedder._glassPaneTagName,
}) {
  final bool isWebKit = browserEngine == BrowserEngine.webkit;
  final bool isFirefox = browserEngine == BrowserEngine.firefox;
  // TODO(web): use more efficient CSS selectors; descendant selectors are slow.
  // More info: https://csswizardry.com/2011/09/writing-efficient-css-selectors

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
  sheet.insertRule(
    '''
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
    }
    ''',
    sheet.cssRules.length,
  );

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
      $glassPaneTagName * {
      -webkit-tap-highlight-color: transparent;
    }
    ''', sheet.cssRules.length);
  }

  // Hide placeholder text
  sheet.insertRule(
    '''
    .flt-text-editing::placeholder {
      opacity: 0;
    }
    ''',
    sheet.cssRules.length,
  );

  // This css prevents an autofill overlay brought by the browser during
  // text field autofill by delaying the transition effect.
  // See: https://github.com/flutter/flutter/issues/61132.
  if (browserHasAutofillOverlay()) {
    sheet.insertRule('''
      .transparentTextEditing:-webkit-autofill,
      .transparentTextEditing:-webkit-autofill:hover,
      .transparentTextEditing:-webkit-autofill:focus,
      .transparentTextEditing:-webkit-autofill:active {
        -webkit-transition-delay: 99999s;
      }
    ''', sheet.cssRules.length);
  }
}

/// The embedder singleton.
FlutterViewEmbedder get flutterViewEmbedder => ensureFlutterViewEmbedderInitialized();

/// Initializes the [FlutterViewEmbedder], if it's not already initialized.
FlutterViewEmbedder ensureFlutterViewEmbedderInitialized() => _flutterViewEmbedder ??= FlutterViewEmbedder();
FlutterViewEmbedder? _flutterViewEmbedder;
