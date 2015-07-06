// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:sky/rendering/box.dart';
import 'package:sky/rendering/object.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/icon.dart';
import 'package:sky/widgets/ink_well.dart';
import 'package:sky/widgets/theme.dart';
import 'package:sky/widgets/widget.dart';

typedef void SelectedIndexChanged(int selectedIndex);

const double _kTabHeight = 46.0;
const double _kTextAndIconTabHeight = 72.0;
const double _kTabIndicatorHeight = 2.0;
const double _kMinTabWidth = 72.0;
const int _kTabIconSize = 24;

class TabBarParentData extends BoxParentData with
    ContainerParentDataMixin<RenderBox> { }

class RenderTabBar extends RenderBox with
    ContainerRenderObjectMixin<RenderBox, TabBarParentData>,
    RenderBoxContainerDefaultsMixin<RenderBox, TabBarParentData> {

  int _selectedIndex;
  int get selectedIndex => _selectedIndex;
  void set selectedIndex(int value) {
    if (_selectedIndex != value) {
      _selectedIndex = value;
      markNeedsPaint();
    }
  }

  Color _backgroundColor;
  Color get backgroundColor => _backgroundColor;
  void set backgroundColor(Color value) {
    if (_backgroundColor != value) {
      _backgroundColor = value;
      markNeedsPaint();
    }
  }

  Color _indicatorColor;
  Color get indicatorColor => _indicatorColor;
  void set indicatorColor(Color value) {
    if (_indicatorColor != value) {
      _indicatorColor = value;
      markNeedsPaint();
    }
  }

  bool _textAndIcons;
  bool get textAndIcons => _textAndIcons;
  void set textAndIcons(bool value) {
    if (_textAndIcons != value) {
      _textAndIcons = value;
      markNeedsLayout();
    }
  }

  void setupParentData(RenderBox child) {
    if (child.parentData is! TabBarParentData)
      child.parentData = new TabBarParentData();
  }

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    BoxConstraints widthConstraints =
        new BoxConstraints(maxWidth: constraints.maxWidth, maxHeight: constraints.maxHeight);
    double maxWidth = 0.0;
    RenderBox child = firstChild;
    while (child != null) {
      maxWidth = math.max(maxWidth, child.getMinIntrinsicWidth(widthConstraints));
      assert(child.parentData is TabBarParentData);
      child = child.parentData.nextSibling;
    }
    return constraints.constrainWidth(maxWidth * childCount);
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    BoxConstraints widthConstraints =
        new BoxConstraints(maxWidth: constraints.maxWidth, maxHeight: constraints.maxHeight);
    double maxWidth = 0.0;
    RenderBox child = firstChild;
    while (child != null) {
      maxWidth = math.max(maxWidth, child.getMaxIntrinsicWidth(widthConstraints));
      assert(child.parentData is TabBarParentData);
      child = child.parentData.nextSibling;
    }
    return constraints.constrainWidth(maxWidth * childCount);
  }

  double get _tabBarHeight {
    return (textAndIcons ? _kTextAndIconTabHeight : _kTabHeight) + _kTabIndicatorHeight;
  }

  double _getIntrinsicHeight(BoxConstraints constraints) => constraints.constrainHeight(_tabBarHeight);

  double getMinIntrinsicHeight(BoxConstraints constraints) => _getIntrinsicHeight(constraints);

  double getMaxIntrinsicHeight(BoxConstraints constraints) => _getIntrinsicHeight(constraints);

  void performLayout() {
    assert(constraints is BoxConstraints);

    size = constraints.constrain(new Size(constraints.maxWidth, _tabBarHeight));
    assert(!size.isInfinite);

    if (childCount == 0)
      return;

    double tabWidth = size.width / childCount;
    BoxConstraints tabConstraints =
      new BoxConstraints.tightFor(width: tabWidth, height: size.height);
    double x = 0.0;
    RenderBox child = firstChild;
    while (child != null) {
      child.layout(tabConstraints);
      assert(child.parentData is TabBarParentData);
      child.parentData.position = new Point(x, 0.0);
      x += tabWidth;
      child = child.parentData.nextSibling;
    }
  }

  void hitTestChildren(HitTestResult result, { Point position }) {
    defaultHitTestChildren(result, position: position);
  }

  void _paintIndicator(PaintingCanvas canvas, RenderBox selectedTab, Offset offset) {
    if (indicatorColor == null)
      return;

    var size = new Size(selectedTab.size.width, _kTabIndicatorHeight);
    var point = new Point(
      selectedTab.parentData.position.x,
      _tabBarHeight - _kTabIndicatorHeight
    );
    Rect rect = (point + offset) & size;
    canvas.drawRect(rect, new Paint()..color = indicatorColor);
  }

  void paint(PaintingCanvas canvas, Offset offset) {
    if (backgroundColor != null) {
      Rect rect = offset & size;
      canvas.drawRect(rect, new Paint()..color = backgroundColor);
    }

    int index = 0;
    RenderBox child = firstChild;
    while (child != null) {
      assert(child.parentData is TabBarParentData);
      canvas.paintChild(child, child.parentData.position + offset);
      if (index++ == selectedIndex)
        _paintIndicator(canvas, child, offset);
      child = child.parentData.nextSibling;
    }
  }
}

class TabBarWrapper extends MultiChildRenderObjectWrapper {
  TabBarWrapper({
    List<Widget> children,
    this.selectedIndex,
    this.backgroundColor,
    this.indicatorColor,
    this.textAndIcons,
    String key 
  }) : super(key: key, children: children);

  final int selectedIndex;
  final Color backgroundColor;
  final Color indicatorColor;
  final bool textAndIcons; 

  RenderTabBar get root => super.root;
  RenderTabBar createNode() => new RenderTabBar();

  void syncRenderObject(Widget old) {
    super.syncRenderObject(old);
    root.selectedIndex = selectedIndex;
    root.backgroundColor = backgroundColor;
    root.indicatorColor = indicatorColor;
    root.textAndIcons = textAndIcons;
  }
}

class TabLabel {
  const TabLabel({ this.text, this.icon });

  final String text;
  final String icon;
}

class Tab extends Component {
  Tab({
    String key,
    this.label,
    this.selected: false
  }) : super(key: key) {
    assert(label.text != null || label.icon != null);
  }

  final TabLabel label;
  final bool selected;

  Widget _buildLabelText() {
    assert(label.text != null);
    return new Text(label.text, style: Theme.of(this).toolbarText.button);
  }

  Widget _buildLabelIcon() {
    assert(label.icon != null);
    return new Icon(type: label.icon, size: _kTabIconSize);
  }

  Widget build() {
    Widget labelContents;
    if (label.icon == null) {
      labelContents = _buildLabelText();
    } else if (label.text == null) {
      labelContents = _buildLabelIcon();
    } else {
      labelContents = new Flex(
        <Widget>[
          new Container(
            child: _buildLabelIcon(),
            margin: const EdgeDims.only(bottom: 10.0)
          ),
          _buildLabelText()
        ], 
        justifyContent: FlexJustifyContent.center,
        alignItems: FlexAlignItems.center,
        direction: FlexDirection.vertical
      );
    }

    Widget highlightedLabel = new Opacity(
      child: labelContents, 
      opacity: selected ? 1.0 : 0.7
    );

    Container centeredLabel = new Container(
      child: new Center(child: highlightedLabel),
      constraints: new BoxConstraints(minWidth: _kMinTabWidth)
    );

    return new InkWell(child: centeredLabel);
  }
}

class TabBar extends Component {
  TabBar({
    String key,
    this.labels,
    this.selectedIndex: 0,
    this.onChanged
  }) : super(key: key);

  final Iterable<TabLabel> labels;
  final int selectedIndex;
  final SelectedIndexChanged onChanged;

  void _handleTap(int tabIndex) {
    if (tabIndex != selectedIndex && onChanged != null)
      onChanged(tabIndex);
  }

  Widget _toTab(TabLabel label, int tabIndex) {
    Tab tab = new Tab(
      label: label,
      selected: tabIndex == selectedIndex,
      key: label.text == null ? label.icon : label.text
    );
    return new Listener(
      child: tab,
      onGestureTap: (_) => _handleTap(tabIndex)
    );
  }

  Widget build() {
    assert(labels != null && labels.isNotEmpty);
    List<Widget> tabs = <Widget>[];
    bool textAndIcons = false;
    int tabIndex = 0;
    for (TabLabel label in labels) {
      tabs.add(_toTab(label, tabIndex++));
      if (label.text != null && label.icon != null)
        textAndIcons = true;
    }
    return new TabBarWrapper(
      children: tabs, 
      selectedIndex: selectedIndex,
      backgroundColor: Theme.of(this).primaryColor,
      indicatorColor: Theme.of(this).accentColor,
      textAndIcons: textAndIcons
    );
  }
}

class TabNavigatorView {
  TabNavigatorView({ this.label, this.builder });

  final TabLabel label;
  final Builder builder;

  Widget buildContent() {
    assert(builder != null);
    Widget content = builder();
    assert(content != null);
    return content;
  }
}

class TabNavigator extends Component {
  TabNavigator({
    String key,
    this.views,
    this.selectedIndex: 0,
    this.onChanged
  }) : super(key: key);

  final List<TabNavigatorView> views;
  final int selectedIndex;
  final SelectedIndexChanged onChanged;

  void _handleSelectedIndexChanged(int tabIndex) {
    if (onChanged != null)
      onChanged(tabIndex);
  }

  Widget build() {
    assert(views != null && views.isNotEmpty);
    assert(selectedIndex >= 0 && selectedIndex < views.length);

    TabBar tabBar = new TabBar(
      labels: views.map((view) => view.label),
      onChanged: _handleSelectedIndexChanged,
      selectedIndex: selectedIndex
    );

    Widget content = views[selectedIndex].buildContent();
    return new Flex([tabBar, new Flexible(child: content)],
      direction: FlexDirection.vertical
    );
  }
}
