// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'icon.dart';
import 'icons.dart';
import 'icon_theme.dart';
import 'icon_theme_data.dart';
import 'list.dart';
import 'list_item.dart';
import 'theme.dart';
import 'theme_data.dart';

const Duration _kExpand = const Duration(milliseconds: 200);

class TwoLevelListItem extends StatelessWidget {
  TwoLevelListItem({
    Key key,
    this.leading,
    this.title,
    this.trailing,
    this.onTap,
    this.onLongPress
  }) : super(key: key) {
    assert(title != null);
  }

  final Widget leading;
  final Widget title;
  final Widget trailing;
  final GestureTapCallback onTap;
  final GestureLongPressCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final TwoLevelList parentList = context.ancestorWidgetOfExactType(TwoLevelList);
    assert(parentList != null);

    return new SizedBox(
      height: kListItemExtent[parentList.type],
      child: new ListItem(
        leading: leading,
        title: title,
        trailing: trailing,
        onTap: onTap,
        onLongPress: onLongPress
      )
    );
  }
}

class TwoLevelSublist extends StatefulWidget {
  TwoLevelSublist({ Key key, this.leading, this.title, this.children }) : super(key: key);

  final Widget leading;
  final Widget title;
  final List<Widget> children;

  @override
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

  @override
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
          new IconTheme(
            data: new IconThemeData(color: _iconColor.evaluate(_easeInAnimation)),
            child: new TwoLevelListItem(
              onTap: _handleOnTap,
              leading: config.leading,
              title: new DefaultTextStyle.explicit(
                style: Theme.of(context).textTheme.subhead.copyWith(color: _headerColor.evaluate(_easeInAnimation)),
                child: config.title
              ),
              trailing: new RotationTransition(
                turns: _iconTurns,
                child: new Icon(
                  icon: Icons.expand_more
                )
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

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    _borderColor.end = theme.dividerColor;
    _headerColor
      ..begin = theme.textTheme.subhead.color
      ..end = theme.accentColor;
    _iconColor
      ..begin = theme.unselectedWidgetColor
      ..end = theme.accentColor;

    return new AnimatedBuilder(
        animation: _controller.view,
        builder: buildList
    );
  }
}

class TwoLevelList extends StatelessWidget {
  TwoLevelList({
    Key key,
    this.scrollableKey,
    this.children,
    this.type: MaterialListType.twoLine,
    this.padding
  }) : super(key: key);

  /// The widgets to display in this list.
  ///
  /// Typically [TwoLevelListItem] or [TwoLevelSublist] widgets.
  final List<Widget> children;

  /// The kind of [ListItem] contained in this list.
  final MaterialListType type;

  /// The key to use for the underlying scrollable widget.
  final Key scrollableKey;

  /// The amount of space by which to inset the children inside the viewport.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return new Block(
      padding: padding,
      children: KeyedSubtree.ensureUniqueKeysForList(children),
      scrollableKey: scrollableKey
    );
  }
}
