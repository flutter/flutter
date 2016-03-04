// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'icon.dart';
import 'icons.dart';
import 'list.dart';
import 'list_item.dart';
import 'theme.dart';
import 'theme_data.dart';

const Duration _kExpand = const Duration(milliseconds: 200);

class TwoLevelListItem extends StatelessComponent {
  TwoLevelListItem({
    Key key,
    this.left,
    this.center,
    this.right,
    this.onTap,
    this.onLongPress
  }) : super(key: key) {
    assert(center != null);
  }

  final Widget left;
  final Widget center;
  final Widget right;
  final GestureTapCallback onTap;
  final GestureLongPressCallback onLongPress;

  Widget build(BuildContext context) {
    final TwoLevelList parentList = context.ancestorWidgetOfExactType(TwoLevelList);
    assert(parentList != null);

    return new SizedBox(
      height: kListItemExtent[parentList.type],
      child: new ListItem(
        left: left,
        primary: center,
        right: right,
        onTap: onTap,
        onLongPress: onLongPress
      )
    );
  }
}

class TwoLevelSublist extends StatefulComponent {
  TwoLevelSublist({ Key key, this.left, this.center, this.children }) : super(key: key);

  final Widget left;
  final Widget center;
  final List<Widget> children;

  _TwoLevelSublistState createState() => new _TwoLevelSublistState();
}

class _TwoLevelSublistState extends State<TwoLevelSublist> {
  AnimationController _controller;
  CurvedAnimation _easeOutAnimation;
  CurvedAnimation _easeInAnimation;
  ColorTween _borderColor;
  ColorTween _headerColor;
  ColorTween _iconColor;
  Animation<double> _iconTurns;

  bool _isExpanded = false;

  void initState() {
    super.initState();
    _controller = new AnimationController(duration: _kExpand);
    _easeOutAnimation = new CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _easeInAnimation = new CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _borderColor = new ColorTween(begin: Colors.transparent);
    _headerColor = new ColorTween();
    _iconColor = new ColorTween();
    _iconTurns = new Tween<double>(begin: 0.0, end: 0.5).animate(_easeInAnimation);

    _isExpanded = PageStorage.of(context)?.readState(context) ?? false;
    if (_isExpanded)
      _controller.value = 1.0;
  }

  void _handleOnTap() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded)
        _controller.forward();
      else
        _controller.reverse();
      PageStorage.of(context)?.writeState(context, _isExpanded);
    });
  }

  Widget buildList(BuildContext context, Widget child) {
    return new Container(
      decoration: new BoxDecoration(
        border: new Border(
          top: new BorderSide(color: _borderColor.evaluate(_easeOutAnimation)),
          bottom: new BorderSide(color: _borderColor.evaluate(_easeOutAnimation))
        )
      ),
      child: new Column(
        children: <Widget>[
          new TwoLevelListItem(
            onTap: _handleOnTap,
            left: config.left,
            center: new DefaultTextStyle(
              style: Theme.of(context).text.subhead.copyWith(color: _headerColor.evaluate(_easeInAnimation)),
              child: config.center
            ),
            right: new RotationTransition(
              turns: _iconTurns,
              child: new Icon(
                icon: Icons.expand_more,
                color: _iconColor.evaluate(_easeInAnimation)
              )
            )
          ),
          new ClipRect(
            child: new Align(
              heightFactor: _easeInAnimation.value,
              child: new Column(children: config.children)
            )
          )
        ]
      )
    );
  }

  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    _borderColor.end = theme.dividerColor;
    _headerColor
      ..begin = theme.text.subhead.color
      ..end = theme.accentColor;
    _iconColor
      ..begin = theme.unselectedColor
      ..end = theme.accentColor;

    return new AnimatedBuilder(
        animation: _controller.view,
        builder: buildList
    );
  }
}

class TwoLevelList extends StatelessComponent {
  TwoLevelList({ Key key, this.items, this.type: MaterialListType.twoLine }) : super(key: key);

  final List<Widget> items;
  final MaterialListType type;

  Widget build(BuildContext context) => new Block(children: items);
}
