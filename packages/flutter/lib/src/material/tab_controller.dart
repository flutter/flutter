// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'constants.dart';

class TabController {
  TabController({ int initialIndex: 0, this.length, TickerProvider vsync })
    : _index = initialIndex,
      _previousIndex = initialIndex,
      _animationController = new AnimationController(
        value: 0.5,
        vsync: vsync
   ) {
    assert(length != null && length > 1);
    assert(initialIndex != null && initialIndex >= 0 && initialIndex < length);
  }

  final AnimationController _animationController;
  Animation<double> get animation => _animationController.view;

  final int length;

  int get previousIndex => _previousIndex;
  int _previousIndex;

  bool _indexIsChanging = false;
  bool get indexIsChanging => _indexIsChanging;

  int get index => _index;
  int _index;

  void animateTo(int value, { Duration duration: kTabScrollDuration, Curve curve: Curves.ease }) {
    assert(value != null);
    assert(value >= 0 && value < length);
    if (value == _index)
      return;
    _indexIsChanging = true;
    _previousIndex = index;
    _index = value;
    _animationController
      ..value = 0.0
      ..animateTo(1.0, duration: duration, curve: curve).then((_) {
        _animationController.value = 0.5;
        _indexIsChanging = false;
      });
  }

  double get offset => 2.0 * _animationController.value - 1.0;
  set offset(double value) {
    assert(value != null);
    assert(value >= -1.0 && value <= 1.0);
    assert(!indexIsChanging);
    if (value == offset)
      return;
    _animationController.value = (value + 1.0) / 2.0;
  }

  void addOnChangedListener(VoidCallback onChanged) {
    _animationController.addStatusListener(new _OnChangedStatusListener(onChanged));
  }

  void removeOnChangedListener(VoidCallback onChanged) {
    _animationController.removeStatusListener(new _OnChangedStatusListener(onChanged));
  }

  void dispose() {
    _animationController.dispose();
  }
}

class _TabControllerScope extends InheritedWidget {
  _TabControllerScope({
    Key key,
    this.controller,
    this.enabled,
    Widget child
  }) : super(key: key, child: child);

  final TabController controller;
  final bool enabled;

  @override
  bool updateShouldNotify(_TabControllerScope old) {
    return enabled != old.enabled || controller != old.controller;
  }
}

class _OnChangedStatusListener extends Function {
  _OnChangedStatusListener(this.onChanged);

  final VoidCallback onChanged;

  void call(AnimationStatus status) {
    if (status == AnimationStatus.completed)
      onChanged();
  }

  @override
  bool operator ==(dynamic other) => onChanged == other;

  @override
  int get hashCode => onChanged.hashCode;
}

class DefaultTabController extends StatefulWidget {
  DefaultTabController({
    Key key,
    @required this.length,
    this.initialIndex: 0,
    this.child
  }) : super(key: key);

  final int length;
  final int initialIndex;
  final Widget child;

  static TabController of(BuildContext context) {
    _TabControllerScope scope = context.inheritFromWidgetOfExactType(_TabControllerScope);
    return scope?.controller;
  }

  @override
  _DefaultTabControllerState createState() => new _DefaultTabControllerState();
}

class _DefaultTabControllerState extends State<DefaultTabController> with SingleTickerProviderStateMixin {
  TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = new TabController(
      vsync: this,
      length: config.length,
      initialIndex: config.initialIndex,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new _TabControllerScope(
      controller: _controller,
      enabled: TickerMode.of(context),
      child: config.child,
    );
  }
}
