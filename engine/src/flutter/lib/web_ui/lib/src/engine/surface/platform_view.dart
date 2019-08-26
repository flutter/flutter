// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

/// A surface containing a platform view, which is an HTML element.
class PersistedPlatformView extends PersistedLeafSurface {
  final int viewId;
  final double dx;
  final double dy;
  final double width;
  final double height;

  html.HtmlElement _hostElement;
  html.ShadowRoot _shadowRoot;

  PersistedPlatformView(this.viewId, this.dx, this.dy, this.width, this.height);

  @override
  html.Element createElement() {
    _hostElement = defaultCreateElement('flt-platform-view');

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
    _hostElement.style.pointerEvents = 'auto';

    _shadowRoot = _hostElement.attachShadow(<String, String>{'mode': 'open'});
    final html.StyleElement _styleReset = html.StyleElement();
    _styleReset.innerHtml = '''
      :host {
        all: initial;
      }''';
    _shadowRoot.append(_styleReset);
    final html.Element platformView =
        platformViewRegistry.getCreatedView(viewId);
    if (platformView != null) {
      _shadowRoot.append(platformView);
    } else {
      html.window.console.warn('No platform view created for id $viewId');
    }
    return _hostElement;
  }

  @override
  Matrix4 get localTransformInverse => null;

  @override
  void apply() {
    _hostElement.style
      ..transform = 'translate(${dx}px, ${dy}px)'
      ..width = '${width}px'
      ..height = '${height}px';
  }

  @override
  double matchForUpdate(PersistedPlatformView existingSurface) {
    return existingSurface.viewId == viewId ? 0.0 : 1.0;
  }
}
