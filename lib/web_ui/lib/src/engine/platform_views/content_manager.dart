// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../browser_detection.dart';
import '../dom.dart';
import '../embedder.dart';
import '../util.dart';
import 'slots.dart';

/// A function which takes a unique `id` and some `params` and creates an HTML element.
///
/// This is made available to end-users through dart:ui in web.
typedef ParameterizedPlatformViewFactory = DomElement Function(
  int viewId, {
  Object? params,
});

/// A function which takes a unique `id` and creates an HTML element.
///
/// This is made available to end-users through dart:ui in web.
typedef PlatformViewFactory = DomElement Function(int viewId);

/// This class handles the lifecycle of Platform Views in the DOM of a Flutter Web App.
///
/// There are three important parts of Platform Views. This class manages two of
/// them:
///
/// * `factories`: The functions used to render the contents of any given Platform
/// View by its `viewType`.
/// * `contents`: The result [DomElement] of calling a `factory` function.
///
/// The third part is `slots`, which are created on demand by the
/// [createPlatformViewSlot] function.
///
/// This class keeps a registry of `factories`, `contents` so the framework can
/// CRUD Platform Views as needed, regardless of the rendering backend.
class PlatformViewManager {
  // The factory functions, indexed by the viewType
  final Map<String, Function> _factories = <String, Function>{};

  // The references to content tags, indexed by their framework-given ID.
  final Map<int, DomElement> _contents = <int, DomElement>{};

  final Set<String> _invisibleViews = <String>{};
  final Map<int, String> _viewIdToType = <int, String>{};

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
  bool registerFactory(String viewType, Function factoryFunction,
      {bool isVisible = true}) {
    assert(factoryFunction is PlatformViewFactory ||
        factoryFunction is ParameterizedPlatformViewFactory);

    if (_factories.containsKey(viewType)) {
      return false;
    }
    _factories[viewType] = factoryFunction;
    if (!isVisible) {
      _invisibleViews.add(viewType);
    }
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
  DomElement renderContent(
    String viewType,
    int viewId,
    Object? params,
  ) {
    assert(knowsViewType(viewType),
        'Attempted to render contents of unregistered viewType: $viewType');

    final String slotName = getPlatformViewSlotName(viewId);
    _viewIdToType[viewId] = viewType;

    return _contents.putIfAbsent(viewId, () {
      final DomElement wrapper = domDocument
          .createElement('flt-platform-view')
            ..setAttribute('slot', slotName);

      final Function factoryFunction = _factories[viewType]!;
      late DomElement content;

      if (factoryFunction is ParameterizedPlatformViewFactory) {
        content = factoryFunction(viewId, params: params);
      } else {
        content = (factoryFunction as PlatformViewFactory).call(viewId);
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
    final DomElement? element = _contents.remove(viewId);
    _safelyRemoveSlottedElement(element);
  }

  // We need to remove slotted elements like this because of a Safari bug that
  // gets triggered when a slotted element is removed in a JS event different
  // than its slot (after the slot is removed).
  //
  // TODO(web): Cleanup https://github.com/flutter/flutter/issues/85816
  void _safelyRemoveSlottedElement(DomElement? element) {
    if (element == null) {
      return;
    }
    if (browserEngine != BrowserEngine.webkit) {
      element.remove();
      return;
    }
    final String tombstoneName = "tombstone-${element.getAttribute('slot')}";
    // Create and inject a new slot in the shadow root
    final DomElement slot = domDocument.createElement('slot')
      ..style.display = 'none'
      ..setAttribute('name', tombstoneName);
    flutterViewEmbedder.glassPaneShadow!.append(slot);
    // Link the element to the new slot
    element.setAttribute('slot', tombstoneName);
    // Delete both the element, and the new slot
    element.remove();
    slot.remove();
  }

  /// Attempt to ensure that the contents of the user-supplied DOM element will
  /// fill the space allocated for this platform view by the framework.
  void _ensureContentCorrectlySized(DomElement content, String viewType) {
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

  /// Returns `true` if the given [viewId] is for an invisible platform view.
  bool isInvisible(int viewId) {
    final String? viewType = _viewIdToType[viewId];
    return viewType != null && _invisibleViews.contains(viewType);
  }

  /// Returns `true` if the given [viewId] is a platform view with a visible
  /// component.
  bool isVisible(int viewId) => !isInvisible(viewId);

  /// Clears the state. Used in tests.
  ///
  /// Returns the set of know view ids, so they can be cleaned up.
  Set<int> debugClear() {
    final Set<int> result = _contents.keys.toSet();
    result.forEach(clearPlatformView);
    _factories.clear();
    _contents.clear();
    _invisibleViews.clear();
    _viewIdToType.clear();
    return result;
  }
}
