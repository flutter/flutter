// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/widgets/framework.dart';

typedef void FocusChanged(GlobalKey key);

// _noFocusedScope is used by Focus to track the case where none of the Focus
// component's subscopes (e.g. dialogs) are focused. This is distinct from the
// focused scope being null, which means that we haven't yet decided which scope
// is focused and whichever is the first scope to ask for focus will get it.
final GlobalKey _noFocusedScope = new GlobalKey();

class _FocusScope extends Inherited {

  _FocusScope({
    Key key,
    this.scopeFocused: true, // are we focused in our ancestor scope?
    this.focusedScope, // which of our descendant scopes is focused, if any?
    this.focusedWidget,
    Widget child
  }) : super(key: key, child: child);

  final bool scopeFocused;

  // These are mutable because we implicitly changed them when they're null in
  // certain cases, basically pretending retroactively that we were constructed
  // with the right keys.
  GlobalKey focusedScope;
  GlobalKey focusedWidget;

  // The ...IfUnset() methods don't need to notify descendants because by
  // definition they are only going to make a change the very first time that
  // our state is checked.

  void _setFocusedWidgetIfUnset(GlobalKey key) {
    assert(parent is Focus);
    (parent as Focus)._setFocusedWidgetIfUnset(key); // TODO(ianh): remove cast once analyzer is cleverer
    focusedWidget = (parent as Focus)._focusedWidget;
    focusedScope = (parent as Focus)._focusedScope == _noFocusedScope ? null : (parent as Focus)._focusedScope;
  }

  void _setFocusedScopeIfUnset(GlobalKey key) {
    assert(parent is Focus);
    (parent as Focus)._setFocusedScopeIfUnset(key); // TODO(ianh): remove cast once analyzer is cleverer
    assert(focusedWidget == (parent as Focus)._focusedWidget);
    focusedScope = (parent as Focus)._focusedScope == _noFocusedScope ? null : (parent as Focus)._focusedScope;
  }

  bool syncShouldNotify(_FocusScope old) {
    assert(parent is Focus);
    if (scopeFocused != old.scopeFocused)
      return true;
    if (!scopeFocused)
      return false;
    if (focusedScope != old.focusedScope)
      return true;
    if (focusedScope != null)
      return false;
    if (focusedWidget != old.focusedWidget)
      return true;
    return false;
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

  bool autofocus;
  Widget child;

  void syncFields(Focus source) {
    autofocus = source.autofocus;
    child = source.child;
  }


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

  void _widgetRemoved(GlobalKey key) {
    assert(_focusedWidget == key);
    _currentlyRegisteredWidgetRemovalListenerKey = null;
    setState(() {
      _focusedWidget = null;
    });
  }

  void _updateWidgetRemovalListener(GlobalKey key) {
    if (_currentlyRegisteredWidgetRemovalListenerKey != key) {
      if (_currentlyRegisteredWidgetRemovalListenerKey != null)
        GlobalKey.unregisterRemovalListener(_currentlyRegisteredWidgetRemovalListenerKey, _widgetRemoved);
      if (key != null)
        GlobalKey.registerRemovalListener(key, _widgetRemoved);
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
    _currentlyRegisteredScopeRemovalListenerKey = null;
    setState(() {
      _focusedScope = null;
    });
  }

  void _updateScopeRemovalListener(GlobalKey key) {
    if (_currentlyRegisteredScopeRemovalListenerKey != key) {
      if (_currentlyRegisteredScopeRemovalListenerKey != null)
        GlobalKey.unregisterRemovalListener(_currentlyRegisteredScopeRemovalListenerKey, _scopeRemoved);
      if (key != null)
        GlobalKey.registerRemovalListener(key, _scopeRemoved);
      _currentlyRegisteredScopeRemovalListenerKey = key;
    }
  }


  bool _didAutoFocus = false;
  void didMount() {
    if (autofocus && !_didAutoFocus) {
      _didAutoFocus = true;
      Focus._moveScopeTo(this);
    }
    _updateWidgetRemovalListener(_focusedWidget);
    _updateScopeRemovalListener(_focusedScope);
    super.didMount();
  }

  void didUnmount() {
    _updateWidgetRemovalListener(null);
    _updateScopeRemovalListener(null);
    super.didUnmount();
  }

  Widget build() {
    return new _FocusScope(
      scopeFocused: Focus._atScope(this),
      focusedScope: _focusedScope == _noFocusedScope ? null : _focusedScope,
      focusedWidget: _focusedWidget,
      child: child
    );
  }

  static bool at(Component component, { bool autofocus: true }) {
    assert(component != null);
    assert(component.key is GlobalKey);
    _FocusScope focusScope = component.inheritedOfType(_FocusScope);
    if (focusScope != null) {
      if (autofocus)
        focusScope._setFocusedWidgetIfUnset(component.key);
      return focusScope.scopeFocused &&
             focusScope.focusedScope == null &&
             focusScope.focusedWidget == component.key;
    }
    return true;
  }

  static bool _atScope(Focus component, { bool autofocus: true }) {
    assert(component != null);
    _FocusScope focusScope = component.inheritedOfType(_FocusScope);
    if (focusScope != null) {
      if (autofocus)
        focusScope._setFocusedScopeIfUnset(component.key);
      assert(component.key != null);
      return focusScope.scopeFocused &&
             focusScope.focusedScope == component.key;
    }
    return true;
  }

  // Don't call moveTo() from your build() function, it's intended to be called
  // from event listeners, e.g. in response to a finger tap or tab key.

  static void moveTo(Component component) {
    assert(component != null);
    assert(component.key is GlobalKey);
    _FocusScope focusScope = component.inheritedOfType(_FocusScope);
    if (focusScope != null) {
      assert(focusScope.parent is Focus);
      (focusScope.parent as Focus)._setFocusedWidget(component.key); // TODO(ianh): remove cast once analyzer is cleverer
    }
  }

  static void _moveScopeTo(Focus component) {
    assert(component != null);
    assert(component.key != null);
    _FocusScope focusScope = component.inheritedOfType(_FocusScope);
    if (focusScope != null) {
      assert(focusScope.parent is Focus);
      (focusScope.parent as Focus)._setFocusedScope(component.key); // TODO(ianh): remove cast once analyzer is cleverer
    }
  }

  String toStringName() {
    return '${super.toStringName()}(focusedScope=$_focusedScope; focusedWidget=$_focusedWidget)';
  }

}
