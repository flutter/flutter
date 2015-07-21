// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/widgets/widget.dart';

class Focus extends Inherited {

  // TODO(ianh): This doesn't yet support nested scopes. We should not
  // be telling our _currentlyFocusedKey that they are focused if we
  // ourselves are not focused. Otherwise if you have a dialog with a
  // text field over the top of a pane with a text field, they'll
  // fight over control of the keyboard.

  Focus({
    GlobalKey key,
    GlobalKey defaultFocus,
    Widget child
  }) : super(key: key, child: child);

  GlobalKey defaultFocus;

  GlobalKey _currentlyFocusedKey;
  GlobalKey get currentlyFocusedKey {
    if (_currentlyFocusedKey != null)
      return _currentlyFocusedKey;
    return defaultFocus;
  }
  void set currentlyFocusedKey(GlobalKey value) {
    if (value != _currentlyFocusedKey) {
      _currentlyFocusedKey = value;
      notifyDescendants();
    }
  }

  void syncState(Focus old) {
    _currentlyFocusedKey = old._currentlyFocusedKey;
    super.syncState(old);
  }  

  static bool at(Component component) {
    assert(component != null);
    assert(component.key is GlobalKey);
    Focus focus = component.inheritedOfType(Focus);
    return focus == null || focus.currentlyFocusedKey == component.key;
  }

  static void moveTo(Component component) {
    assert(component != null);
    assert(component.key is GlobalKey);
    Focus focus = component.inheritedOfType(Focus);
    if (focus != null)
      focus.currentlyFocusedKey = component.key;
  }

}
