// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:ui/src/engine/safe_browser_api.dart';
import 'package:ui/ui.dart' as ui;

import '../engine.dart' show buildMode, renderer, window;
import 'browser_detection.dart';
import 'configuration.dart';
import 'dom.dart';
import 'global_styles.dart';
import 'keyboard_binding.dart';
import 'platform_dispatcher.dart';
import 'pointer_binding.dart';
import 'semantics.dart';
import 'text_editing/text_editing.dart';
import 'view_embedder/dimensions_provider/dimensions_provider.dart';
import 'view_embedder/embedding_strategy/embedding_strategy.dart';

/// Controls the placement and lifecycle of a Flutter view on the web page.
///
/// Manages several top-level elements that host Flutter-generated content,
/// including:
///
/// - [flutterViewElement], the root element of a Flutter view.
/// - [glassPaneElement], the glass pane element that hosts the shadowDOM.
/// - [glassPaneShadow], the shadow root used to isolate Flutter-rendered
///   content from the surrounding page content, including from the platform
///   views.
/// - [sceneElement], the element that hosts Flutter layers and pictures, and
///   projects platform views.
/// - [sceneHostElement], the anchor that provides a stable location in the DOM
///   tree for the [sceneElement].
/// - [semanticsHostElement], hosts the ARIA-annotated semantics tree.
///
/// This class is currently a singleton, but it'll possibly need to morph to have
/// multiple instances in a multi-view scenario. (One ViewEmbedder per FlutterView).
class FlutterViewEmbedder {
  /// Creates a FlutterViewEmbedder.
  ///
  /// The incoming [hostElement] parameter specifies the root element in the DOM
  /// into which Flutter will be rendered.
  ///
  /// The hostElement is abstracted by an [EmbeddingStrategy] instance, which has
  /// different behavior depending on the `hostElement` value:
  ///
  /// - A `null` `hostElement` will cause Flutter to take over the whole page.
  /// - A non-`null` `hostElement` will render flutter inside that element.
  FlutterViewEmbedder({DomElement? hostElement})
      : _embeddingStrategy =
            EmbeddingStrategy.create(hostElement: hostElement) {
    // Configure the EngineWindow so it knows how to measure itself.
    // TODO(dit): Refactor ownership according to new design, https://github.com/flutter/flutter/issues/117098
    window.configureDimensionsProvider(DimensionsProvider.create(
      hostElement: hostElement,
    ));

    reset();
  }

  /// Abstracts all the DOM manipulations required to embed a Flutter app in an user-supplied `hostElement`.
  final EmbeddingStrategy _embeddingStrategy;

  // The tag name for the Flutter View, which hosts the app.
  static const String flutterViewTagName = 'flutter-view';

  // The tag name for the glass-pane.
  static const String glassPaneTagName = 'flt-glass-pane';

  /// The element that contains the [sceneElement].
  ///
  /// This element is created and inserted in the HTML DOM once. It is never
  /// removed or moved. However the [sceneElement] may be replaced inside it.
  ///
  /// This element is inserted after the [semanticsHostElement] so that
  /// platform views take precedence in DOM event handling.
  DomElement? get sceneHostElement => _sceneHostElement;
  DomElement? _sceneHostElement;

  /// A child element of body outside the shadowroot that hosts
  /// global resources such svg filters and clip paths when using webkit.
  DomElement? _resourcesHost;

  /// The element that contains the semantics tree.
  ///
  /// This element is created and inserted in the HTML DOM once. It is never
  /// removed or moved.
  ///
  /// Render semantics inside the glasspane for proper focus and event
  /// handling. If semantics is behind the glasspane, the phone will disable
  /// focusing by touch, only by tabbing around the UI. If semantics is in
  /// front of glasspane, then DOM event won't bubble up to the glasspane so
  /// it can forward events to the framework.
  ///
  /// This element is inserted before the [semanticsHostElement] so that
  /// platform views take precedence in DOM event handling.
  DomElement? get semanticsHostElement => _semanticsHostElement;
  DomElement? _semanticsHostElement;

  /// The last scene element rendered by the [render] method.
  DomElement? get sceneElement => _sceneElement;
  DomElement? _sceneElement;

  /// Don't unnecessarily move DOM nodes around. If a DOM node is
  /// already in the right place, skip DOM mutation. This is both faster and
  /// more correct, because moving DOM nodes loses internal state, such as
  /// text selection.
  void addSceneToSceneHost(DomElement? sceneElement) {
    if (sceneElement != _sceneElement) {
      _sceneElement?.remove();
      _sceneElement = sceneElement;
      _sceneHostElement!.append(sceneElement!);
    }
  }

  /// The element that captures input events, such as pointer events.
  ///
  /// If semantics is enabled this element also contains the semantics DOM tree,
  /// which captures semantics input events. The semantics DOM tree must be a
  /// child of the glass pane element so that events bubble up to the glass pane
  /// if they are not handled by semantics.
  DomElement get flutterViewElement => _flutterViewElement;
  late DomElement _flutterViewElement;

  DomElement get glassPaneElement => _glassPaneElement;
  late DomElement _glassPaneElement;

  /// The shadow root of the [glassPaneElement], which contains the whole Flutter app.
  DomShadowRoot get glassPaneShadow => _glassPaneShadow;
  late DomShadowRoot _glassPaneShadow;

  DomElement get textEditingHostNode => _textEditingHostNode;
  late DomElement _textEditingHostNode;

  static const String defaultFontStyle = 'normal';
  static const String defaultFontWeight = 'normal';
  static const double defaultFontSize = 14;
  static const String defaultFontFamily = 'sans-serif';
  static const String defaultCssFont =
      '$defaultFontStyle $defaultFontWeight ${defaultFontSize}px $defaultFontFamily';

  void reset() {
    // How was the current renderer selected?
    const String rendererSelection = FlutterConfiguration.flutterWebAutoDetect
        ? 'auto-selected'
        : 'requested explicitly';

    // Initializes the embeddingStrategy so it can host a single-view Flutter app.
    _embeddingStrategy.initialize(
      hostElementAttributes: <String, String>{
        'flt-renderer': '${renderer.rendererTag} ($rendererSelection)',
        'flt-build-mode': buildMode,
        // TODO(mdebbar): Disable spellcheck until changes in the framework and
        // engine are complete.
        'spellcheck': 'false',
      },
    );

    // Create and inject the [_glassPaneElement].
    _flutterViewElement = domDocument.createElement(flutterViewTagName);
    _glassPaneElement = domDocument.createElement(glassPaneTagName);


    // This must be attached to the DOM now, so the engine can create a host
    // node (ShadowDOM or a fallback) next.
    //
    // The embeddingStrategy will take care of cleaning up the glassPane on hot
    // restart.
    _embeddingStrategy.attachGlassPane(flutterViewElement);
    flutterViewElement.appendChild(glassPaneElement);

    if (getJsProperty<Object?>(glassPaneElement, 'attachShadow') == null) {
      throw UnsupportedError('ShadowDOM is not supported in this browser.');
    }

    // Create a [HostNode] under the glass pane element, and attach everything
    // there, instead of directly underneath the glass panel.
    final DomShadowRoot shadowRoot = glassPaneElement.attachShadow(<String, dynamic>{
      'mode': 'open',
      // This needs to stay false to prevent issues like this:
      // - https://github.com/flutter/flutter/issues/85759
      'delegatesFocus': false,
    });
    _glassPaneShadow = shadowRoot;

    final DomHTMLStyleElement shadowRootStyleElement = createDomHTMLStyleElement();
    shadowRootStyleElement.id = 'flt-internals-stylesheet';
    // The shadowRootStyleElement must be appended to the DOM, or its `sheet` will be null later.
    shadowRoot.appendChild(shadowRootStyleElement);
    applyGlobalCssRulesToSheet(
      shadowRootStyleElement,
      defaultCssFont: defaultCssFont,
    );

    _textEditingHostNode =
        createTextEditingHostNode(flutterViewElement, defaultCssFont);

    // Don't allow the scene to receive pointer events.
    _sceneHostElement = domDocument.createElement('flt-scene-host')
      ..style.pointerEvents = 'none';

    renderer.reset(this);

    final DomElement semanticsHostElement =
        domDocument.createElement('flt-semantics-host');
    semanticsHostElement.style
      ..position = 'absolute'
      ..transformOrigin = '0 0 0';
    _semanticsHostElement = semanticsHostElement;
    updateSemanticsScreenProperties();

    final DomElement accessibilityPlaceholder = EngineSemanticsOwner
        .instance.semanticsHelper
        .prepareAccessibilityPlaceholder();

    shadowRoot.append(accessibilityPlaceholder);
    shadowRoot.append(_sceneHostElement!);

    // The semantic host goes last because hit-test order-wise it must be
    // first. If semantics goes under the scene host, platform views will
    // obscure semantic elements.
    //
    // You may be wondering: wouldn't semantics obscure platform views and
    // make then not accessible? At least with some careful planning, that
    // should not be the case. The semantics tree makes all of its non-leaf
    // elements transparent. This way, if a platform view appears among other
    // interactive Flutter widgets, as long as those widgets do not intersect
    // with the platform view, the platform view will be reachable.
    flutterViewElement.appendChild(semanticsHostElement);

    // When debugging semantics, make the scene semi-transparent so that the
    // semantics tree is more prominent.
    if (configuration.debugShowSemanticsNodes) {
      _sceneHostElement!.style.opacity = '0.3';
    }

    KeyboardBinding.initInstance();
    PointerBinding.initInstance(
      flutterViewElement,
      KeyboardBinding.instance!.converter,
    );

    window.onResize.listen(_metricsDidChange);
  }

  /// The framework specifies semantics in physical pixels, but CSS uses
  /// logical pixels. To compensate, an inverse scale is injected at the root
  /// level.
  void updateSemanticsScreenProperties() {
    _semanticsHostElement!.style
        .setProperty('transform', 'scale(${1 / window.devicePixelRatio})');
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
  void _metricsDidChange(ui.Size? newSize) {
    updateSemanticsScreenProperties();
    // TODO(dit): Do not computePhysicalSize twice, https://github.com/flutter/flutter/issues/117036
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
    final DomScreen? screen = domWindow.screen;
    if (screen != null) {
      final DomScreenOrientation? screenOrientation = screen.orientation;
      if (screenOrientation != null) {
        if (orientations.isEmpty) {
          screenOrientation.unlock();
          return Future<bool>.value(true);
        } else {
          final String? lockType =
              _deviceOrientationToLockType(orientations.first as String?);
          if (lockType != null) {
            final Completer<bool> completer = Completer<bool>();
            try {
              screenOrientation.lock(lockType).then((dynamic _) {
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
  //
  // See also: https://developer.mozilla.org/en-US/docs/Web/API/ScreenOrientation/lock
  static String? _deviceOrientationToLockType(String? deviceOrientation) {
    switch (deviceOrientation) {
      case 'DeviceOrientation.portraitUp':
        return orientationLockTypePortraitPrimary;
      case 'DeviceOrientation.portraitDown':
        return orientationLockTypePortraitSecondary;
      case 'DeviceOrientation.landscapeLeft':
        return orientationLockTypeLandscapePrimary;
      case 'DeviceOrientation.landscapeRight':
        return orientationLockTypeLandscapeSecondary;
      default:
        return null;
    }
  }

  /// Add an element as a global resource to be referenced by CSS.
  ///
  /// This call create a global resource host element on demand and either
  /// place it as first element of body(webkit), or as a child of
  /// glass pane element for other browsers to make sure url resolution
  /// works correctly when content is inside a shadow root.
  void addResource(DomElement element) {
    final bool isWebKit = browserEngine == BrowserEngine.webkit;
    if (_resourcesHost == null) {
      final DomElement resourcesHost = domDocument
          .createElement('flt-svg-filters')
        ..style.visibility = 'hidden';
      if (isWebKit) {
        // The resourcesHost *must* be a sibling of the glassPaneElement.
        _embeddingStrategy.attachResourcesHost(resourcesHost,
            nextTo: flutterViewElement);
      } else {
        glassPaneShadow.insertBefore(resourcesHost, glassPaneShadow.firstChild);
      }
      _resourcesHost = resourcesHost;
    }
    _resourcesHost!.append(element);
  }

  /// Removes a global resource element.
  void removeResource(DomElement? element) {
    if (element == null) {
      return;
    }
    assert(element.parentNode == _resourcesHost);
    element.remove();
  }

  /// Disables the browser's context menu for this part of the DOM.
  ///
  /// By default, when a Flutter web app starts, the context menu is enabled.
  ///
  /// Can be re-enabled by calling [enableContextMenu].
  void disableContextMenu() => _embeddingStrategy.disableContextMenu();

  /// Enables the browser's context menu for this part of the DOM.
  ///
  /// By default, when a Flutter web app starts, the context menu is already
  /// enabled. Typically, this method would be used after calling
  /// [disableContextMenu] to first disable it.
  void enableContextMenu() => _embeddingStrategy.enableContextMenu();
}

/// The embedder singleton.
///
/// [ensureFlutterViewEmbedderInitialized] must be called prior to calling this
/// getter.
FlutterViewEmbedder get flutterViewEmbedder {
  final FlutterViewEmbedder? embedder = _flutterViewEmbedder;
  assert(() {
    if (embedder == null) {
      throw StateError(
          'FlutterViewEmbedder not initialized. Call `ensureFlutterViewEmbedderInitialized()` '
          'prior to calling the `flutterViewEmbedder` getter.');
    }
    return true;
  }());
  return embedder!;
}

FlutterViewEmbedder? _flutterViewEmbedder;

/// Initializes the [FlutterViewEmbedder], if it's not already initialized.
FlutterViewEmbedder ensureFlutterViewEmbedderInitialized() =>
    _flutterViewEmbedder ??=
        FlutterViewEmbedder(hostElement: configuration.hostElement);

/// Creates a node to host text editing elements and applies a stylesheet
/// to Flutter nodes that exist outside of the shadowDOM.
DomElement createTextEditingHostNode(DomElement root, String defaultFont) {
  final DomElement domElement =
      domDocument.createElement('flt-text-editing-host');
  final DomHTMLStyleElement styleElement = createDomHTMLStyleElement();

  styleElement.id = 'flt-text-editing-stylesheet';
  root.appendChild(styleElement);
  applyGlobalCssRulesToSheet(
    styleElement,
    cssSelectorPrefix: FlutterViewEmbedder.flutterViewTagName,
    defaultCssFont: defaultFont,
  );

  root.appendChild(domElement);

  return domElement;
}
