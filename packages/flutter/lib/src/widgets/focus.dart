// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'basic.dart';
import 'framework.dart';
import 'media_query.dart';
import 'scrollable.dart';

// _noFocusedScope is used by Focus to track the case where none of the Focus
// widget's subscopes (e.g. dialogs) are focused. This is distinct from the
// focused scope being null, which means that we haven't yet decided which scope
// is focused and whichever is the first scope to ask for focus will get it.
final GlobalKey _noFocusedScope = new GlobalKey();

class _FocusScope extends InheritedWidget {
  _FocusScope({
    Key key,
    this.focusState,
    this.scopeFocused: true, // are we focused in our ancestor scope?
    this.focusedScope, // which of our descendant scopes is focused, if any?
    this.focusedWidget,
    Widget child
  }) : super(key: key, child: child);

  final _FocusState focusState;
  final bool scopeFocused;

  // These are mutable because we implicitly change them when they're null in
  // certain cases, basically pretending retroactively that we were constructed
  // with the right keys.
  GlobalKey focusedScope;
  GlobalKey focusedWidget;

  // The _setFocusedWidgetIfUnset() methodsdon't need to notify descendants
  // because by definition they are only going to make a change the very first
  // time that our state is checked.

  void _setFocusedWidgetIfUnset(GlobalKey key) {
    focusState._setFocusedWidgetIfUnset(key);
    focusedWidget = focusState._focusedWidget;
    focusedScope = focusState._focusedScope == _noFocusedScope ? null : focusState._focusedScope;
  }

  @override
  bool updateShouldNotify(_FocusScope oldWidget) {
    if (scopeFocused != oldWidget.scopeFocused)
      return true;
    if (!scopeFocused)
      return false;
    if (focusedScope != oldWidget.focusedScope)
      return true;
    if (focusedScope != null)
      return false;
    if (focusedWidget != oldWidget.focusedWidget)
      return true;
    return false;
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (scopeFocused)
      description.add('this scope has focus');
    if (focusedScope != null)
      description.add('focused subscope: $focusedScope');
    if (focusedWidget != null)
      description.add('focused widget: $focusedWidget');
  }
}

/// A scope for managing the focus state of descendant widgets.
///
/// The focus represents where the user's attention is directed. If the use
/// interacts with the system in a way that isn't visually directed at a
/// particular widget (e.g., by typing on a keyboard), the interaction is
/// directed to the currently focused widget.
///
/// The focus system consists of a tree of Focus widgets, which is embedded in
/// the widget tree. Focus widgets themselves can be focused in their enclosing
/// Focus widget, which means that their subtree is the one that has the current
/// focus. For example, a dialog creates a Focus widget to maintain focus
/// within the dialog.  When the dialog closes, its Focus widget is removed from
/// the tree and focus is restored to whichever other part of the Focus tree
/// previously had focus.
///
/// In addition to tracking which enclosed Focus widget has focus, each Focus
/// widget also tracks a GlobalKey, which represents the currently focused
/// widget in this part of the focus tree. If this Focus widget is the currently
/// focused subtree of the focus system (i.e., the path from it to the root is
/// focused at each level and it hasn't focused any of its enclosed Focus
/// widgets), then the widget this this global key actually has the focus in the
/// entire system.
class Focus extends StatefulWidget {
  Focus({
    GlobalKey key,
    this.child
  }) : super(key: key) {
    assert(key != null);
  }

  /// The widget below this widget in the tree.
  final Widget child;

  /// The key that currently has focus globally in the entire focus tree.
  ///
  /// This field is always null except in checked mode.
  static GlobalKey debugOnlyFocusedKey;

  /// Whether the focus is current at the given context.
  ///
  /// If autofocus is true, the given context will become focused if no other
  /// widget is already focused.
  static bool at(BuildContext context, { bool autofocus: false }) {
    assert(context != null);
    assert(context.widget != null);
    assert(context.widget.key != null);
    assert(context.widget.key is GlobalKey);
    _FocusScope focusScope = context.inheritFromWidgetOfExactType(_FocusScope);
    if (focusScope != null) {
      if (autofocus)
        focusScope._setFocusedWidgetIfUnset(context.widget.key);
      return focusScope.scopeFocused &&
             focusScope.focusedScope == null &&
             focusScope.focusedWidget == context.widget.key;
    }
    assert(() {
      if (debugOnlyFocusedKey?.currentContext == null)
        debugOnlyFocusedKey = context.widget.key;
      if (debugOnlyFocusedKey != context.widget.key) {
        throw new FlutterError(
          'Missing Focus scope.\n'
          'Two focusable widgets with different keys, $debugOnlyFocusedKey and ${context.widget.key}, '
          'exist in the widget tree simultaneously, but they have no Focus widget ancestor.\n'
          'If you have more than one focusable widget, then you should put them inside a Focus. '
          'Normally, this is done for you using a Route, via Navigator, WidgetsApp, or MaterialApp.'
        );
      }
      return true;
    });
    return true;
  }

  static bool _atScope(BuildContext context) {
    assert(context != null);
    assert(context.widget != null);
    assert(context.widget is Focus);
    assert(context.widget.key != null);
    _FocusScope focusScope = context.inheritFromWidgetOfExactType(_FocusScope);
    if (focusScope != null) {
      return focusScope.scopeFocused &&
             focusScope.focusedScope == context.widget.key;
    }
    return true;
  }

  /// Focuses a particular widget, identified by its GlobalKey.
  /// The widget must be in the widget tree.
  ///
  /// Don't call moveTo() from your build() functions, it's intended to be
  /// called from event listeners, e.g. in response to a finger tap or tab key.
  static void moveTo(GlobalKey key) {
    BuildContext focusedContext = key.currentContext;
    assert(focusedContext != null);
    _FocusScope focusScope = key.currentContext.ancestorWidgetOfExactType(_FocusScope);
    if (focusScope != null) {
      focusScope.focusState._setFocusedWidget(key);
      Scrollable.ensureVisible(focusedContext);
    }
  }

  /// Unfocuses the currently focused widget (if any) in the Focus that most
  /// tightly encloses the given context.
  static void clear(BuildContext context) {
    _FocusScope focusScope = context.ancestorWidgetOfExactType(_FocusScope);
    if (focusScope != null)
      focusScope.focusState._clearFocusedWidget();
  }

  /// Focuses a particular focus scope, identified by its GlobalKey.
  ///
  /// Don't call moveScopeTo() from your build() functions, it's intended to be
  /// called from event listeners, e.g. in response to a finger tap or tab key.
  static void moveScopeTo(GlobalKey key, { BuildContext context }) {
    _FocusScope focusScope;
    BuildContext searchContext = key.currentContext;
    if (searchContext != null) {
      assert(key.currentWidget is Focus);
      focusScope = searchContext.ancestorWidgetOfExactType(_FocusScope);
      assert(context == null || focusScope == context.ancestorWidgetOfExactType(_FocusScope));
    } else {
      focusScope = context.ancestorWidgetOfExactType(_FocusScope);
    }
    if (focusScope != null)
      focusScope.focusState._setFocusedScope(key);
  }

  @override
  _FocusState createState() => new _FocusState();
}

class _FocusState extends State<Focus> {
  @override
  void initState() {
    super.initState();
    _updateWidgetRemovalListener(_focusedWidget);
    _updateScopeRemovalListener(_focusedScope);
  }

  @override
  void dispose() {
    _updateWidgetRemovalListener(null);
    _updateScopeRemovalListener(null);
    super.dispose();
  }

  GlobalKey _focusedWidget; // when null, the first widget to ask if it's focused will get the focus
  GlobalKey _currentlyRegisteredWidgetRemovalListenerKey;

  void _setFocusedWidget(GlobalKey key) {
    setState(() {
      _focusedWidget = key;
      if (_focusedScope == null)
        _focusedScope = _noFocusedScope;
    });
    _updateWidgetRemovalListener(key);
  }

  void _setFocusedWidgetIfUnset(GlobalKey key) {
    if (_focusedWidget == null && (_focusedScope == null || _focusedScope == _noFocusedScope)) {
      _focusedWidget = key;
      _focusedScope = _noFocusedScope;
      _updateWidgetRemovalListener(key);
    }
  }

  void _clearFocusedWidget() {
    if (_focusedWidget != null) {
      _updateWidgetRemovalListener(null);
      setState(() {
        _focusedWidget = null;
      });
    }
  }

  void _handleWidgetRemoved(GlobalKey key) {
    assert(key != null);
    assert(_focusedWidget == key);
    _clearFocusedWidget();
  }

  void _updateWidgetRemovalListener(GlobalKey key) {
    if (_currentlyRegisteredWidgetRemovalListenerKey != key) {
      if (_currentlyRegisteredWidgetRemovalListenerKey != null)
        GlobalKey.unregisterRemoveListener(_currentlyRegisteredWidgetRemovalListenerKey, _handleWidgetRemoved);
      if (key != null)
        GlobalKey.registerRemoveListener(key, _handleWidgetRemoved);
      _currentlyRegisteredWidgetRemovalListenerKey = key;
    }
  }

  GlobalKey _focusedScope; // when null, the first scope to ask if it's focused will get the focus
  GlobalKey _currentlyRegisteredScopeRemovalListenerKey;

  void _setFocusedScope(GlobalKey key) {
    setState(() {
      _focusedScope = key;
    });
    _updateScopeRemovalListener(key);
  }

  void _scopeRemoved(GlobalKey key) {
    assert(_focusedScope == key);
    GlobalKey.unregisterRemoveListener(_currentlyRegisteredScopeRemovalListenerKey, _scopeRemoved);
    _currentlyRegisteredScopeRemovalListenerKey = null;
    setState(() {
      _focusedScope = null;
    });
  }

  void _updateScopeRemovalListener(GlobalKey key) {
    if (_currentlyRegisteredScopeRemovalListenerKey != key) {
      if (_currentlyRegisteredScopeRemovalListenerKey != null)
        GlobalKey.unregisterRemoveListener(_currentlyRegisteredScopeRemovalListenerKey, _scopeRemoved);
      if (key != null)
        GlobalKey.registerRemoveListener(key, _scopeRemoved);
      _currentlyRegisteredScopeRemovalListenerKey = key;
    }
  }

  Size _mediaSize;
  EdgeInsets _mediaPadding;

  void _ensureVisibleIfFocused() {
    if (!Focus._atScope(context))
      return;
    BuildContext focusedContext = _focusedWidget?.currentContext;
    if (focusedContext == null)
      return;
    Scrollable.ensureVisible(focusedContext);
  }

  @override
  Widget build(BuildContext context) {
    MediaQueryData data = MediaQuery.of(context);
    Size newMediaSize = data.size;
    EdgeInsets newMediaPadding = data.padding;
    if (newMediaSize != _mediaSize || newMediaPadding != _mediaPadding) {
      _mediaSize = newMediaSize;
      _mediaPadding = newMediaPadding;
      scheduleMicrotask(_ensureVisibleIfFocused);
    }
    return new Semantics(
      container: true,
      child: new _FocusScope(
        focusState: this,
        scopeFocused: Focus._atScope(context),
        focusedScope: _focusedScope == _noFocusedScope ? null : _focusedScope,
        focusedWidget: _focusedWidget,
        child: config.child
      )
    );
  }
}
