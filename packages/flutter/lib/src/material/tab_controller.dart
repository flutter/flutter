// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'constants.dart';

/// Coordinates tab selection between a [TabBar] and a [TabBarView].
///
/// The [index] property is the index of the selected tab and the [animation]
/// represents the current scroll positions of the tab bar and the tar bar view.
/// The selected tab's index can be changed with [animateTo].
///
/// See also:
///
/// * [DefaultTabController], which simplifies sharing a TabController with
///   its [TabBar] and a [TabBarView] descendants.
class TabController extends ChangeNotifier {
  /// Creates an object that manages the state required by [TabBar] and a [TabBarView].
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
  }

  /// An animation whose value represents the current position of the [TabBar]'s
  /// selected tab indicator as well as the scrollOffsets of the [TabBar]
  /// and [TabBarView].
  ///
  /// The animation's value ranges from 0.0 to [length] - 1.0. After the
  /// selected tab is changed, the animation's value equals [index]. The
  /// animation's value can be [offset] by +/- 1.0 to reflect [TabBarView]
  /// drag scrolling.
  final AnimationController _animationController;
  Animation<double> get animation => _animationController.view;

  /// The total number of tabs. Must be greater than one.
  final int length;

  void _changeIndex(int value, { Duration duration, Curve curve }) {
    assert(value != null);
    assert(value >= 0 && value < length);
    assert(duration == null ? curve == null : true);
    assert(_indexIsChangingCount >= 0);
    if (value == _index)
      return;
    _previousIndex = index;
    _index = value;
    if (duration != null) {
      _indexIsChangingCount += 1;
      _animationController
        ..animateTo(_index.toDouble(), duration: duration, curve: curve).whenComplete(() {
          _indexIsChangingCount -= 1;
          notifyListeners();
        });
    } else {
      _indexIsChangingCount += 1;
      _animationController.value = _index.toDouble();
      _indexIsChangingCount -= 1;
      notifyListeners();
    }
  }

  /// The index of the currently selected tab. Changing the index also updates
  /// [previousIndex], sets the [animation]'s value to index, resets
  /// [indexIsChanging] to false, and notifies listeners.
  ///
  /// To change the currently selected tab and play the [animation] use [animateTo].
  int get index => _index;
  int _index;
  set index(int value) {
    _changeIndex(value);
  }

  /// The index of the previously selected tab. Initially the same as [index].
  int get previousIndex => _previousIndex;
  int _previousIndex;

  /// True while we're animating from [previousIndex] to [index].
  bool get indexIsChanging => _indexIsChangingCount != 0;
  int _indexIsChangingCount = 0;

  /// Immediately sets [index] and [previousIndex] and then plays the
  /// [animation] from its current value to [index].
  ///
  /// While the animation is running [indexIsChanging] is true. When the
  /// animation completes [offset] will be 0.0.
  void animateTo(int value, { Duration duration: kTabScrollDuration, Curve curve: Curves.ease }) {
    _changeIndex(value, duration: duration, curve: curve);
  }

  /// The difference between the [animation]'s value and [index]. The offset
  /// value must be between -1.0 and 1.0.
  ///
  /// This property is typically set by the [TabBarView] when the user
  /// drags left or right. A value between -1.0 and 0.0 implies that the
  /// TabBarView has been dragged to the left. Similarly a value between
  /// 0.0 and 1.0 implies that the TabBarView has been dragged to the right.
  double get offset => _animationController.value - _index.toDouble();
  set offset(double newOffset) {
    assert(newOffset != null);
    assert(newOffset >= -1.0 && newOffset <= 1.0);
    assert(!indexIsChanging);
    if (newOffset == offset)
      return;
    _animationController.value = newOffset + _index.toDouble();
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

/// The [TabController] for descendant widgets that don't specify one explicitly.
class DefaultTabController extends StatefulWidget {
  DefaultTabController({
    Key key,
    @required this.length,
    this.initialIndex: 0,
    @required this.child,
  }) : super(key: key);

  /// The total number of tabs. Must be greater than one.
  final int length;

  /// The initial index of the selected tab.
  final int initialIndex;

  /// This widget's child. Often a [Scaffold] whose [AppBar] includes a [TabBar].
  final Widget child;

  /// The closest instance of this class that encloses the given context.
  ///
  /// Typical usage:
  ///
  /// ```dart
  /// TabController controller = DefaultTabBarController.of(context);
  /// ```
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
