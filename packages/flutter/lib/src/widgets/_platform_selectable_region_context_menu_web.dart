// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/rendering.dart';

import '../web.dart' as web;
import 'basic.dart';
import 'framework.dart';
import 'platform_view.dart';
import 'selection_container.dart';

const String _viewType = 'Browser__WebContextMenuViewType__';
const String _kClassName = 'web-selectable-region-context-menu';
// These css rules hides the dom element with the class name.
const String _kClassSelectionRule = '.$_kClassName::selection { background: transparent; }';
const String _kClassRule =
    '''
.$_kClassName {
  color: transparent;
  user-select: text;
  -webkit-user-select: text; /* Safari */
  -moz-user-select: text; /* Firefox */
  -ms-user-select: text; /* IE10+ */
}
''';
const int _kRightClickButton = 2;

typedef _WebSelectionCallBack = void Function(web.HTMLElement, web.MouseEvent);

/// Function signature for `ui_web.platformViewRegistry.registerViewFactory`.
@visibleForTesting
typedef RegisterViewFactory = void Function(String, Object Function(int viewId), {bool isVisible});

/// See `_platform_selectable_region_context_menu_io.dart` for full
/// documentation.
class PlatformSelectableRegionContextMenu extends StatefulWidget {
  /// See `_platform_selectable_region_context_menu_io.dart`.
  PlatformSelectableRegionContextMenu({
    required this.child,
    required SelectionContainerDelegate client,
    super.key,
  }) : _client = client {
    if (_registeredViewType == null) {
      _register();
    }
  }

  /// See `_platform_selectable_region_context_menu_io.dart`.
  final Widget child;

  /// The [SelectionContainerDelegate] for this region.
  final SelectionContainerDelegate _client;

  /// See `_platform_selectable_region_context_menu_io.dart`.
  // ignore: use_setters_to_change_properties
  static void attach(SelectionContainerDelegate activeClient) {
    _activeClient = activeClient;
    _activeElement = _elementsByClient[activeClient];
  }

  /// See `_platform_selectable_region_context_menu_io.dart`.
  static void detach(SelectionContainerDelegate activeClient) {
    if (_activeClient != activeClient) {
      _activeClient = null;
      _activeElement = null;
    }
  }

  /// The currently active [SelectionContainerDelegate].
  static SelectionContainerDelegate? _activeClient;

  /// The hidden element for [_activeClient].
  static web.HTMLElement? _activeElement;

  /// The next ID assigned to be assigned to next State instance to allow
  /// looking up the client for that instance.
  static int _nextElementId = 0;

  /// A mapping from element IDs (see [_nextElementId]) to
  /// [SelectionContainerDelegate]s.
  static final Map<int, SelectionContainerDelegate> _clientsByElementId =
      <int, SelectionContainerDelegate>{};

  /// A mapping of [SelectionContainerDelegate]s to their hidden elements.
  static final Map<SelectionContainerDelegate, web.HTMLElement> _elementsByClient =
      <SelectionContainerDelegate, web.HTMLElement>{};

  // Keeps track if this widget has already registered its view factories or not.
  static String? _registeredViewType;

  static RegisterViewFactory get _registerViewFactory =>
      debugOverrideRegisterViewFactory ?? ui_web.platformViewRegistry.registerViewFactory;

  /// Override this to provide a custom implementation of [ui_web.platformViewRegistry.registerViewFactory].
  ///
  /// This should only be used for testing.
  // See `_platform_selectable_region_context_menu_io.dart`.
  @visibleForTesting
  static RegisterViewFactory? debugOverrideRegisterViewFactory;

  /// Resets the view factory registration to its initial state.
  @visibleForTesting
  static void debugResetRegistry() {
    _registeredViewType = null;
    _activeClient = null;
    _activeElement = null;
    _nextElementId = 0;
    _clientsByElementId.clear();
    _elementsByClient.clear();
    web.document.body?.removeEventListener('copy', _copyEventHandler);
  }

  // Registers the view factories for the interceptor widgets.
  static void _register() {
    assert(_registeredViewType == null);
    web.document.body?.addEventListener('copy', _copyEventHandler);
    _registeredViewType = _registerWebSelectionCallback((
      web.HTMLElement element,
      web.MouseEvent event,
    ) {
      final SelectionContainerDelegate? client = _activeClient;
      if (client != null) {
        _activeElement = element;

        // Converts the html right click event to flutter coordinate.
        final localOffset = Offset(event.offsetX.toDouble(), event.offsetY.toDouble());
        final Matrix4 transform = client.getTransformTo(null);
        final Offset globalOffset = MatrixUtils.transformPoint(transform, localOffset);
        client.dispatchSelectionEvent(SelectWordSelectionEvent(globalPosition: globalOffset));

        _syncDomSelection(client, element);
      }
    });
  }

  /// Syncs the selection from [client] into the hidden [element].
  static void _syncDomSelection(SelectionContainerDelegate client, web.HTMLElement element) {
    // The innerText must contain the text in order to be selected by
    // the browser.
    element.innerText = client.getSelectedContent()?.plainText ?? '';

    // Programmatically select the dom element in browser.
    final web.Range range = web.document.createRange()..selectNode(element);

    web.window.getSelection()
      ?..removeAllRanges()
      ..addRange(range);
  }

  /// A handler for the document copy event to ensure the appropriate hidden
  /// element is updated.
  ///
  /// Registered in [_register] and unregistered in [debugResetRegistry].
  static final JSExportedDartFunction<Null Function(web.Event event)> _copyEventHandler =
      (web.Event event) {
        final SelectionContainerDelegate? client = _activeClient;
        final web.HTMLElement? element = _activeElement;
        if (client == null || element == null) {
          return;
        }
        _syncDomSelection(client, element);
      }.toJS;

  static String _registerWebSelectionCallback(_WebSelectionCallBack callback) {
    // Create css style for _kClassName.
    final styleElement = web.document.createElement('style') as web.HTMLStyleElement;
    web.document.head!.append(styleElement as JSAny);
    final web.CSSStyleSheet sheet = styleElement.sheet!;
    sheet.insertRule(_kClassRule, 0);
    sheet.insertRule(_kClassSelectionRule, 1);

    _registerViewFactory(_viewType, (int viewId, {Object? params}) {
      final htmlElement = web.document.createElement('div') as web.HTMLElement;
      htmlElement
        ..style.width = '100%'
        ..style.height = '100%'
        ..classList.add(_kClassName);

      // Keep track of this hidden element by the States element ID.
      final creationParams = params as Map<Object?, Object?>?;
      final elementId = creationParams?['elementId'] as int?;
      final SelectionContainerDelegate? client = _clientsByElementId[elementId];
      if (client != null) {
        _elementsByClient[client] = htmlElement;
        if (_activeClient == client) {
          _activeElement = htmlElement;
        }
      }

      htmlElement.addEventListener(
        'mousedown',
        (web.Event event) {
          final mouseEvent = event as web.MouseEvent;
          mouseEvent.preventDefault();
          if (mouseEvent.button != _kRightClickButton) {
            return;
          }
          callback(htmlElement, mouseEvent);
        }.toJS,
      );
      return htmlElement;
    }, isVisible: false);
    return _viewType;
  }

  @override
  State<PlatformSelectableRegionContextMenu> createState() =>
      _PlatformSelectableRegionContextMenuState();
}

class _PlatformSelectableRegionContextMenuState extends State<PlatformSelectableRegionContextMenu> {
  /// A unique ID that can be used to link this state back to the corresponding
  /// [SelectionContainerDelegate].
  late final int _elementId;

  @override
  void initState() {
    super.initState();
    _elementId = PlatformSelectableRegionContextMenu._nextElementId++;
    PlatformSelectableRegionContextMenu._clientsByElementId[_elementId] = widget._client;
  }

  @override
  void dispose() {
    PlatformSelectableRegionContextMenu._clientsByElementId.remove(_elementId);
    PlatformSelectableRegionContextMenu._elementsByClient.remove(widget._client);
    if (PlatformSelectableRegionContextMenu._activeClient == widget._client) {
      PlatformSelectableRegionContextMenu._activeElement = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        Positioned.fill(
          child: HtmlElementView(
            viewType: _viewType,
            creationParams: <String, int>{'elementId': _elementId},
          ),
        ),
        widget.child,
      ],
    );
  }
}
