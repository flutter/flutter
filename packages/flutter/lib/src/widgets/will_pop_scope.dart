// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'framework.dart';
import 'routes.dart';

/// Registers a callback to veto attempts by the user to dismiss the enclosing
/// [ModalRoute].
///
/// See also:
///
///  * [ModalRoute.addScopedWillPopCallback] and [ModalScope.removeScopedWillPopCallback],
///    which this widget uses to register and unregister [onWillPop].
class WillPopScope extends StatefulWidget {
  /// Creates a widget that registers a callback to veto attempts by the user to
  /// dismiss the enclosing [ModalRoute].
  ///
  /// The [child] argument must not be null.
  WillPopScope({
    Key key,
    @required this.child,
    @required this.onWillPop,
  }) : super(key: key) {
    assert(child != null);
  }

  /// The widget below this widget in the tree.
  final Widget child;

  /// Called to veto attempts by the user to dismiss the enclosing [ModalRoute].
  ///
  /// If the callback returns a Future that resolves to false, the enclosing
  /// route will not be popped.
  WillPopCallback onWillPop;

  @override
  _WillPopScopeState createState() => new _WillPopScopeState();
}

class _WillPopScopeState extends State<WillPopScope> {
  ModalRoute<dynamic> _route;

  @override
  void dependenciesChanged() {
    super.dependenciesChanged();
    if (config.onWillPop != null)
      _route?.removeScopedWillPopCallback(config.onWillPop);
    _route = ModalRoute.of(context);
    if (config.onWillPop != null)
      _route?.addScopedWillPopCallback(config.onWillPop);
  }

  @override
  void didUpdateConfig(WillPopScope oldConfig) {
    assert(_route == ModalRoute.of(context));
    if (config.onWillPop != oldConfig.onWillPop && _route != null) {
      if (oldConfig.onWillPop != null)
        _route.removeScopedWillPopCallback(oldConfig.onWillPop);
      if (config.onWillPop != null)
        _route.addScopedWillPopCallback(config.onWillPop);
    }
  }

  @override
  void dispose() {
    if (config.onWillPop != null)
      _route?.removeScopedWillPopCallback(config.onWillPop);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => config.child;
}
