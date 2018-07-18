// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'expand_icon.dart';
import 'mergeable_material.dart';
import 'theme.dart';

const double _kPanelHeaderCollapsedHeight = 48.0;
const double _kPanelHeaderExpandedHeight = 64.0;

class _SaltedKey<S, V> extends LocalKey {
  const _SaltedKey(this.salt, this.value);

  final S salt;
  final V value;

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType)
      return false;
    final _SaltedKey<S, V> typedOther = other;
    return salt == typedOther.salt
        && value == typedOther.value;
  }

  @override
  int get hashCode => hashValues(runtimeType, salt, value);

  @override
  String toString() {
    final String saltString = S == String ? '<\'$salt\'>' : '<$salt>';
    final String valueString = V == String ? '<\'$value\'>' : '<$value>';
    return '[$saltString $valueString]';
  }
}

/// Signature for the callback that's called when an [ExpansionPanel] is
/// expanded or collapsed.
///
/// The position of the panel within an [ExpansionPanelList] is given by
/// [panelIndex].
typedef void ExpansionPanelCallback(int panelIndex, bool isExpanded);

/// Signature for the callback that's called when the header of the
/// [ExpansionPanel] needs to rebuild.
typedef Widget ExpansionPanelHeaderBuilder(BuildContext context, bool isExpanded);

/// A material expansion panel. It has a header and a body and can be either
/// expanded or collapsed. The body of the panel is only visible when it is
/// expanded.
///
/// Expansion panels are only intended to be used as children for
/// [ExpansionPanelList].
///
/// See also:
///
///  * [ExpansionPanelList]
///  * <https://material.google.com/components/expansion-panels.html>
class ExpansionPanel {
  /// Creates an expansion panel to be used as a child for [ExpansionPanelList].
  ///
  /// The [headerBuilder], [body], and [isExpanded] arguments must not be null.
  ExpansionPanel({
    @required this.headerBuilder,
    @required this.body,
    this.isExpanded = false
  }) : assert(headerBuilder != null),
        assert(body != null),
        assert(isExpanded != null);

  /// The widget builder that builds the expansion panels' header.
  final ExpansionPanelHeaderBuilder headerBuilder;

  /// The body of the expansion panel that's displayed below the header.
  ///
  /// This widget is visible only when the panel is expanded.
  final Widget body;

  /// Whether the panel is expanded.
  ///
  /// Defaults to false.
  final bool isExpanded;
}

/// A material expansion panel list that lays out its children and animates
/// expansions.
///
/// See also:
///
///  * [ExpansionPanel]
///  * <https://material.google.com/components/expansion-panels.html>

class ExpansionPanelList extends StatefulWidget {

  ///Expansion Panel List
  const ExpansionPanelList({
    Key key,
    this.children = const <ExpansionPanel>[],
    this.expansionCallback,
    this.animationDuration = kThemeAnimationDuration,
    this.allowMultiplePanelsOpen = true
  })
      : assert(children != null),
        assert(animationDuration != null),
        super(key: key);

  /// The children of the expansion panel list. They are laid out in a similar
  /// fashion to [ListBody].
  final List<ExpansionPanel> children;

  /// The callback that gets called whenever one of the expand/collapse buttons
  /// is pressed. The arguments passed to the callback are the index of the
  /// to-be-expanded panel in the list and whether the panel is currently
  /// expanded or not.
  ///
  /// This callback is useful in order to keep track of the expanded/collapsed
  /// panels in a parent widget that may need to react to these changes.
  final ExpansionPanelCallback expansionCallback;

  /// The duration of the expansion animation.
  final Duration animationDuration;

  /// Whether the Expansion Panel List can have multiple panels open
  /// simultaneously or at most one.
  ///
  /// If set to false and a closed panel is opened, all other opened panels will
  /// be closed. In this state there can be exactly one or zero panels open.

  final bool allowMultiplePanelsOpen;

  @override
  State<StatefulWidget> createState() => new _ExpansionPanelListState();
}

class _ExpansionPanelListState extends State<ExpansionPanelList> {

  /// Creates an expansion panel list widget. The [expansionCallback] is
  /// triggered when an expansion panel expand/collapse button is pushed.
  List<bool> widgetOpenValue;

  @override
  void initState() {
    super.initState();
    widgetOpenValue = new List<bool>(widget.children.length);

    for(int i = 0; i < widget.children.length; i++)
      widgetOpenValue[i] = false;
  }
  bool _isChildExpanded(int index) {
    return widget.allowMultiplePanelsOpen ? widget.children[index].isExpanded :
    widgetOpenValue[index];
  }

  @override
  Widget build(BuildContext context) {
    final List<MergeableMaterialItem> items = <MergeableMaterialItem>[];


    const EdgeInsets kExpandedEdgeInsets = const EdgeInsets.symmetric(
        vertical: _kPanelHeaderExpandedHeight - _kPanelHeaderCollapsedHeight
    );

    for (int index = 0; index < widget.children.length; index += 1) {
      if (_isChildExpanded(index) && index != 0 && !_isChildExpanded(index - 1))
        items.add(new MaterialGap(key: new _SaltedKey<BuildContext, int>(context, index * 2 - 1)));

      final Row header = new Row(
        children: <Widget>[
          new Expanded(
            child: new AnimatedContainer(
              duration: widget.animationDuration,
              curve: Curves.fastOutSlowIn,
              margin: _isChildExpanded(index) ? kExpandedEdgeInsets : EdgeInsets.zero,
              child: new ConstrainedBox(
                constraints: const BoxConstraints(minHeight: _kPanelHeaderCollapsedHeight),
                child: widget.children[index].headerBuilder(
                  context,
                  widget.allowMultiplePanelsOpen ? widget.children[index].isExpanded :
                  widgetOpenValue[index],
                ),
              ),
            ),
          ),
          new Container(
            margin: const EdgeInsetsDirectional.only(end: 8.0),
            child: new ExpandIcon(
              isExpanded: _isChildExpanded(index),
              padding: const EdgeInsets.all(16.0),
              onPressed: (bool isExpanded) {
                if (widget.expansionCallback != null)
                  widget.expansionCallback(index, isExpanded);

                setState(() {
                  if(!widget.allowMultiplePanelsOpen) {
                    for (int cIndex = 0; cIndex < widget.children.length; cIndex++) {
                      if (cIndex != index && !widget.children[cIndex].isExpanded) {
                        if (widget.expansionCallback != null)
                          widget.expansionCallback(cIndex, false);
                        widgetOpenValue[cIndex] = false;
                      }
                    }
                    widgetOpenValue[index] =!isExpanded;
                  }
                });
              },
            ),
          ),
        ],
      );

      items.add(
        new MaterialSlice(
          key: new _SaltedKey<BuildContext, int>(context, index * 2),
          child: new Column(
            children: <Widget>[
              header,
              new AnimatedCrossFade(
                firstChild: new Container(height: 0.0),
                secondChild: widget.children[index].body,
                firstCurve: const Interval(0.0, 0.6, curve: Curves.fastOutSlowIn),
                secondCurve: const Interval(0.4, 1.0, curve: Curves.fastOutSlowIn),
                sizeCurve: Curves.fastOutSlowIn,
                crossFadeState: _isChildExpanded(index) ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: widget.animationDuration,
              ),
            ],
          ),
        ),
      );

      if (_isChildExpanded(index) && index != widget.children.length - 1)
        items.add(new MaterialGap(key: new _SaltedKey<BuildContext, int>(context, index * 2 + 1)));
    }

    return new MergeableMaterial(
      hasDividers: true,
      children: items,
    );
  }
}
