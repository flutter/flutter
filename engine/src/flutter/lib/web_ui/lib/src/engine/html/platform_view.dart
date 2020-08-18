// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.10
part of engine;

/// A surface containing a platform view, which is an HTML element.
class PersistedPlatformView extends PersistedLeafSurface {
  final int viewId;
  final double dx;
  final double dy;
  final double width;
  final double height;

  late html.ShadowRoot _shadowRoot;

  PersistedPlatformView(this.viewId, this.dx, this.dy, this.width, this.height);

  @override
  html.Element createElement() {
    html.Element element = defaultCreateElement('flt-platform-view');

    // Allow the platform view host element to receive pointer events.
    //
    // This is to allow platform view HTML elements to be interactive.
    //
    // ACCESSIBILITY NOTE: The way we enable accessibility on Flutter for web
    // is to have a full-page button which waits for a double tap. Placing this
    // full-page button in front of the scene would cause platform views not
    // to receive pointer events. The tradeoff is that by placing the scene in
    // front of the semantics placeholder will cause platform views to block
    // pointer events from reaching the placeholder. This means that in order
    // to enable accessibility, you must double tap the app *outside of a
    // platform view*. As a consequence, a full-screen platform view will make
    // it impossible to enable accessibility.
    element.style.pointerEvents = 'auto';

    // Enforce the effective size of the PlatformView.
    element.style.overflow = 'hidden';

    _shadowRoot = element.attachShadow(<String, String>{'mode': 'open'});
    final html.StyleElement _styleReset = html.StyleElement();
    _styleReset.innerHtml = '''
      :host {
        all: initial;
      }''';
    _shadowRoot.append(_styleReset);
    final html.Element? platformView =
        ui.platformViewRegistry.getCreatedView(viewId);
    if (platformView != null) {
      _shadowRoot.append(platformView);
    } else {
      html.window.console.warn('No platform view created for id $viewId');
    }
    return element;
  }

  @override
  Matrix4? get localTransformInverse => null;

  @override
  void apply() {
    rootElement!.style
      ..transform = 'translate(${dx}px, ${dy}px)'
      ..width = '${width}px'
      ..height = '${height}px';
    // Set size of the root element created by the PlatformView.
    final html.Element? platformView =
        ui.platformViewRegistry.getCreatedView(viewId);
    if (platformView != null) {
      platformView.style
        ..width = '${width}px'
        ..height = '${height}px';
    }
  }

  @override
  double matchForUpdate(PersistedPlatformView existingSurface) {
    return existingSurface.viewId == viewId ? 0.0 : 1.0;
  }

  @override
  void update(PersistedPlatformView oldSurface) {
    super.update(oldSurface);
    if (viewId != oldSurface.viewId) {
      // The content of the surface has to be rebuild if the viewId is changed.
      build();
    } else if (dx != oldSurface.dx ||
        dy != oldSurface.dy ||
        width != oldSurface.width ||
        height != oldSurface.height) {
      // A change in any of the dimensions is performed by calling apply.
      apply();
    }
  }
}
