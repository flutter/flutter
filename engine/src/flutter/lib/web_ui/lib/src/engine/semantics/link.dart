// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../dom.dart';
import '../semantics.dart';

/// Provides accessibility for links.
///
/// For same-origin URLs, click events are intercepted and the browser's default
/// navigation is prevented. Instead, the URL is pushed via the browser's
/// History API and a popstate event is dispatched, which the framework's
/// BrowserHistory listens to and forwards to the Router.
///
/// For cross-origin URLs, the browser's default navigation is allowed so that
/// external links work as expected.
class SemanticLink extends SemanticRole {
  SemanticLink(SemanticsObject semanticsObject)
    : super.withBasics(
        EngineSemanticsRole.link,
        semanticsObject,
        preferredLabelRepresentation: LabelRepresentation.domText,
      ) {
    addTappable();
    _addLinkClickInterceptor();
  }

  DomEventListener? _clickListener;

  @override
  DomElement createElement() {
    final DomElement element = domDocument.createElement('a');
    element.style.display = 'block';
    return element;
  }

  /// Intercepts click events on the anchor element to prevent the browser's
  /// default navigation for same-origin URLs and instead push the route via
  /// the browser's History API.
  ///
  /// Without this, clicking a semantic link with an `href` causes a full page
  /// navigation, reinitializing the Flutter engine and losing all app state.
  void _addLinkClickInterceptor() {
    _clickListener = createDomEventListener((DomEvent event) {
      final String? href = element.getAttribute('href');
      if (href case final href? when _isSameOrigin(href)) {
        event.preventDefault();
        domWindow.history.pushState(null, '', href);
        domWindow.dispatchEvent(DomPopStateEvent('popstate'));
      }
    });
    element.addEventListener('click', _clickListener);
  }

  /// Returns `true` if [href] points to the same origin as the current page.
  ///
  /// Relative URLs (e.g., `/legal/terms`) are always same-origin. Absolute URLs
  /// are compared by their origin (scheme + host + port). Protocol-relative
  /// URLs (e.g., `//example.com/page`) are resolved using the current scheme.
  static bool _isSameOrigin(String href) {
    if (href.startsWith('/') && !href.startsWith('//')) {
      return true;
    }

    final Uri? uri = Uri.tryParse(href);
    if (uri == null) {
      return false;
    }

    if (!uri.hasScheme) {
      if (uri.host.isEmpty) {
        return true;
      }
      // Protocol-relative URL (e.g., "//other.com/foo"). Prepend the current
      // scheme so origin comparison works correctly.
      final String currentScheme = Uri.parse(domWindow.location.href).scheme;
      final Uri fullUri = Uri.parse('$currentScheme:$href');
      return fullUri.origin == domWindow.location.origin;
    }

    return uri.origin == domWindow.location.origin;
  }

  @override
  void update() {
    super.update();

    if (semanticsObject.isLinkUrlDirty) {
      if (semanticsObject.hasLinkUrl) {
        element.setAttribute('href', semanticsObject.linkUrl!);
      } else {
        element.removeAttribute('href');
      }
    }
  }

  @override
  void dispose() {
    if (_clickListener case final listener?) {
      element.removeEventListener('click', listener);
      _clickListener = null;
    }
    super.dispose();
  }

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
}
