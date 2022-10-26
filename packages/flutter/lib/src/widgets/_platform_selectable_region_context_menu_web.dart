// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:js/js.dart';

import '../services/dom.dart';
import 'basic.dart';
import 'framework.dart';
import 'platform_view.dart';
import 'selection_container.dart';

const String _viewType = 'Browser__WebContextMenuViewType__';
const String _kClassName = 'web-electable-region-context-menu';
// These css rules hides the dom element with the class name.
const String _kClassSelectionRule = '.$_kClassName::selection { background: transparent; }';
const String _kClassRule = '''
.$_kClassName {
  color: transparent;
  user-select: text;
  -webkit-user-select: text; /* Safari */
  -moz-user-select: text; /* Firefox */
  -ms-user-select: text; /* IE10+ */
}
''';
const int _kRightClickButton = 2;

typedef _WebSelectionCallBack = void Function(DomHTMLElement, DomMouseEvent);

/// Function signature for `ui.platformViewRegistry.registerViewFactory`.
@visibleForTesting
typedef RegisterViewFactory = void Function(String, Object Function(int viewId), {bool isVisible});

/// See `_platform_selectable_region_context_menu_io.dart` for full
/// documentation.
class PlatformSelectableRegionContextMenu extends StatelessWidget {
  /// See `_platform_selectable_region_context_menu_io.dart`.
  PlatformSelectableRegionContextMenu({
    required this.child,
    super.key,
  }) {
    if (_registeredViewType == null) {
      _register();
    }
  }

  /// See `_platform_selectable_region_context_menu_io.dart`.
  final Widget child;

  /// See `_platform_selectable_region_context_menu_io.dart`.
  // ignore: use_setters_to_change_properties
  static void attach(SelectionContainerDelegate client) {
    _activeClient = client;
  }

  /// See `_platform_selectable_region_context_menu_io.dart`.
  static void detach(SelectionContainerDelegate client) {
    if (_activeClient != client) {
      _activeClient = null;
    }
  }

  static SelectionContainerDelegate? _activeClient;

  // Keeps track if this widget has already registered its view factories or not.
  static String? _registeredViewType;

  /// See `_platform_selectable_region_context_menu_io.dart`.
  @visibleForTesting
  // ignore: undefined_prefixed_name, invalid_assignment, avoid_dynamic_calls
  static RegisterViewFactory registerViewFactory = ui.platformViewRegistry.registerViewFactory;

  // Registers the view factories for the interceptor widgets.
  static void _register() {
    assert(_registeredViewType == null);
    _registeredViewType = _registerWebSelectionCallback((DomHTMLElement element, DomMouseEvent event) {
      final SelectionContainerDelegate? client = _activeClient;
      if (client != null) {
        // Converts the html right click event to flutter coordinate.
        final Offset localOffset = Offset(event.offsetX.toDouble(), event.offsetY.toDouble());
        final Matrix4 transform = client.getTransformTo(null);
        final Offset globalOffset = MatrixUtils.transformPoint(transform, localOffset);
        client.dispatchSelectionEvent(SelectWordSelectionEvent(globalPosition: globalOffset));
        // The innerText must contain the text in order to be selected by
        // the browser.
        element.innerText = client.getSelectedContent()?.plainText ?? '';

        // Programmatically select the dom element in browser.
        final DomRange range = domDocument.createRange();
        range.selectNode(element);
        final DomSelection? selection = domWindow.getSelection();
        if (selection != null) {
          selection.removeAllRanges();
          selection.addRange(range);
        }
      }
    });
  }

  static String _registerWebSelectionCallback(_WebSelectionCallBack callback) {
    registerViewFactory(_viewType, (int viewId) {
      final DomHTMLElement htmlElement = createDomHTMLDivElement();
      htmlElement
        ..style.width = '100%'
        ..style.height = '100%'
        ..classList.add(_kClassName);

      // Create css style for _kClassName.
      final DomHTMLStyleElement styleElement = createDomHTMLStyleElement();
      domDocument.head!.append(styleElement);
      final DomCSSStyleSheet sheet = styleElement.sheet! as DomCSSStyleSheet;
      sheet.insertRule(_kClassRule, 0);
      sheet.insertRule(_kClassSelectionRule, 1);

      htmlElement.addEventListener('mousedown', allowInterop((DomEvent event) {
        final DomMouseEvent mouseEvent = event as DomMouseEvent;
        if (mouseEvent.button != _kRightClickButton) {
          return;
        }
        callback(htmlElement, mouseEvent);
      }));
      return htmlElement;
    }, isVisible: false);
    return _viewType;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        const Positioned.fill(
          child: HtmlElementView(
            viewType: _viewType,
          ),
        ),
        child,
      ],
    );
  }
}
