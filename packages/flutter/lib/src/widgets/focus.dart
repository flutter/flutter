// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'framework.dart';

// _noFocusedScope is used by Focus to track the case where none of the Focus
// component's subscopes (e.g. dialogs) are focused. This is distinct from the
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

  final FocusState focusState;
  final bool scopeFocused;

  // These are mutable because we implicitly change them when they're null in
  // certain cases, basically pretending retroactively that we were constructed
  // with the right keys.
  GlobalKey focusedScope;
  GlobalKey focusedWidget;

  // The ...IfUnset() methods don't need to notify descendants because by
  // definition they are only going to make a change the very first time that
  // our state is checked.

  void _setFocusedWidgetIfUnset(GlobalKey key) {
    focusState._setFocusedWidgetIfUnset(key);
    focusedWidget = focusState._focusedWidget;
    focusedScope = focusState._focusedScope == _noFocusedScope ? null : focusState._focusedScope;
  }

  void _setFocusedScopeIfUnset(GlobalKey key) {
    focusState._setFocusedScopeIfUnset(key);
    assert(focusedWidget == focusState._focusedWidget);
    focusedScope = focusState._focusedScope == _noFocusedScope ? null : focusState._focusedScope;
  }

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

class Focus extends StatefulComponent {
  Focus({
    GlobalKey key, // key is required if this is a nested Focus scope
    this.autofocus: false,
    this.child
  }) : super(key: key) {
    assert(!autofocus || key != null);
  }

  final bool autofocus;
  final Widget child;

  static bool at(BuildContext context, Widget widget, { bool autofocus: true }) {
    assert(widget != null);
    assert(widget.key is GlobalKey);
    _FocusScope focusScope = context.inheritFromWidgetOfType(_FocusScope);
    if (focusScope != null) {
      if (autofocus)
        focusScope._setFocusedWidgetIfUnset(widget.key);
      return focusScope.scopeFocused &&
             focusScope.focusedScope == null &&
             focusScope.focusedWidget == widget.key;
    }
    return true;
  }

  static bool _atScope(BuildContext context, Widget widget, { bool autofocus: true }) {
    assert(widget != null);
    _FocusScope focusScope = context.inheritFromWidgetOfType(_FocusScope);
    if (focusScope != null) {
      if (autofocus)
        focusScope._setFocusedScopeIfUnset(widget.key);
      assert(widget.key != null);
      return focusScope.scopeFocused &&
             focusScope.focusedScope == widget.key;
    }
    return true;
  }

  // Don't call moveTo() and moveScopeTo() from your build()
  // functions, it's intended to be called from event listeners, e.g.
  // in response to a finger tap or tab key.

  static void moveTo(BuildContext context, Widget widget) {
    assert(widget != null);
    assert(widget.key is GlobalKey);
    _FocusScope focusScope = context.inheritFromWidgetOfType(_FocusScope);
    if (focusScope != null)
      focusScope.focusState._setFocusedWidget(widget.key);
  }

  static void moveScopeTo(BuildContext context, Focus component) {
    assert(component != null);
    assert(component.key != null);
    _FocusScope focusScope = context.inheritFromWidgetOfType(_FocusScope);
    if (focusScope != null)
      focusScope.focusState._setFocusedScope(component.key);
  }

  FocusState createState() => new FocusState();
}

class FocusState extends State<Focus> {
  GlobalKey _focusedWidget; // when null, the first component to ask if it's focused will get the focus
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

  void _handleWidgetRemoved(GlobalKey key) {
    assert(_focusedWidget == key);
    _updateWidgetRemovalListener(null);
    setState(() {
      _focusedWidget = null;
    });
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

  void _setFocusedScopeIfUnset(GlobalKey key) {
    if (_focusedScope == null) {
      _focusedScope = key;
      _updateScopeRemovalListener(key);
    }
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

  void initState() {
    super.initState();
    _updateWidgetRemovalListener(_focusedWidget);
    _updateScopeRemovalListener(_focusedScope);
  }

  void dispose() {
    _updateWidgetRemovalListener(null);
    _updateScopeRemovalListener(null);
    super.dispose();
  }

  Widget build(BuildContext context) {
    return new _FocusScope(
      focusState: this,
      scopeFocused: Focus._atScope(context, config),
      focusedScope: _focusedScope == _noFocusedScope ? null : _focusedScope,
      focusedWidget: _focusedWidget,
      child: config.child
    );
  }
}
