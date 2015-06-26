// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:sky' as sky;

import 'package:sky/painting/text_style.dart';
import 'package:sky/rendering/box.dart';
import 'package:sky/rendering/object.dart';
import 'package:sky/theme/colors.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/icon.dart';
import 'package:sky/widgets/ink_well.dart';
import 'package:sky/widgets/widget.dart';

typedef void SelectedIndexChanged(int selectedIndex);

const double _kTabHeight = 46.0;
const double _kTabIndicatorHeight = 2.0;
const double _kTabBarHeight = _kTabHeight + _kTabIndicatorHeight;
const double _kMinTabWidth = 72.0;

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

  void setParentData(RenderBox child) {
    if (child.parentData is! TabBarParentData)
      child.parentData = new TabBarParentData();
  }

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    BoxConstraints widthConstraints =
        new BoxConstraints(maxWidth: constraints.maxWidth, maxHeight: constraints.maxHeight);
    double maxWidth = 0.0;
    int childCount = 0;
    RenderBox child = firstChild;
    while (child != null) {
      maxWidth = math.max(maxWidth, child.getMinIntrinsicWidth(widthConstraints));
      ++childCount;
      assert(child.parentData is TabBarParentData);
      child = child.parentData.nextSibling;
    }
    return constraints.constrainWidth(maxWidth * childCount);
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    BoxConstraints widthConstraints =
        new BoxConstraints(maxWidth: constraints.maxWidth, maxHeight: constraints.maxHeight);
    double maxWidth = 0.0;
    int childCount = 0;
    RenderBox child = firstChild;
    while (child != null) {
      maxWidth = math.max(maxWidth, child.getMaxIntrinsicWidth(widthConstraints));
      ++childCount;
      assert(child.parentData is TabBarParentData);
      child = child.parentData.nextSibling;
    }
    return constraints.constrainWidth(maxWidth * childCount);
  }

  double _getIntrinsicHeight(BoxConstraints constraints) => constraints.constrainHeight(_kTabBarHeight);

  double getMinIntrinsicHeight(BoxConstraints constraints) => _getIntrinsicHeight(constraints);

  double getMaxIntrinsicHeight(BoxConstraints constraints) => _getIntrinsicHeight(constraints);

  // TODO(hansmuller): track this value in the parent rather than computing it.
  int _childCount() {
    int childCount = 0;
    RenderBox child = firstChild;
    while (child != null) {
      ++childCount;
      assert(child.parentData is TabBarParentData);
      child = child.parentData.nextSibling;
    }
    return childCount;
  }

  void performLayout() {
    assert(constraints is BoxConstraints);

    size = constraints.constrain(new Size(constraints.maxWidth, _kTabBarHeight));
    assert(!size.isInfinite);

    int childCount = _childCount();
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

  void _paintIndicator(RenderCanvas canvas, RenderBox selectedTab) {
    var size = new Size(selectedTab.size.width, _kTabIndicatorHeight);
    var point = new Point(selectedTab.parentData.position.x, _kTabHeight);
    Rect rect = new Rect.fromPointAndSize(point, size);
    // TODO(hansmuller): indicator color should be based on the theme.
    canvas.drawRect(rect, new Paint()..color = White);
  }

  void paint(RenderCanvas canvas) {
    Rect rect = new Rect.fromSize(size);
    canvas.drawRect(rect, new Paint()..color = Blue[500]);

    int index = 0;
    RenderBox child = firstChild;
    while (child != null) {
      assert(child.parentData is TabBarParentData);
      canvas.paintChild(child, child.parentData.position);
      if (index++ == selectedIndex)
        _paintIndicator(canvas, child);
      child = child.parentData.nextSibling;
    }
  }
}

class TabBarWrapper extends MultiChildRenderObjectWrapper {
  TabBarWrapper(List<Widget> children, this.selectedIndex, { String key })
    : super(key: key, children: children);

  final int selectedIndex;

  RenderTabBar get root => super.root;
  RenderTabBar createNode() => new RenderTabBar();

  void syncRenderObject(Widget old) {
    super.syncRenderObject(old);
    root.selectedIndex = selectedIndex;
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

  // TODO(hansmuller): use themes here.
  static const TextStyle selectedStyle = const TextStyle(color: const Color(0xFFFFFFFF));
  static const TextStyle style = const TextStyle(color: const Color(0xB2FFFFFF));

  Widget _buildLabelText() {
    assert(label.text != null);
    return new Text(label.text, style: style);
  }

  Widget _buildLabelIcon() {
    assert(label.icon != null);
    return new Icon(type: label.icon, size: 24);
  }

  Widget build() {
    Widget labelContents;
    if (label.icon == null) {
      labelContents = _buildLabelText();
    } else if (label.text == null) {
      labelContents = _buildLabelIcon();
    } else {
      labelContents = new Flex(
        <Widget>[_buildLabelText(), _buildLabelIcon()], 
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

  final List<TabLabel> labels;
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
    for (int tabIndex = 0; tabIndex < labels.length; tabIndex++) {
      tabs.add(_toTab(labels[tabIndex], tabIndex));
    }
    return new TabBarWrapper(tabs, selectedIndex);
  }
}


