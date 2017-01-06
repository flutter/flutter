// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'constants.dart';

/// Coordinates the tab selection between a [TabBar] and a [TabBarView].
///
/// The [index] property is the index of the selected tab and the [animation]
/// represents the current scroll positions of the tab bar and the tar bar view.
/// The selected tab's index can be changed with [animateTo].
///
/// See also:
///
/// * [DefaultTabController], which simplifies sharing a TabController with
/// its [TabBar] and a [TabBarView] descendants.
class TabController extends ChangeNotifier {
  TabController({ int initialIndex: 0, @required this.length, @required TickerProvider vsync })
    : _index = initialIndex,
      _previousIndex = initialIndex,
      _animationController = new AnimationController(
        value: initialIndex.toDouble(),
        upperBound: (length - 1).toDouble(),
        vsync: vsync
   ) {
    assert(length != null && length > 1);
    assert(initialIndex != null && initialIndex >= 0 && initialIndex < length);
    _animationController.addStatusListener(_statusListener);
  }

  void _statusListener(AnimationStatus status) {
    if (status == AnimationStatus.completed)
      notifyListeners();
  }

  /// An animation whose value represents the current position of the
  /// selected tab indicator. The animation's value ranges from 0.0
  /// to [length] - 1.0.
  final AnimationController _animationController;
  Animation<double> get animation => _animationController.view;

  /// The total number of tabs. Must be at least two.
  final int length;

  /// The index of the currently selected tab. Change the currently selected
  /// tab with [animateTo].
  int get index => _index;
  int _index;

  /// The index of the previously selected tab, initially the same as [index].
  int get previousIndex => _previousIndex;
  int _previousIndex;

  /// True if we're animating from [previousIndex] to [index].
  bool get indexIsChanging => _indexIsChanging;
  bool _indexIsChanging = false;

  /// Immediately sets [index] and [previousIndex] and then plays the
  /// [animation] from its current value to [index].
  ///
  /// While the animation is running [indexIsChanging] is true. When the
  /// animation completes [offset] will be 0.0.
  void animateTo(int value, { Duration duration: kTabScrollDuration, Curve curve: Curves.ease }) {
    assert(value != null);
    assert(value >= 0 && value < length);
    if (value == _index)
      return;
    _indexIsChanging = true;
    _previousIndex = index;
    _index = value;
    _animationController
      ..animateTo(_index.toDouble(), duration: duration, curve: curve).then((_) {
        _indexIsChanging = false;
      });
  }

  /// The difference between the [animation]'s value and [index]. The [value]
  /// must be between -1.0 and 1.0.
  ///
  /// This property is typically set by the [TabBarView] when the user
  /// drags left or right. A value between -1.0 and 0.0 implies that the
  /// TabBarView has been dragged to the left. Similarly a value between
  /// 0.0 and 1.0 implies that the TabBarView has been dragged to the right.
  double get offset => _animationController.value - _index.toDouble();
  set offset(double value) {
    assert(value != null);
    assert(value >= -1.0 && value <= 1.0);
    assert(!indexIsChanging);
    if (value == offset)
      return;
    _animationController.value = value + _index.toDouble();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
