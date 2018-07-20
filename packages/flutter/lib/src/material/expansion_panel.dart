// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

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

/// An expansion panel that allows for radio-like functionality.
///
/// This type of panel will automatically handle closing and opening itself,
/// set the [initializesExpanded] value to true on a panel if you want it to begin
/// opened when the expansion panel list is created. A unique identifier [value]
/// must be assigned to each panel.
class ExpansionPanelRadio extends ExpansionPanel {

  /// A subclass of expansion panel that allows for radio functionality.
  ///
  /// A unique identifier [value] must be passed into the constructor. The
  /// [headerBuilder], [body], [value], and [initializesExpanded] arguments must not be null.
  ExpansionPanelRadio({
    this.initializesExpanded = false,
    @required this.value,
    @required ExpansionPanelHeaderBuilder headerBuilder,
    @required Widget body,
  }) : assert(initializesExpanded != null),
        assert(value != null),
        super(body: body, headerBuilder: headerBuilder);

  /// Whether this panel initializes expanded or not.
  final bool initializesExpanded;

  /// Identifier that corresponds to this specific object.
  final int value;
}

/// A material expansion panel list that lays out its children and animates
/// expansions.
///
/// See also:
///
///  * [ExpansionPanel]
///  * <https://material.google.com/components/expansion-panels.html>
class ExpansionPanelList extends StatefulWidget {
  /// Creates an expansion panel list widget. The [expansionCallback] is
  /// triggered when an expansion panel expand/collapse button is pushed.
  ///
  /// The [children] and [animationDuration] arguments must not be null.
  const ExpansionPanelList({
    Key key,
    this.children = const <ExpansionPanel>[],
    this.expansionCallback,
    this.animationDuration = kThemeAnimationDuration,
  }) : assert(children != null),
        assert(animationDuration != null),
        _allowMultiplePanelsOpen = true,
        super(key: key);

  /// Creates a radio expansion panel list widget.
  ///
  /// This widget allows for at most one panel in the list to be open.
  /// The expansion panel callback is triggered when an expansion panel
  /// expand/collapse button is pushed. The [children] and [animationDuration]
  /// arguments must not be null. The [children] objects also must of type
  /// [ExpansionPanelRadio].
  const ExpansionPanelList.radio({
    Key key,
    this.children = const <ExpansionPanelRadio>[],
    this.expansionCallback,
    this.animationDuration = kThemeAnimationDuration,
  }) : assert(children != null),
        assert(animationDuration != null),
        _allowMultiplePanelsOpen = false,
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

  //Whether multiple panels can be open simultaneously
  final bool _allowMultiplePanelsOpen;

  @override
  State<StatefulWidget> createState() => new _ExpansionPanelListState();
}

class _ExpansionPanelListState extends State<ExpansionPanelList> {
  Map<int, bool> _openPanels = <int, bool>{};

  @override
  void initState() {
    super.initState();
    if (!widget._allowMultiplePanelsOpen) {
      for (int i = 0; i < widget.children.length; i += 1) {
        assert(widget.children[i] is ExpansionPanelRadio,
        'All children of ExpansionPanel.radio need to be of type ExpansionPanelRadio');
        final ExpansionPanelRadio _widgetChild = widget.children[i];
        _openPanels[_widgetChild.value] = _widgetChild.initializesExpanded;
      }

      assert(_debugCheckExpandLimit(),
      'This expansion panel widget initialized with more than one panel open');
    }
  }

  @override
  void didUpdateWidget(ExpansionPanelList oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!widget._allowMultiplePanelsOpen) {
      final Map<int, bool> newMap = <int, bool>{};
      for (int i = 0; i < widget.children.length; i += 1) {
        final ExpansionPanelRadio child = widget.children[i];
        final int childKey = child.value;
        newMap[childKey] = _openPanels[childKey] ?? child.initializesExpanded;

        assert(widget.children[i] is ExpansionPanelRadio,
        'All children of ExpansionPanel.radio need to be of type ExpansionPanelRadio');
      }
      _openPanels = newMap;
      assert(_debugCheckExpandLimit(),
      'This expansion panel widget initialized with more than one panel open');
    }
  }

  // Used for initializing the radio type list.
  // Checks whether more than one panel is set to expanded when the radio expansion
  // panel is used.
  bool _debugCheckExpandLimit() {
    int openPanels = 0;
    for (bool value in _openPanels.values) {
      if (value)
        openPanels += 1;
    }
    return openPanels <= 1;
  }

  bool _isChildExpanded(int index) {
    if (!widget._allowMultiplePanelsOpen) {
      final ExpansionPanelRadio radioWidget = widget.children[index];
      return _openPanels[radioWidget.value];
    }
    return widget.children[index].isExpanded;
  }

  void _handlePressed(bool isExpanded, int index) {
    if (widget.expansionCallback != null)
      widget.expansionCallback(index, isExpanded);

    if (!widget._allowMultiplePanelsOpen) {
      final ExpansionPanelRadio pressedChild = widget.children[index];

      for (int childIndex = 0; childIndex < widget.children.length; childIndex += 1) {
        final ExpansionPanelRadio child = widget.children[childIndex];

        if (childIndex != index && !child.isExpanded) {
          if (widget.expansionCallback != null)
            widget.expansionCallback(childIndex, false);
          _openPanels[child.value] = false;
        }
      }
      _openPanels[pressedChild.value] = !isExpanded;
    }
    setState((){});
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

      final ExpansionPanelRadio _widgetChild = widget._allowMultiplePanelsOpen ? null :
      widget.children[index];

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
                  widget._allowMultiplePanelsOpen ? widget.children[index].isExpanded :
                  _openPanels[_widgetChild.value],
                ),
              ),
            ),
          ),
          new Container(
            margin: const EdgeInsetsDirectional.only(end: 8.0),
            child: new ExpandIcon(
              isExpanded: _isChildExpanded(index),
              padding: const EdgeInsets.all(16.0),
              onPressed: (bool isExpanded) => _handlePressed(isExpanded, index),
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
