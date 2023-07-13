// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'constants.dart';
import 'expand_icon.dart';
import 'ink_well.dart';
import 'material_localizations.dart';
import 'mergeable_material.dart';
import 'shadows.dart';
import 'theme.dart';

const double _kPanelHeaderCollapsedHeight = kMinInteractiveDimension;
const EdgeInsets _kPanelHeaderExpandedDefaultPadding = EdgeInsets.symmetric(
  vertical: 64.0 - _kPanelHeaderCollapsedHeight,
);
const EdgeInsets _kExpandIconPadding = EdgeInsets.all(12.0);

class _SaltedKey<S, V> extends LocalKey {
  const _SaltedKey(this.salt, this.value);

  final S salt;
  final V value;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is _SaltedKey<S, V> &&
        other.salt == salt &&
        other.value == value;
  }

  @override
  int get hashCode => Object.hash(runtimeType, salt, value);

  @override
  String toString() {
    final String saltString = S == String ? "<'$salt'>" : '<$salt>';
    final String valueString = V == String ? "<'$value'>" : '<$value>';
    return '[$saltString $valueString]';
  }
}

/// Signature for the callback that's called when an [ExpansionPanel] is
/// expanded or collapsed.
///
/// The position of the panel within an [ExpansionPanelList] is given by
/// [panelIndex].
typedef ExpansionPanelCallback = void Function(int panelIndex, bool isExpanded);

/// Signature for the callback that's called when the header of the
/// [ExpansionPanel] needs to rebuild.
typedef ExpansionPanelHeaderBuilder = Widget Function(
    BuildContext context, bool isExpanded);

/// Signature for the callback that's called when the expansion indicator of the
/// [ExpansionPanel] needs to rebuild.
typedef ExpansionPanelIconBuilder = Widget Function(
  BuildContext context,
  bool isExpanded,
  VoidCallback handlePressed,
  Duration animationDuration,
);

/// A material expansion panel. It has a header and a body and can be either
/// expanded or collapsed. The body of the panel is only visible when it is
/// expanded.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=2aJZzRMziJc}
///
/// Expansion panels are only intended to be used as children for
/// [ExpansionPanelList].
///
/// See [ExpansionPanelList] for a sample implementation.
///
/// See also:
///
///  * [ExpansionPanelList]
///  * <https://material.io/design/components/lists.html#types>
class ExpansionPanel {
  /// Creates an expansion panel to be used as a child for [ExpansionPanelList].
  /// See [ExpansionPanelList] for an example on how to use this widget.
  ///
  /// The [headerBuilder], [body], and [isExpanded] arguments must not be null.
  ExpansionPanel({
    required this.headerBuilder,
    required this.body,
    this.isExpanded = false,
    this.canTapOnHeader = false,
    this.backgroundColor,
    this.expandIconBuilder,
  });

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

  /// Whether tapping on the panel's header will expand/collapse it.
  ///
  /// Defaults to false.
  final bool canTapOnHeader;

  /// Defines the background color of the panel.
  ///
  /// Defaults to [ThemeData.cardColor].
  final Color? backgroundColor;

  /// A callback which builds the expansion panel indicator to show
  /// whether the panel is expanded or not.
  ///
  /// If [expandIconBuilder] is specified, then the widget it returns must
  /// rebuild the panel with a new [isExpanded] value.
  /// [ExpansionPanelList.expansionCallback] should still be used to update
  /// the state correctly. A [VoidCallback] is passed as a parameter to `expandIconBuilder`
  /// to properly trigger [ExpansionPanelList.expansionCallback].
  ///
  /// The `expandIconBuilder` callback also provides [ExpansionPanelList.animationDuration],
  /// which can be used to build custom animation for expansion icon.
  ///
  /// If [expandIconBuilder] is not specified, then [ExpandIcon] is used as
  /// expansion indicator icon.
  ///
  /// When [canTapOnHeader] is set to true, the expansion indicator icon will we
  /// invisible to hit testing. Since the entire header should semantically behave
  /// as a single button, the expansion indicator icon's gesture detection and
  /// semantics are ignored.
  ///
  /// ## Handling Gesture Detection
  ///
  /// Since there are many ways to customize the expanded icons, the gesture
  /// detection has to be properly handled. This makes it necessary to
  /// define a [VoidCallback] that calls [ExpansionPanelList.expansionCallback]
  /// with correct index and isExpanded values.
  ///
  /// {@tool dartpad --template=stateful_widget_scaffold}
  ///
  /// Here is a custom expansion indicator icon that uses a [Checkbox], which
  /// has its own gesture detector. This example assumes that
  /// [ExpansionPanelList.expansionCallback] toggles `_isExpanded`.
  ///
  /// ```dart
  /// bool _isExpanded = false;
  ///
  /// @override
  /// Widget build(BuildContext context) {
  ///   return SingleChildScrollView(
  ///     child: ExpansionPanelList(
  ///       expansionCallback: (int index, bool isExpanded) {
  ///         setState(() {
  ///           _isExpanded = !_isExpanded;
  ///         });
  ///       },
  ///       children: <ExpansionPanel>[
  ///         ExpansionPanel(
  ///           isExpanded: _isExpanded,
  ///           headerBuilder: (BuildContext context, bool isExpanded) {
  ///             return const ListTile(
  ///               title: Text('Header Text'),
  ///             );
  ///           },
  ///           expandIconBuilder: (
  ///             BuildContext context,
  ///             bool isExpanded,
  ///             VoidCallback handlePressed,
  ///             Duration animationDuration,
  ///         ) {
  ///           return Checkbox(
  ///             value: isExpanded,
  ///             onChanged: (bool? value) {
  ///               handlePressed();
  ///             });
  ///           },
  ///           body: const ListTile(
  ///             title: Text('Title Text'),
  ///             subtitle: Text('Subtitle Text'),
  ///           ),
  ///         ),
  ///       ],
  ///     ),
  ///   );
  /// }
  /// ```
  /// {@end-tool}
  ///
  /// {@tool dartpad --template=stateful_widget_scaffold}
  ///
  /// Here is a custom expansion icon that uses two static icons, which requires
  /// gesture detection to be manually handled. In this case, an [InkWell] is
  /// used. This example assumes that [ExpansionPanelList.expansionCallback]
  /// toggles _isExpanded.
  ///
  /// ```dart
  /// bool _isExpanded = false;
  ///
  /// @override
  /// Widget build(BuildContext context) {
  ///   return SingleChildScrollView(
  ///     child: ExpansionPanelList(
  ///       expansionCallback: (int index, bool isExpanded) {
  ///         setState(() {
  ///           _isExpanded = !_isExpanded;
  ///         });
  ///       },
  ///       children: <ExpansionPanel>[
  ///         ExpansionPanel(
  ///           isExpanded: _isExpanded,
  ///           headerBuilder: (BuildContext context, bool isExpanded) {
  ///             return const ListTile(title: Text('Header Text'));
  ///           },
  ///           expandIconBuilder: (
  ///             BuildContext context,
  ///             bool isExpanded,
  ///             VoidCallback handlePressed,
  ///             Duration animationDuration,
  ///           ) {
  ///             return InkWell(
  ///               customBorder: const CircleBorder(),
  ///               onTap: () {
  ///                 handlePressed();
  ///               },
  ///               child: Padding(
  ///                 padding: const EdgeInsets.all(12.0),
  ///                 child: isExpanded
  ///                   ? const Icon(Icons.check_box)
  ///                   : const Icon(Icons.check_box_outline_blank),
  ///               ),
  ///             );
  ///           },
  ///           body: const ListTile(
  ///             title: Text('Title Text'),
  ///             subtitle: Text('Subtitle Text'),
  ///           ),
  ///         ),
  ///       ],
  ///     ),
  ///   );
  /// }
  /// ```
  /// {@end-tool}
  ///
  /// {@tool dartpad --template=stateful_widget_scaffold}
  ///
  /// Here is a custom expansion icon that uses an [AnimatedIcon], which
  /// requires gesture detection to be manually handled. In this case, an
  /// [InkWell] is used. It also can make use of the
  /// [ExpansionPanelList.animationDuration] for its animation. This example
  /// assumes that [ExpansionPanelList.expansionCallback] toggles _isExpanded.
  ///
  /// ```dart preamble
  /// class CustomAnimatedIcon extends StatefulWidget{
  ///   const CustomAnimatedIcon(
  ///     this.isExpanded,
  ///     this.duration,
  ///   );
  ///
  ///   final bool isExpanded;
  ///   final Duration duration;
  ///
  ///   @override
  ///   _CustomAnimatedIconState createState() => _CustomAnimatedIconState();
  /// }
  ///
  /// class _CustomAnimatedIconState extends State<CustomAnimatedIcon> with SingleTickerProviderStateMixin {
  ///   late AnimationController animationController;
  ///
  ///   @override
  ///   void initState() {
  ///     super.initState();
  ///     animationController = AnimationController(
  ///       vsync: this,
  ///       duration: widget.duration,
  ///     );
  ///   }
  ///
  ///   @override
  ///   void didUpdateWidget(CustomAnimatedIcon oldWidget) {
  ///     if (widget.isExpanded != oldWidget.isExpanded) {
  ///       if (widget.isExpanded) {
  ///         animationController.forward();
  ///       } else {
  ///         animationController.reverse();
  ///       }
  ///     }
  ///     super.didUpdateWidget(oldWidget);
  ///   }
  ///
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     return AnimatedIcon(
  ///       icon: AnimatedIcons.menu_close,
  ///       progress: animationController,
  ///     );
  ///   }
  /// }
  /// ```
  ///
  /// ```dart
  /// bool _isExpanded = false;
  ///
  /// @override
  /// Widget build(BuildContext context) {
  ///   return SingleChildScrollView(
  ///     child: ExpansionPanelList(
  ///       expansionCallback: (int index, bool isExpanded) {
  ///         setState(() {
  ///           _isExpanded = !isExpanded;
  ///         });
  ///       },
  ///       children: <ExpansionPanel>[
  ///         ExpansionPanel(
  ///           isExpanded: _isExpanded,
  ///           headerBuilder: (BuildContext context, bool isExpanded) {
  ///             return const ListTile(title: Text('Header Text'));
  ///           },
  ///           expandIconBuilder: (
  ///             BuildContext context,
  ///             bool isExpanded,
  ///             VoidCallback handlePressed,
  ///             Duration animationDuration,
  ///           ) {
  ///             return InkWell(
  ///               customBorder: const CircleBorder(),
  ///               onTap: () {
  ///                 handlePressed();
  ///               },
  ///               child: Padding(
  ///                 padding: const EdgeInsets.all(12.0),
  ///                 child: CustomAnimatedIcon(isExpanded, animationDuration),
  ///               ),
  ///             );
  ///           },
  ///           body: const ListTile(
  ///             title: Text('Title Text'),
  ///             subtitle: Text('Subtitle Text'),
  ///           ),
  ///         ),
  ///       ],
  ///     ),
  ///   );
  /// }
  /// ```
  /// {@end-tool}
  final ExpansionPanelIconBuilder? expandIconBuilder;
}

/// An expansion panel that allows for radio-like functionality.
/// This means that at any given time, at most, one [ExpansionPanelRadio]
/// can remain expanded.
///
/// A unique identifier [value] must be assigned to each panel.
/// This identifier allows the [ExpansionPanelList] to determine
/// which [ExpansionPanelRadio] instance should be expanded.
///
/// See [ExpansionPanelList.radio] for a sample implementation.
class ExpansionPanelRadio extends ExpansionPanel {
  /// An expansion panel that allows for radio functionality.
  ///
  /// A unique [value] must be passed into the constructor. The
  /// [headerBuilder], [body], [value] must not be null.
  ExpansionPanelRadio({
    required this.value,
    required super.headerBuilder,
    required super.body,
    super.canTapOnHeader,
    super.backgroundColor,
    super.expandIconBuilder,
    super.isExpanded,
  });

  /// The value that uniquely identifies a radio panel so that the currently
  /// selected radio panel can be identified.
  final Object value;
}

/// A material expansion panel list that lays out its children and animates
/// expansions.
///
/// The [expansionCallback] is called when the expansion state changes. For
/// normal [ExpansionPanelList] widgets, it is the responsibility of the parent
/// widget to rebuild the [ExpansionPanelList] with updated values for
/// [ExpansionPanel.isExpanded]. For [ExpansionPanelList.radio] widgets, the
/// open state is tracked internally and the callback is invoked both for the
/// previously open panel, which is closing, and the previously closed panel,
/// which is opening.
///
/// {@tool dartpad}
/// Here is a simple example of how to use [ExpansionPanelList].
///
/// ** See code in examples/api/lib/material/expansion_panel/expansion_panel_list.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [ExpansionPanel], which is used in the [children] property.
///  * [ExpansionPanelList.radio], a variant of this widget where only one panel is open at a time.
///  * <https://material.io/design/components/lists.html#types>
class ExpansionPanelList extends StatefulWidget {
  /// Creates an expansion panel list widget. The [expansionCallback] is
  /// triggered when an expansion panel expand/collapse button is pushed.
  ///
  /// The [children] and [animationDuration] arguments must not be null.
  const ExpansionPanelList({
    super.key,
    this.children = const <ExpansionPanel>[],
    this.expansionCallback,
    this.animationDuration = kThemeAnimationDuration,
    this.expandedHeaderPadding = _kPanelHeaderExpandedDefaultPadding,
    this.dividerColor,
    this.elevation = 2,
    this.expandIconColor,
    this.materialGapSize = 16.0,
  })  : _allowOnlyOnePanelOpen = false,
        initialOpenPanelValue = null;

  /// Creates a radio expansion panel list widget.
  ///
  /// This widget allows for at most one panel in the list to be open.
  /// The expansion panel callback is triggered when an expansion panel
  /// expand/collapse button is pushed. The [children] and [animationDuration]
  /// arguments must not be null. The [children] objects must be instances
  /// of [ExpansionPanelRadio].
  ///
  /// {@tool dartpad}
  /// Here is a simple example of how to implement ExpansionPanelList.radio.
  ///
  /// ** See code in examples/api/lib/material/expansion_panel/expansion_panel_list.expansion_panel_list_radio.0.dart **
  /// {@end-tool}
  const ExpansionPanelList.radio({
    super.key,
    this.children = const <ExpansionPanelRadio>[],
    this.expansionCallback,
    this.animationDuration = kThemeAnimationDuration,
    this.initialOpenPanelValue,
    this.expandedHeaderPadding = _kPanelHeaderExpandedDefaultPadding,
    this.dividerColor,
    this.elevation = 2,
    this.expandIconColor,
    this.materialGapSize = 16.0,
  }) : _allowOnlyOnePanelOpen = true;

  /// The children of the expansion panel list. They are laid out in a similar
  /// fashion to [ListBody].
  final List<ExpansionPanel> children;

  /// The callback that gets called whenever one of the expand/collapse buttons
  /// is pressed. The arguments passed to the callback are the index of the
  /// pressed panel and whether the panel is currently expanded or not.
  ///
  /// If [ExpansionPanelList.radio] is used, the callback may be called a
  /// second time if a different panel was previously open. The arguments
  /// passed to the second callback are the index of the panel that will close
  /// and false, marking that it will be closed.
  ///
  /// For [ExpansionPanelList], the callback should call [State.setState] when
  /// it is notified about the closing/opening panel. On the other hand, the
  /// callback for [ExpansionPanelList.radio] is intended to inform the parent
  /// widget of changes, as the radio panels' open/close states are managed
  /// internally.
  ///
  /// This callback is useful in order to keep track of the expanded/collapsed
  /// panels in a parent widget that may need to react to these changes.
  final ExpansionPanelCallback? expansionCallback;

  /// The duration of the expansion animation.
  final Duration animationDuration;

  // Whether multiple panels can be open simultaneously
  final bool _allowOnlyOnePanelOpen;

  /// The value of the panel that initially begins open. (This value is
  /// only used when initializing with the [ExpansionPanelList.radio]
  /// constructor.)
  final Object? initialOpenPanelValue;

  /// The padding that surrounds the panel header when expanded.
  ///
  /// By default, 16px of space is added to the header vertically (above and below)
  /// during expansion.
  final EdgeInsets expandedHeaderPadding;

  /// Defines color for the divider when [ExpansionPanel.isExpanded] is false.
  ///
  /// If [dividerColor] is null, then [DividerThemeData.color] is used. If that
  /// is null, then [ThemeData.dividerColor] is used.
  final Color? dividerColor;

  /// Defines elevation for the [ExpansionPanel] while it's expanded.
  ///
  /// By default, the value of elevation is 2.
  final double elevation;

  /// {@macro flutter.material.ExpandIcon.color}
  final Color? expandIconColor;

  /// Defines the [MaterialGap.size] of the [MaterialGap] which is placed
  /// between the [ExpansionPanelList.children] when they're expanded.
  ///
  /// Defaults to `16.0`.
  final double materialGapSize;

  @override
  State<StatefulWidget> createState() => _ExpansionPanelListState();
}

class _ExpansionPanelListState extends State<ExpansionPanelList> {
  ExpansionPanelRadio? _currentOpenPanel;

  @override
  void initState() {
    super.initState();
    if (widget._allowOnlyOnePanelOpen) {
      assert(_allIdentifiersUnique(),
          'All ExpansionPanelRadio identifier values must be unique.');
      if (widget.initialOpenPanelValue != null) {
        _currentOpenPanel = searchPanelByValue(
            widget.children.cast<ExpansionPanelRadio>(),
            widget.initialOpenPanelValue);
      }
    }
  }

  @override
  void didUpdateWidget(ExpansionPanelList oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget._allowOnlyOnePanelOpen) {
      assert(_allIdentifiersUnique(),
          'All ExpansionPanelRadio identifier values must be unique.');
      // If the previous widget was non-radio ExpansionPanelList, initialize the
      // open panel to widget.initialOpenPanelValue
      if (!oldWidget._allowOnlyOnePanelOpen) {
        _currentOpenPanel = searchPanelByValue(
            widget.children.cast<ExpansionPanelRadio>(),
            widget.initialOpenPanelValue);
      }
    } else {
      _currentOpenPanel = null;
    }
  }

  bool _allIdentifiersUnique() {
    final Map<Object, bool> identifierMap = <Object, bool>{};
    for (final ExpansionPanelRadio child
        in widget.children.cast<ExpansionPanelRadio>()) {
      identifierMap[child.value] = true;
    }
    return identifierMap.length == widget.children.length;
  }

  bool _isChildExpanded(int index) {
    if (widget._allowOnlyOnePanelOpen) {
      final ExpansionPanelRadio radioWidget =
          widget.children[index] as ExpansionPanelRadio;
      return _currentOpenPanel?.value == radioWidget.value;
    }
    return widget.children[index].isExpanded;
  }

  void _handlePressed(bool isExpanded, int index) {
    if (widget._allowOnlyOnePanelOpen) {
      final ExpansionPanelRadio pressedChild =
          widget.children[index] as ExpansionPanelRadio;

      // If another ExpansionPanelRadio was already open, apply its
      // expansionCallback (if any) to false, because it's closing.
      for (int childIndex = 0;
          childIndex < widget.children.length;
          childIndex += 1) {
        final ExpansionPanelRadio child =
            widget.children[childIndex] as ExpansionPanelRadio;
        if (widget.expansionCallback != null &&
            childIndex != index &&
            child.value == _currentOpenPanel?.value) {
          widget.expansionCallback!(childIndex, false);
        }
      }

      setState(() {
        _currentOpenPanel = isExpanded ? null : pressedChild;
      });
    }
    // !isExpanded is passed because, when _handlePressed, the state of the panel to expand is not yet expanded.
    widget.expansionCallback?.call(index, !isExpanded);
  }

  ExpansionPanelRadio? searchPanelByValue(
      List<ExpansionPanelRadio> panels, Object? value) {
    for (final ExpansionPanelRadio panel in panels) {
      if (panel.value == value) {
        return panel;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    assert(
      kElevationToShadow.containsKey(widget.elevation),
      'Invalid value for elevation. See the kElevationToShadow constant for'
      ' possible elevation values.',
    );

    final List<MergeableMaterialItem> items = <MergeableMaterialItem>[];

    for (int index = 0; index < widget.children.length; index += 1) {
      if (_isChildExpanded(index) &&
          index != 0 &&
          !_isChildExpanded(index - 1)) {
        items.add(MaterialGap(
            key: _SaltedKey<BuildContext, int>(context, index * 2 - 1),
            size: widget.materialGapSize));
      }

      final ExpansionPanel child = widget.children[index];
      final Widget headerWidget = child.headerBuilder(
        context,
        _isChildExpanded(index),
      );

      Widget expansionIndicator;
      if (child.expandIconBuilder != null) {
        expansionIndicator = IgnorePointer(
          ignoring: child.canTapOnHeader,
          ignoringSemantics: child.canTapOnHeader,
          child: child.expandIconBuilder!(
            context,
            _isChildExpanded(index),
            () {
              _handlePressed(_isChildExpanded(index), index);
            },
            widget.animationDuration,
          ),
        );
      } else {
        expansionIndicator = ExpandIcon(
          color: widget.expandIconColor,
          isExpanded: _isChildExpanded(index),
          padding: _kExpandIconPadding,
          onPressed: !child.canTapOnHeader
              ? (bool isExpanded) => _handlePressed(isExpanded, index)
              : null,
        );
      }

      Widget expandIconContainer = Container(
        margin: const EdgeInsetsDirectional.only(end: 8.0),
        child: expansionIndicator,
      );
      if (!child.canTapOnHeader) {
        final MaterialLocalizations localizations =
            MaterialLocalizations.of(context);
        final String onTapHint = _isChildExpanded(index)
            ? localizations.expandedIconTapHint
            : localizations.collapsedIconTapHint;
        expandIconContainer = Semantics(
          label: onTapHint,
          onTapHint: child.expandIconBuilder == null ? null : onTapHint,
          container: true,
          child: expandIconContainer,
        );
      }
      Widget header = Row(
        children: <Widget>[
          Expanded(
            child: AnimatedContainer(
              duration: widget.animationDuration,
              curve: Curves.fastOutSlowIn,
              margin: _isChildExpanded(index)
                  ? widget.expandedHeaderPadding
                  : EdgeInsets.zero,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                    minHeight: _kPanelHeaderCollapsedHeight),
                child: headerWidget,
              ),
            ),
          ),
          expandIconContainer,
        ],
      );
      if (child.canTapOnHeader) {
        header = MergeSemantics(
          child: InkWell(
            onTap: () => _handlePressed(_isChildExpanded(index), index),
            child: child.expandIconBuilder != null
                ? Semantics(
                    button: true,
                    enabled: true,
                    child: header,
                  )
                : header,
          ),
        );
      }
      items.add(
        MaterialSlice(
          key: _SaltedKey<BuildContext, int>(context, index * 2),
          color: child.backgroundColor,
          child: Column(
            children: <Widget>[
              header,
              AnimatedCrossFade(
                firstChild: Container(height: 0.0),
                secondChild: child.body,
                firstCurve:
                    const Interval(0.0, 0.6, curve: Curves.fastOutSlowIn),
                secondCurve:
                    const Interval(0.4, 1.0, curve: Curves.fastOutSlowIn),
                sizeCurve: Curves.fastOutSlowIn,
                crossFadeState: _isChildExpanded(index)
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: widget.animationDuration,
              ),
            ],
          ),
        ),
      );

      if (_isChildExpanded(index) && index != widget.children.length - 1) {
        items.add(MaterialGap(
            key: _SaltedKey<BuildContext, int>(context, index * 2 + 1),
            size: widget.materialGapSize));
      }
    }

    return MergeableMaterial(
      hasDividers: true,
      dividerColor: widget.dividerColor,
      elevation: widget.elevation,
      children: items,
    );
  }
}
