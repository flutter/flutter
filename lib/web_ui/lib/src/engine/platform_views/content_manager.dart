// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

/// A function which takes a unique `id` and some `params` and creates an HTML element.
///
/// This is made available to end-users through dart:ui in web.
typedef ParameterizedPlatformViewFactory = html.Element Function(
  int viewId, {
  Object? params,
});

/// A function which takes a unique `id` and creates an HTML element.
///
/// This is made available to end-users through dart:ui in web.
typedef PlatformViewFactory = html.Element Function(int viewId);

/// This class handles the lifecycle of Platform Views in the DOM of a Flutter Web App.
///
/// There are three important parts of Platform Views. This class manages two of
/// them:
///
/// * `factories`: The functions used to render the contents of any given Platform
/// View by its `viewType`.
/// * `contents`: The result [html.Element] of calling a `factory` function.
///
/// The third part is `slots`, which are created on demand by the
/// [createPlatformViewSlot] function.
///
/// This class keeps a registry of `factories`, `contents` so the framework can
/// CRUD Platform Views as needed, regardless of the rendering backend.
class PlatformViewManager {
  // The factory functions, indexed by the viewType
  final Map<String, Function> _factories = {};

  // The references to content tags, indexed by their framework-given ID.
  final Map<int, html.Element> _contents = {};

  /// Returns `true` if the passed in `viewType` has been registered before.
  ///
  /// See [registerViewFactory] to understand how factories are registered.
  bool knowsViewType(String viewType) {
    return _factories.containsKey(viewType);
  }

  /// Returns `true` if the passed in `viewId` has been rendered (and not disposed) before.
  ///
  /// See [renderContent] and [createPlatformViewSlot] to understand how platform views are
  /// rendered.
  bool knowsViewId(int viewId) {
    return _contents.containsKey(viewId);
  }

  /// Registers a `factoryFunction` that knows how to render a Platform View of `viewType`.
  ///
  /// `viewType` is selected by the programmer, but it can't be overridden once
  /// it's been set.
  ///
  /// `factoryFunction` needs to be a [PlatformViewFactory].
  bool registerFactory(String viewType, Function factoryFunction) {
    assert(factoryFunction is PlatformViewFactory ||
        factoryFunction is ParameterizedPlatformViewFactory);

    if (_factories.containsKey(viewType)) {
      return false;
    }
    _factories[viewType] = factoryFunction;
    return true;
  }

  /// Creates the HTML markup for the `contents` of a Platform View.
  ///
  /// The result of this call is cached in the `_contents` Map. This is only
  /// cached so it can be disposed of later by [clearPlatformView]. _Note that
  /// there's no `getContents` function in this class._
  ///
  /// The resulting DOM for the `contents` of a Platform View looks like this:
  ///
  /// ```html
  /// <flt-platform-view slot="...">
  ///   <arbitrary-html-elements />
  /// </flt-platform-view-slot>
  /// ```
  ///
  /// The `arbitrary-html-elements` are the result of the call to the user-supplied
  /// `factory` function for this Platform View (see [registerFactory]).
  ///
  /// The outer `flt-platform-view` tag is a simple wrapper that we add to have
  /// a place where to attach the `slot` property, that will tell the browser
  /// what `slot` tag will reveal this `contents`, **without modifying the returned
  /// html from the `factory` function**.
  html.Element renderContent(
    String viewType,
    int viewId,
    Object? params,
  ) {
    assert(knowsViewType(viewType),
        'Attempted to render contents of unregistered viewType: $viewType');

    final String slotName = getPlatformViewSlotName(viewId);

    return _contents.putIfAbsent(viewId, () {
      final html.Element wrapper = html.document
          .createElement('flt-platform-view')
            ..setAttribute('slot', slotName);

      final Function factoryFunction = _factories[viewType]!;
      late html.Element content;

      if (factoryFunction is ParameterizedPlatformViewFactory) {
        content = factoryFunction(viewId, params: params);
      } else {
        content = factoryFunction(viewId);
      }

      _ensureContentCorrectlySized(content, viewType);

      return wrapper..append(content);
    });
  }

  /// Removes a PlatformView by its `viewId` from the manager, and from the DOM.
  ///
  /// Once a view has been cleared, calls [knowsViewId] will fail, as if it had
  /// never been rendered before.
  void clearPlatformView(int viewId) {
    // Remove from our cache, and then from the DOM...
    final html.Element? element = _contents.remove(viewId);
    _safelyRemoveSlottedElement(element);
  }

  // We need to remove slotted elements like this because of a Safari bug that
  // gets triggered when a slotted element is removed in a JS event different
  // than its slot (after the slot is removed).
  //
  // TODO(web): Cleanup https://github.com/flutter/flutter/issues/85816
  void _safelyRemoveSlottedElement(html.Element? element) {
    if (element == null) {
      return;
    }
    if (browserEngine != BrowserEngine.webkit) {
      element.remove();
      return;
    }
    final String tombstoneName = "tombstone-${element.getAttribute('slot')}";
    // Create and inject a new slot in the shadow root
    final html.Element slot = html.document.createElement('slot')
      ..style.display = 'none'
      ..setAttribute('name', tombstoneName);
    domRenderer._glassPaneShadow!.append(slot);
    // Link the element to the new slot
    element.setAttribute('slot', tombstoneName);
    // Delete both the element, and the new slot
    element.remove();
    slot.remove();
  }

  /// Attempt to ensure that the contents of the user-supplied DOM element will
  /// fill the space allocated for this platform view by the framework.
  void _ensureContentCorrectlySized(html.Element content, String viewType) {
    // Scrutinize closely any other modifications to `content`.
    // We shouldn't modify users' returned `content` if at all possible.
    // Note there's also no getContent(viewId) function anymore, to prevent
    // from later modifications too.
    if (content.style.height.isEmpty) {
      printWarning('Height of Platform View type: [$viewType] may not be set.'
          ' Defaulting to `height: 100%`.\n'
          'Set `style.height` to any appropriate value to stop this message.');

      content.style.height = '100%';
    }

    if (content.style.width.isEmpty) {
      printWarning('Width of Platform View type: [$viewType] may not be set.'
          ' Defaulting to `width: 100%`.\n'
          'Set `style.width` to any appropriate value to stop this message.');

      content.style.width = '100%';
    }
  }

  /// Clears the state. Used in tests.
  ///
  /// Returns the set of know view ids, so they can be cleaned up.
  Set<int> debugClear() {
    final Set<int> result = _contents.keys.toSet();
    for (int viewId in result) {
      clearPlatformView(viewId);
    }
    _factories.clear();
    _contents.clear();
    return result;
  }
}
