// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'icons.dart';
import 'list_tile.dart';
import 'theme.dart';
import 'theme_data.dart';

/// This enum is deprecated. Please use [ListTileTheme] instead.
enum MaterialListType {
  /// A list tile that contains a single line of text.
  oneLine,

  /// A list tile that contains a [CircleAvatar] followed by a single line of text.
  oneLineWithAvatar,

  /// A list tile that contains two lines of text.
  twoLine,

  /// A list tile that contains three lines of text.
  threeLine,
}

/// This constant is deprecated. The [ListTile] class sizes itself based on
/// its content and [ListTileTheme].
@deprecated
Map<MaterialListType, double> kListTileExtent = const <MaterialListType, double>{
  MaterialListType.oneLine: 48.0,
  MaterialListType.oneLineWithAvatar: 56.0,
  MaterialListType.twoLine: 72.0,
  MaterialListType.threeLine: 88.0,
};

const Duration _kExpand = Duration(milliseconds: 200);

/// This class is deprecated. Please use [ListTile] instead.
@deprecated
class TwoLevelListItem extends StatelessWidget {
  /// Creates an item in a two-level list.
  const TwoLevelListItem({
    Key key,
    this.leading,
    @required this.title,
    this.trailing,
    this.enabled = true,
    this.onTap,
    this.onLongPress
  }) : assert(title != null),
       super(key: key);

  /// A widget to display before the title.
  ///
  /// Typically a [CircleAvatar] widget.
  final Widget leading;

  /// The primary content of the list item.
  ///
  /// Typically a [Text] widget.
  final Widget title;

  /// A widget to display after the title.
  ///
  /// Typically an [Icon] widget.
  final Widget trailing;

  /// Whether this list item is interactive.
  ///
  /// If false, this list item is styled with the disabled color from the
  /// current [Theme] and the [onTap] and [onLongPress] callbacks are
  /// inoperative.
  final bool enabled;

  /// Called when the user taps this list item.
  ///
  /// Inoperative if [enabled] is false.
  final GestureTapCallback onTap;

  /// Called when the user long-presses on this list item.
  ///
  /// Inoperative if [enabled] is false.
  final GestureLongPressCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final TwoLevelList parentList = context.ancestorWidgetOfExactType(TwoLevelList);
    assert(parentList != null);

    return SizedBox(
      height: kListTileExtent[parentList.type],
      child: ListTile(
        leading: leading,
        title: title,
        trailing: trailing,
        enabled: enabled,
        onTap: onTap,
        onLongPress: onLongPress
      )
    );
  }
}

/// This class is deprecated. Please use [ExpansionTile] instead.
@deprecated
class TwoLevelSublist extends StatefulWidget {
  /// Creates an item in a two-level list that can expand and collapse.
  const TwoLevelSublist({
    Key key,
    this.leading,
    @required this.title,
    this.backgroundColor,
    this.onOpenChanged,
    this.children = const <Widget>[],
  }) : super(key: key);

  /// A widget to display before the title.
  ///
  /// Typically a [CircleAvatar] widget.
  final Widget leading;

  /// The primary content of the list item.
  ///
  /// Typically a [Text] widget.
  final Widget title;

  /// Called when the sublist expands or collapses.
  ///
  /// When the sublist starts expanding, this function is called with the value
  /// true. When the sublist starts collapsing, this function is called with
  /// the value false.
  final ValueChanged<bool> onOpenChanged;

  /// The widgets that are displayed when the sublist expands.
  ///
  /// Typically [TwoLevelListItem] widgets.
  final List<Widget> children;

  /// The color to display behind the sublist when expanded.
  final Color backgroundColor;

  @override
  _TwoLevelSublistState createState() => _TwoLevelSublistState();
}

@deprecated
class _TwoLevelSublistState extends State<TwoLevelSublist> with SingleTickerProviderStateMixin {
  AnimationController _controller;
  CurvedAnimation _easeOutAnimation;
  CurvedAnimation _easeInAnimation;
  ColorTween _borderColor;
  ColorTween _headerColor;
  ColorTween _iconColor;
  ColorTween _backgroundColor;
  Animation<double> _iconTurns;

  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: _kExpand, vsync: this);
    _easeOutAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _easeInAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _borderColor = ColorTween(begin: Colors.transparent);
    _headerColor = ColorTween();
    _iconColor = ColorTween();
    _iconTurns = Tween<double>(begin: 0.0, end: 0.5).animate(_easeInAnimation);
    _backgroundColor = ColorTween();

    _isExpanded = PageStorage.of(context)?.readState(context) ?? false;
    if (_isExpanded)
      _controller.value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
    if (widget.onOpenChanged != null)
      widget.onOpenChanged(_isExpanded);
  }

  Widget buildList(BuildContext context, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: _backgroundColor.evaluate(_easeOutAnimation),
        border: Border(
          top: BorderSide(color: _borderColor.evaluate(_easeOutAnimation)),
          bottom: BorderSide(color: _borderColor.evaluate(_easeOutAnimation))
        )
      ),
      child: Column(
        children: <Widget>[
          IconTheme.merge(
            data: IconThemeData(color: _iconColor.evaluate(_easeInAnimation)),
            child: TwoLevelListItem(
              onTap: _handleOnTap,
              leading: widget.leading,
              title: DefaultTextStyle(
                style: Theme.of(context).textTheme.subhead.copyWith(color: _headerColor.evaluate(_easeInAnimation)),
                child: widget.title
              ),
              trailing: RotationTransition(
                turns: _iconTurns,
                child: const Icon(Icons.expand_more)
              )
            )
          ),
          ClipRect(
            child: Align(
              heightFactor: _easeInAnimation.value,
              child: Column(children: widget.children)
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
    _backgroundColor
      ..begin = Colors.transparent
      ..end = widget.backgroundColor ?? Colors.transparent;

    return AnimatedBuilder(
      animation: _controller.view,
      builder: buildList
    );
  }
}

/// This class is deprecated. Please use [ListView] and [ListTileTheme] instead.
@deprecated
class TwoLevelList extends StatelessWidget {
  /// Creates a scrollable list of items that can expand and collapse.
  ///
  /// The [type] argument must not be null.
  const TwoLevelList({
    Key key,
    this.children = const <Widget>[],
    this.type = MaterialListType.twoLine,
    this.padding,
  }) : assert(type != null),
       super(key: key);

  /// The widgets to display in this list.
  ///
  /// Typically [TwoLevelListItem] or [TwoLevelSublist] widgets.
  final List<Widget> children;

  /// The kind of [ListTile] contained in this list.
  final MaterialListType type;

  /// The amount of space by which to inset the children inside the viewport.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: padding,
      shrinkWrap: true,
      children: KeyedSubtree.ensureUniqueKeysForList(children),
    );
  }
}
