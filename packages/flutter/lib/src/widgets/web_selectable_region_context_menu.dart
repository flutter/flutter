// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;

import 'package:flutter/rendering.dart';

import '_dart_ui_io.dart' if(dart.library.html) 'dart:ui' as ui;
import 'basic.dart';
import 'framework.dart';
import 'platform_view.dart';
import 'selection_container.dart';

const String _viewType = 'Browser__WebContextMenuViewType__';
const String _kClassName = 'web-electable-region-context-menu';
// The below css rule makes sure the hidden dom element is invisible to the user.
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

typedef _WebSelectionCallBack = void Function(html.Element, html.MouseEvent);

/// Function signature for `ui.platformViewRegistry.registerViewFactory`.
@visibleForTesting
typedef RegisterViewFactory = void Function(String, Object Function(int viewId), {bool isVisible});

/// A widget that provides browser selection context menu for the child subtree
///
/// This widget can only be used in flutter web.
///
/// This widget register a platform view, i.e. a html dom element, with the web
/// platform. The platform view is a singleton shared between all
/// [WebSelectableRegionContextMenu]s. Only one [SelectionContainerDelegate]
/// can attach to the the platform view at a time. Use [attach] method to make
/// a [SelectionContainerDelegate] to be the active client.
class WebSelectableRegionContextMenu extends StatelessWidget {
  /// Creates a BrowserContextMenu for the web.
  WebSelectableRegionContextMenu({
    required this.child,
    super.key,
  }) {
    if (_registeredViewType == null) {
      _register();
    }
  }

  /// The `Widget` that is being wrapped by this `WebSelectableRegionContextMenu`.
  final Widget child;

  /// Attaches the `client` to be able to open browser selection context menu.
  // ignore: use_setters_to_change_properties
  static void attach(SelectionContainerDelegate client) {
    _activeClient = client;
  }

  /// Detaches the `client` from the browser selection context menu.
  static void detach(SelectionContainerDelegate client) {
    if (_activeClient != client) {
      _activeClient = null;
    }
  }

  static SelectionContainerDelegate? _activeClient;

  // Keeps track if this widget has already registered its view factories or not.
  static String? _registeredViewType;

  /// The factory to create a dom element.
  @visibleForTesting
  static RegisterViewFactory factory = ui.platformViewRegistry.registerViewFactory;

  // Registers the view factories for the interceptor widgets.
  static void _register() {
    assert(_registeredViewType == null);
    _registeredViewType = _registerWebSelectionCallback((html.Element element, html.MouseEvent event) {
      final SelectionContainerDelegate? client = _activeClient;
      if (client != null) {
        // Converts the html right click event to flutter coordinate.
        final Offset localOffset = Offset(event.offset.x.toDouble(), event.offset.y.toDouble());
        final Matrix4 transform = client.getTransformTo(null);
        final Offset globalOffset = MatrixUtils.transformPoint(transform, localOffset);
        client.dispatchSelectionEvent(SelectWordSelectionEvent(globalPosition: globalOffset));
        // The innerText must contain the text in order to be selected by
        // the browser.
        element.innerText = client.getSelectedContent()?.plainText ?? '';

        // Programmatically select the dom element in browser.
        final html.Range range = html.document.createRange();
        range.selectNode(element);
        final html.Selection? selection = html.window.getSelection();
        if (selection != null) {
          selection.removeAllRanges();
          selection.addRange(range);
        }
      }
    });
  }

  static String _registerWebSelectionCallback(_WebSelectionCallBack callback) {
    factory(_viewType, (int viewId) {
      final html.Element htmlElement = html.DivElement();
      htmlElement
        ..style.width = '100%'
        ..style.height = '100%'
        ..classes.add(_kClassName);

      // Create css style for _kClassName.
      final html.StyleElement styleElement = html.StyleElement();
      html.document.head!.append(styleElement);
      final html.CssStyleSheet sheet = styleElement.sheet! as html.CssStyleSheet;
      sheet.insertRule(_kClassRule, 0);
      sheet.insertRule(_kClassSelectionRule, 1);

      htmlElement.onMouseDown.listen((html.MouseEvent event) {
        if (event.button != _kRightClickButton) {
          return;
        }
        callback(htmlElement, event);
      });
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
        Positioned.fill(child: child),
      ],
    );
  }
}
