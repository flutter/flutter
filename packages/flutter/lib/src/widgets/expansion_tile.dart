// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'actions.dart';
import 'basic.dart';
import 'container.dart';
import 'framework.dart';
import 'gesture_detector.dart';
import 'page_storage.dart';
import 'ticker_provider.dart';
import 'transitions.dart';

/// Enables control over a single [RawExpansionTile]'s expanded/collapsed state.
///
/// It can be useful to expand or collapse an [RawExpansionTile]
/// programmatically, for example to reconfigure an existing expansion
/// tile based on a system event. To do so, create an [RawExpansionTile]
/// with an [ExpansionTileController] that's owned by a stateful widget
/// or look up the tile's automatically created [ExpansionTileController]
/// with [ExpansionTileController.of]
///
/// The controller's [expand] and [collapse] methods cause the
/// the [RawExpansionTile] to rebuild, so they may not be called from
/// a build method.
class ExpansionTileController {
  /// Create a controller to be used with [RawExpansionTile.controller].
  ExpansionTileController();

  ///
  RawExpansionTileState<RawExpansionTile>? state;

  /// Whether the [RawExpansionTile] built with this controller is in expanded state.
  ///
  /// This property doesn't take the animation into account. It reports `true`
  /// even if the expansion animation is not completed.
  ///
  /// See also:
  ///
  ///  * [expand], which expands the [RawExpansionTile].
  ///  * [collapse], which collapses the [RawExpansionTile].
  ///  * [RawExpansionTile.controller] to create an ExpansionTile with a controller.
  bool get isExpanded {
    assert(state != null);
    return state!._isExpanded;
  }

  /// Expands the [RawExpansionTile] that was built with this controller;
  ///
  /// Normally the tile is expanded automatically when the user taps on the header.
  /// It is sometimes useful to trigger the expansion programmatically due
  /// to external changes.
  ///
  /// If the tile is already in the expanded state (see [isExpanded]), calling
  /// this method has no effect.
  ///
  /// Calling this method may cause the [RawExpansionTile] to rebuild, so it may
  /// not be called from a build method.
  ///
  /// Calling this method will trigger an [RawExpansionTile.onExpansionChanged] callback.
  ///
  /// See also:
  ///
  ///  * [collapse], which collapses the tile.
  ///  * [isExpanded] to check whether the tile is expanded.
  ///  * [RawExpansionTile.controller] to create an ExpansionTile with a controller.
  void expand() {
    assert(state != null);
    if (!isExpanded) {
      state!.toggleExpansion();
    }
  }

  /// Collapses the [RawExpansionTile] that was built with this controller.
  ///
  /// Normally the tile is collapsed automatically when the user taps on the header.
  /// It can be useful sometimes to trigger the collapse programmatically due
  /// to some external changes.
  ///
  /// If the tile is already in the collapsed state (see [isExpanded]), calling
  /// this method has no effect.
  ///
  /// Calling this method may cause the [RawExpansionTile] to rebuild, so it may
  /// not be called from a build method.
  ///
  /// Calling this method will trigger an [RawExpansionTile.onExpansionChanged] callback.
  ///
  /// See also:
  ///
  ///  * [expand], which expands the tile.
  ///  * [isExpanded] to check whether the tile is expanded.
  ///  * [RawExpansionTile.controller] to create an ExpansionTile with a controller.
  void collapse() {
    assert(state != null);
    if (isExpanded) {
      state!.toggleExpansion();
    }
  }

  /// Finds the [ExpansionTileController] for the closest [RawExpansionTile] instance
  /// that encloses the given context.
  ///
  /// If no [RawExpansionTile] encloses the given context, calling this
  /// method will cause an assert in debug mode, and throw an
  /// exception in release mode.
  ///
  /// To return null if there is no [RawExpansionTile] use [maybeOf] instead.
  ///
  /// {@tool dartpad}
  /// Typical usage of the [ExpansionTileController.of] function is to call it from within the
  /// `build` method of a descendant of an [RawExpansionTile].
  ///
  /// When the [RawExpansionTile] is actually created in the same `build`
  /// function as the callback that refers to the controller, then the
  /// `context` argument to the `build` function can't be used to find
  /// the [ExpansionTileController] (since it's "above" the widget
  /// being returned in the widget tree). In cases like that you can
  /// add a [Builder] widget, which provides a new scope with a
  /// [BuildContext] that is "under" the [RawExpansionTile]:
  ///
  /// ** See code in examples/api/lib/material/expansion_tile/expansion_tile.1.dart **
  /// {@end-tool}
  ///
  /// A more efficient solution is to split your build function into
  /// several widgets. This introduces a new context from which you
  /// can obtain the [ExpansionTileController]. With this approach you
  /// would have an outer widget that creates the [RawExpansionTile]
  /// populated by instances of your new inner widgets, and then in
  /// these inner widgets you would use [ExpansionTileController.of].
  static ExpansionTileController of(BuildContext context) {
    final RawExpansionTileState<RawExpansionTile>? result =
        context.findAncestorStateOfType<RawExpansionTileState<RawExpansionTile>>();
    if (result != null) {
      return result._tileController;
    }
    throw FlutterError.fromParts(<DiagnosticsNode>[
      ErrorSummary(
        'ExpansionTileController.of() called with a context that does not contain a RawExpansionTile.',
      ),
      ErrorDescription(
        'No RawExpansionTile ancestor could be found starting from the context that was passed to ExpansionTileController.of(). '
        'This usually happens when the context provided is from the same StatefulWidget as that '
        'whose build function actually creates the RawExpansionTile widget being sought.',
      ),
      ErrorHint(
        'There are several ways to avoid this problem. The simplest is to use a Builder to get a '
        'context that is "under" the RawExpansionTile. For an example of this, please see the '
        'documentation for ExpansionTileController.of():\n'
        '  https://api.flutter.dev/flutter/material/ExpansionTile/of.html',
      ),
      ErrorHint(
        'A more efficient solution is to split your build function into several widgets. This '
        'introduces a new context from which you can obtain the RawExpansionTile. In this solution, '
        'you would have an outer widget that creates the RawExpansionTile populated by instances of '
        'your new inner widgets, and then in these inner widgets you would use ExpansionTileController.of().\n'
        'An other solution is assign a GlobalKey to the RawExpansionTile, '
        'then use the key.currentState property to obtain the RawExpansionTile rather than '
        'using the ExpansionTileController.of() function.',
      ),
      context.describeElement('The context used was'),
    ]);
  }

  /// Finds the [RawExpansionTile] from the closest instance of this class that
  /// encloses the given context and returns its [ExpansionTileController].
  ///
  /// If no [RawExpansionTile] encloses the given context then return null.
  /// To throw an exception instead, use [of] instead of this function.
  ///
  /// See also:
  ///
  ///  * [of], a similar function to this one that throws if no [RawExpansionTile]
  ///    encloses the given context. Also includes some sample code in its
  ///    documentation.
  static ExpansionTileController? maybeOf(BuildContext context) {
    return context
        .findAncestorStateOfType<RawExpansionTileState<RawExpansionTile>>()
        ?._tileController;
  }
}

/// A single-line [ListTile] with an expansion arrow icon that expands or collapses
/// the tile to reveal or hide the [children].
///
/// This widget is typically used with [ListView] to create an "expand /
/// collapse" list entry. When used with scrolling widgets like [ListView], a
/// unique [PageStorageKey] must be specified as the [key], to enable the
/// [RawExpansionTile] to save and restore its expanded state when it is scrolled
/// in and out of view.
class RawExpansionTile extends StatefulWidget {
  /// Creates a single-line [ListTile] with an expansion arrow icon that expands or collapses
  /// the tile to reveal or hide the [children]. The [initiallyExpanded] property must
  /// be non-null.
  const RawExpansionTile({
    super.key,
    required this.title,
    required this.icon,
    this.onExpansionChanged,
    this.children = const <Widget>[],
    this.initiallyExpanded = false,
    this.maintainState = false,
    this.expansionDuration = const Duration(milliseconds: 200),
    this.expandedCrossAxisAlignment,
    this.expandedAlignment,
    this.childrenPadding,
    this.header,
    this.iconDegree = 0.5,
    this.controller,
  }) : assert(
         expandedCrossAxisAlignment != CrossAxisAlignment.baseline,
         'CrossAxisAlignment.baseline is not supported since the expanded children '
         'are aligned in a column, not a row. Try to use another constant.',
       );

  ///
  final Widget? icon;

  /// The primary content of the list item.
  ///
  /// Typically a [Text] widget.
  final Widget title;

  /// Called when the tile expands or collapses.
  ///
  /// When the tile starts expanding, this function is called with the value
  /// true. When the tile starts collapsing, this function is called with
  /// the value false.
  final ValueChanged<bool>? onExpansionChanged;

  /// The widgets that are displayed when the tile expands.
  final List<Widget> children;

  /// Specifies if the list tile is initially expanded (true) or collapsed (false, the default).
  final bool initiallyExpanded;

  /// Specifies whether the state of the children is maintained when the tile expands and collapses.
  ///
  /// When true, the children are kept in the tree while the tile is collapsed.
  /// When false (default), the children are removed from the tree when the tile is
  /// collapsed and recreated upon expansion.
  final bool maintainState;

  /// Specifies the alignment of each child within [children] when the tile is expanded.
  ///
  /// The internals of the expanded tile make use of a [Column] widget for
  /// [children], and the `crossAxisAlignment` parameter is passed directly into
  /// the [Column].
  ///
  /// Modifying this property controls the cross axis alignment of each child
  /// within its [Column]. The width of the [Column] that houses [children] will
  /// be the same as the widest child widget in [children]. The width of the
  /// [Column] might not be equal to the width of the expanded tile.
  ///
  /// To align the [Column] along the expanded tile, use the [expandedAlignment]
  /// property instead.
  ///
  /// When the value is null, the value of [expandedCrossAxisAlignment] is
  /// [CrossAxisAlignment.center].
  final CrossAxisAlignment? expandedCrossAxisAlignment;

  /// Specifies padding for [children].
  ///
  /// If this property is null, the value of [childrenPadding] is [EdgeInsets.zero].
  final EdgeInsetsGeometry? childrenPadding;

  /// Specifies the alignment of [children], which are arranged in a column when
  /// the tile is expanded.
  ///
  /// The internals of the expanded tile make use of a [Column] widget for
  /// [children], and [Align] widget to align the column. The [expandedAlignment]
  /// parameter is passed directly into the [Align].
  ///
  /// Modifying this property controls the alignment of the column within the
  /// expanded tile, not the alignment of [children] widgets within the column.
  /// To align each child within [children], see [expandedCrossAxisAlignment].
  ///
  /// The width of the column is the width of the widest child widget in [children].
  ///
  /// If this property is null, the value of [expandedAlignment] is [Alignment.center].
  final Alignment? expandedAlignment;

  /// If provided, the controller can be used to expand and collapse tiles.
  ///
  /// In cases were control over the tile's state is needed from a callback triggered
  /// by a widget within the tile, [ExpansionTileController.of] may be more convenient
  /// than supplying a controller.
  final ExpansionTileController? controller;

  ///
  final Widget? header;

  ///
  final Duration expansionDuration;

  ///
  final double iconDegree;

  @override
  State<RawExpansionTile> createState() => RawExpansionTileState<RawExpansionTile>();
}

///
class RawExpansionTileState<T extends RawExpansionTile> extends State<T>
    with SingleTickerProviderStateMixin {
  static final Animatable<double> _easeInTween = CurveTween(curve: Curves.easeIn);
  static final Animatable<double> _easeOutTween = CurveTween(curve: Curves.easeOut);

  final ColorTween _backgroundColorTween = ColorTween();
  final Tween<double> _heightFactorTween = Tween<double>(begin: 0.0, end: 1.0);

  late AnimationController _animationController;
  late Animation<double> _iconTurns;
  late CurvedAnimation _heightFactor;

  late Animation<Color?> _backgroundColorAnimation;

  bool _isExpanded = false;

  ///
  bool get isExpanded => _isExpanded;

  ///
  AnimationController get animationController => _animationController;

  ///
  CurvedAnimation get heightFactor => _heightFactor;

  ///
  Animation<Color?> get backgroundColorAnimation => _backgroundColorAnimation;

  ///
  ColorTween get backgroundColorTween => _backgroundColorTween;

  @protected
  ///
  EdgeInsetsGeometry get childrenPadding => widget.childrenPadding ?? EdgeInsets.zero;

  late ExpansionTileController _tileController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: widget.expansionDuration, vsync: this);
    _heightFactor = CurvedAnimation(
      parent: _animationController.drive(_heightFactorTween),
      curve: Curves.easeIn,
    );
    final Tween<double> iconDegreeTween = Tween<double>(begin: 0.0, end: widget.iconDegree);
    _iconTurns = _animationController.drive(iconDegreeTween.chain(_easeInTween));
    _backgroundColorAnimation = _animationController.drive(
      _backgroundColorTween.chain(_easeOutTween),
    );

    _isExpanded =
        PageStorage.maybeOf(context)?.readState(context) as bool? ?? widget.initiallyExpanded;
    if (_isExpanded) {
      _animationController.value = 1.0;
    }

    assert(widget.controller?.state == null);
    _tileController = widget.controller ?? ExpansionTileController();
    _tileController.state = this;
  }

  @override
  void dispose() {
    _tileController.state = null;
    _animationController.dispose();
    _heightFactor.dispose();
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  @protected
  @mustCallSuper
  ///
  void toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse().then<void>((void value) {
          if (!mounted) {
            return;
          }
          setState(() {
            // Rebuild without widget.children.
          });
        });
      }
      PageStorage.maybeOf(context)?.writeState(context, _isExpanded);
    });
    widget.onExpansionChanged?.call(_isExpanded);
  }

  @protected
  ///
  Widget? buildIcon(BuildContext context, Widget? icon) {
    return RotationTransition(turns: _iconTurns, child: icon);
  }

  @protected
  ///
  Widget buildChildren(BuildContext context, Widget? child) {
    final Decoration decoration = ShapeDecoration(
      color: _backgroundColorAnimation.value ?? const Color(0x00000000),
      shape: const Border(),
    );
    final Widget tile = Padding(
      padding: decoration.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          GestureDetector(
            onTap: toggleExpansion,
            child: FocusableActionDetector(
              child:
                  widget.header ??
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      widget.title,
                      buildIcon(context, widget.icon) ?? const SizedBox.shrink(),
                    ],
                  ),
            ),
          ),
          ClipRect(
            child: Align(
              alignment: widget.expandedAlignment ?? Alignment.center,
              heightFactor: heightFactor.value,
              child: child,
            ),
          ),
        ],
      ),
    );
    return DecoratedBox(decoration: decoration, child: tile);
  }

  @override
  Widget build(BuildContext context) {
    final bool closed = !_isExpanded && _animationController.isDismissed;
    final bool shouldRemoveChildren = closed && !widget.maintainState;

    final Widget result = Offstage(
      offstage: closed,
      child: TickerMode(
        enabled: !closed,
        child: Padding(
          padding: childrenPadding,
          child: Column(
            crossAxisAlignment: widget.expandedCrossAxisAlignment ?? CrossAxisAlignment.center,
            children: widget.children,
          ),
        ),
      ),
    );

    return AnimatedBuilder(
      animation: _animationController.view,
      builder: buildChildren,
      child: shouldRemoveChildren ? null : result,
    );
  }
}
