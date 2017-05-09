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
/// A stateful widget that builds a [TabBar] or a [TabBarView] can create
/// a TabController and share it directly.
///
/// ```dart
/// class _MyDemoState extends State<MyDemo> with SingleTickerProviderStateMixin {
///   final List<Tab> myTabs = <Tab>[
///     new Tab(text: 'LEFT'),
///     new Tab(text: 'RIGHT'),
///   ];
///
///   TabController _tabController;
///
///   @override
///   void initState() {
///     super.initState();
///     _tabController = new TabController(vsync: this, length: myTabs.length);
///   }
///
///  @override
///  void dispose() {
///    _tabController.dispose();
///    super.dispose();
///  }
///
///   @override
///   Widget build(BuildContext context) {
///     return new Scaffold(
///       appBar: new AppBar(
///         bottom: new TabBar(
///           controller: _tabController,
///           tabs: myTabs,
///         ),
///       ),
///       body: new TabBarView(
///         controller: _tabController,
///         children: myTabs.map((Tab tab) {
///           return new Center(child: new Text(tab.text));
///         }).toList(),
///       ),
///     );
///   }
/// }
/// ```
///
/// When the [TabBar] and [TabBarView] don't have a convenient stateful
/// ancestor, a TabController can be shared with the [DefaultTabController]
/// inherited widget.
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
  Animation<double> get animation => _animationController.view;
  final AnimationController _animationController;

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
      notifyListeners(); // Because the value of indexIsChanging may have changed.
      _animationController
        .animateTo(_index.toDouble(), duration: duration, curve: curve)
        .orCancel.then<Null>(_indexChanged, onError: _indexChanged);
    } else {
      _indexIsChangingCount += 1;
      _animationController.value = _index.toDouble();
      _indexIsChangingCount -= 1;
      notifyListeners();
    }
  }

  Null _indexChanged(dynamic value) {
    _indexIsChangingCount -= 1;
    notifyListeners();
    return null;
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
  const _TabControllerScope({
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
///
/// DefaultTabController is an inherited widget that is used to share a
/// TabController with a [TabBar] or a [TabBarView]. It's used when
/// sharing an explicitly created TabController isn't convenient because
/// the tab bar widgets are created by a stateless parent widget or by
/// different parent widgets.
///
/// ```dart
/// class MyDemo extends StatelessWidget {
///   final List<Tab> myTabs = <Tab>[
///     new Tab(text: 'LEFT'),
///     new Tab(text: 'RIGHT'),
///   ];
///
///   @override
///   Widget build(BuildContext context) {
///     return new DefaultTabController(
///       length: myTabs.length,
///       child: new Scaffold(
///         appBar: new AppBar(
///           bottom: new TabBar(
///             tabs: myTabs,
///           ),
///         ),
///         body: new TabBarView(
///           children: myTabs.map((Tab tab) {
///             return new Center(child: new Text(tab.text));
///           }).toList(),
///         ),
///       ),
///     );
///   }
/// }
/// ```
class DefaultTabController extends StatefulWidget {
  /// Creates a default tab controller for the given [child] widget.
  ///
  /// The [length] argument must be great than one.
  ///
  /// The [initialIndex] argument must not be null.
  const DefaultTabController({
    Key key,
    @required this.length,
    this.initialIndex: 0,
    @required this.child,
  }) : assert(initialIndex != null),
       super(key: key);

  /// The total number of tabs. Must be greater than one.
  final int length;

  /// The initial index of the selected tab.
  ///
  /// Defaults to zero.
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
    final _TabControllerScope scope = context.inheritFromWidgetOfExactType(_TabControllerScope);
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
      length: widget.length,
      initialIndex: widget.initialIndex,
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
      child: widget.child,
    );
  }
}
