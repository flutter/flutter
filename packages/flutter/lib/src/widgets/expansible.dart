// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/material.dart';
library;

import 'basic.dart';
import 'framework.dart';
import 'gesture_detector.dart';
import 'page_storage.dart';
import 'ticker_provider.dart';
import 'transitions.dart';

/// The type of the callback that returns the header or body of an [Expansible].
///
/// The `animation` property exposes the underlying expanding or collapsing
/// animation, which has a value of 0 when the [Expansible] is completely
/// collapsed and 1 when it is completely expanded. This can be used to drive
/// animations that sync up with the expanding or collapsing animation, such as
/// rotating an icon.
///
/// See also:
///
///   * [Expansible.headerBuilder], which is of this type.
///   * [Expansible.bodyBuilder], which is also of this type.
typedef ExpansibleComponentBuilder =
    Widget Function(BuildContext context, Animation<double> animation);

/// The type of the callback that uses the header and body of an [Expansible]
/// widget to build the widget.
///
/// The `header` property is the header returned by [Expansible.headerBuilder]
/// wrapped in a [GestureDetector] to toggle the expansion when tapped.
///
/// The `body` property is the body returned by [Expansible.bodyBuilder] wrapped
/// in an [Offstage] to hide the body when the [Expansible] is collapsed.
///
/// The `animation` property exposes the underlying expanding or collapsing
/// animation, which has a value of 0 when the [Expansible] is completely
/// collapsed and 1 when it is completely expanded. This can be used to drive
/// animations that sync up with the expanding or collapsing animation, such as
/// rotating an icon.
///
/// See also:
///
///   * [Expansible.expansibleBuilder], which is of this type.
typedef ExpansibleBuilder =
    Widget Function(BuildContext context, Widget header, Widget body, Animation<double> animation);

/// A controller for managing the expansion state of an [Expansible].
///
/// This class is a [ChangeNotifier] that notifies its listeners if the value of
/// [isExpanded] changes.
///
/// This controller provides methods to programmatically expand or collapse the
/// widget, and it allows external components to query the current expansion
/// state.
///
/// The controller's [expand] and [collapse] methods cause the
/// the [Expansible] to rebuild, so they may not be called from
/// a build method.
///
class ExpansibleController extends ChangeNotifier {
  /// Creates a controller to be used with [Expansible.controller].
  ExpansibleController();

  _ExpansibleState? _state;

  /// Whether the expansible widget built with this controller is in expanded
  /// state.
  ///
  /// This property doesn't take the animation into account. It reports `true`
  /// even if the expansion animation is not completed.
  ///
  /// See also:
  ///
  ///  * [expand], which expands the expansible widget.
  ///  * [collapse], which collapses the expansible widget.
  bool get isExpanded => _isExpanded;
  bool _isExpanded = false;
  set isExpanded(bool value) {
    if (_isExpanded == value) {
      return;
    }
    _isExpanded = value;
    notifyListeners();
  }

  /// Expands the expansible widget that was built with this controller.
  ///
  /// If the widget is already in the expanded state (see [isExpanded]), calling
  /// this method has no effect.
  ///
  /// Calling this method may cause the [Expansible] to rebuild, so it may
  /// not be called from a build method.
  ///
  /// Calling this method will notify registered listeners of this controller
  /// that the expansion state has changed.
  ///
  /// See also:
  ///
  ///  * [collapse], which collapses the expansible widget.
  ///  * [isExpanded] to check whether the expansible widget is expanded.
  void expand() {
    assert(_state != null);
    if (!_isExpanded) {
      _state!._toggleExpansion();
    }
  }

  /// Collapses the expansible widget that was built with this controller.
  ///
  /// If the widget is already in the collapsed state (see [isExpanded]),
  /// calling this method has no effect.
  ///
  /// Calling this method may cause the [Expansible] to rebuild, so it may not
  /// be called from a build method.
  ///
  /// Calling this method will notify registered listeners of this controller
  /// that the expansion state has changed.
  ///
  /// See also:
  ///
  ///  * [expand], which expands the [Expansible].
  ///  * [isExpanded] to check whether the [Expansible] is expanded.
  void collapse() {
    assert(_state != null);
    if (_isExpanded) {
      _state!._toggleExpansion();
    }
  }

  /// Finds the [ExpansibleController] for the closest [Expansible] instance
  /// that encloses the given context.
  ///
  /// If no [Expansible] encloses the given context, calling this
  /// method will cause an assert in debug mode, and throw an
  /// exception in release mode.
  ///
  /// To return null if there is no [Expansible] use [maybeOf] instead.
  ///
  /// Typical usage of the [ExpansibleController.of] function is to call it from
  /// within the `build` method of a descendant of an [Expansible].
  static ExpansibleController of(BuildContext context) {
    final _ExpansibleState? result = context.findAncestorStateOfType<_ExpansibleState>();
    assert(() {
      if (result == null) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
            'ExpansibleController.of() called with a context that does not contain a Expansible.',
          ),
          ErrorDescription(
            'No Expansible ancestor could be found starting from the context that was passed to ExpansibleController.of(). '
            'This usually happens when the context provided is from the same StatefulWidget as that '
            'whose build function actually creates the Expansible widget being sought.',
          ),
          ErrorHint(
            'There are several ways to avoid this problem. The simplest is to use a Builder to get a '
            'context that is "under" the Expansible. ',
          ),
          ErrorHint(
            'A more efficient solution is to split your build function into several widgets. This '
            'introduces a new context from which you can obtain the Expansible. In this solution, '
            'you would have an outer widget that creates the Expansible populated by instances of '
            'your new inner widgets, and then in these inner widgets you would use ExpansibleController.of().\n'
            'An other solution is assign a GlobalKey to the Expansible, '
            'then use the key.currentState property to obtain the Expansible rather than '
            'using the ExpansibleController.of() function.',
          ),
          context.describeElement('The context used was'),
        ]);
      }
      return true;
    }());
    return result!.widget.controller;
  }

  /// Finds the [Expansible] from the closest instance of this class that
  /// encloses the given context and returns its [ExpansibleController].
  ///
  /// If no [Expansible] encloses the given context then return null.
  /// To throw an exception instead, use [of] instead of this function.
  ///
  /// See also:
  ///
  ///  * [of], a similar function to this one that throws if no [Expansible]
  ///    encloses the given context.
  static ExpansibleController? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<_ExpansibleState>()?.widget.controller;
  }
}

/// A [StatefulWidget] that expands and collapses.
///
/// An [Expansible] consists of a header, which is always shown, and a
/// body, which is hidden in its collapsed state and shown in its expanded
/// state.
///
/// The [Expansible] is expanded or collapsed with an animation driven by an
/// [AnimationController]. When the widget is expanded, the height of its body
/// animates from 0 to its fully expanded height.
///
/// This widget is typically used with [ListView] to create an "expand /
/// collapse" list entry. When used with scrolling widgets like [ListView], a
/// unique [PageStorageKey] must be specified as the [key], to enable the
/// [Expansible] to save and restore its expanded state when it is scrolled
/// in and out of view.
///
/// Provide [headerBuilder] and [bodyBuilder] callbacks to
/// build the header and body widgets. An additional [expansibleBuilder]
/// callback can be provided to further customize the layout of the widget.
///
/// See also:
///
///  * [ExpansionTile], a Material-styled widget that expands and collapses.
class Expansible extends StatefulWidget {
  /// Creates an instance of [Expansible].
  const Expansible({
    super.key,
    required this.headerBuilder,
    required this.bodyBuilder,
    required this.controller,
    this.expansibleBuilder,
    this.duration = const Duration(milliseconds: 200),
    this.curve = Curves.ease,
    this.reverseCurve,
    this.maintainState = false,
    this.excludeHeaderGestures = false,
  });

  /// Used to programmatically expand and collapse the widget.
  final ExpansibleController controller;

  /// Builds the always-displayed header.
  ///
  /// If this header already has an `onTap` or `onPressed` method that toggles
  /// its expansion, set [excludeHeaderGestures] to true.
  final ExpansibleComponentBuilder headerBuilder;

  /// Builds the collapsible body.
  ///
  /// When this widget is expanded, the height of its body animates from 0 to
  /// its fully extended height.
  final ExpansibleComponentBuilder bodyBuilder;

  /// Lays out the widget with the results of [headerBuilder] and [bodyBuilder].
  ///
  /// Defaults to placing the header and body in a [Column].
  final ExpansibleBuilder? expansibleBuilder;

  /// The duration of the expansion animation.
  ///
  /// Defaults to a duration of 200ms.
  final Duration duration;

  /// The curve of the expansion animation.
  ///
  /// Defaults to [Curves.ease].
  final Curve curve;

  /// The reverse curve of the expansion animation.
  final Curve? reverseCurve;

  /// If the header already coordinates its behavior on tap using the
  /// [controller].
  ///
  /// By default, the header returned from [headerBuilder] is wrapped in a
  /// [GestureDetector] to toggle the expansion when tapped. Set this to true to
  /// avoid conflicting gestures if the header returned in [headerBuilder]
  /// already toggles its expansion on tap using [ExpansibleController.expand]
  /// or [ExpansibleController.collapse].
  ///
  /// Defaults to false.
  final bool excludeHeaderGestures;

  /// If the state of the body is maintained when the widget expands or
  /// collapses.
  ///
  /// If true, the body is kept in the tree while the widget is
  /// collapsed. Otherwise, the body is removed from the tree when the
  /// widget is collapsed and recreated upon expansion.
  ///
  /// Defaults to false.
  final bool maintainState;

  @override
  State<StatefulWidget> createState() => _ExpansibleState();
}

class _ExpansibleState extends State<Expansible> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late CurvedAnimation _heightFactor;

  @override
  void initState() {
    super.initState();
    assert(widget.controller._state == null);
    widget.controller._state = this;
    _animationController = AnimationController(duration: widget.duration, vsync: this);
    widget.controller.isExpanded =
        PageStorage.maybeOf(context)?.readState(context) as bool? ?? widget.controller.isExpanded;
    // If the expansible should be initially expanded.
    if (widget.controller.isExpanded) {
      _animationController.value = 1.0;
    }
    final Tween<double> heightFactorTween = Tween<double>(begin: 0.0, end: 1.0);
    _heightFactor = CurvedAnimation(
      parent: _animationController.drive(heightFactorTween),
      curve: widget.curve,
      reverseCurve: widget.reverseCurve,
    );
  }

  @override
  void didUpdateWidget(covariant Expansible oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.curve != oldWidget.curve) {
      _heightFactor.curve = widget.curve;
    }
    if (widget.reverseCurve != oldWidget.reverseCurve) {
      _heightFactor.reverseCurve = widget.reverseCurve;
    }
    if (widget.duration != oldWidget.duration) {
      _animationController.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    widget.controller._state = null;
    _animationController.dispose();
    _heightFactor.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      widget.controller.isExpanded = !widget.controller.isExpanded;
      if (widget.controller.isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse().then<void>((void value) {
          if (!mounted) {
            return;
          }
          setState(() {
            // Rebuild without the body.
          });
        });
      }
      PageStorage.maybeOf(context)?.writeState(context, widget.controller.isExpanded);
    });
  }

  Widget _buildExpansible(BuildContext context, Widget header, Widget body) {
    return Column(mainAxisSize: MainAxisSize.min, children: <Widget>[header, body]);
  }

  @override
  Widget build(BuildContext context) {
    final bool closed = !widget.controller.isExpanded && _animationController.isDismissed;
    final bool shouldRemoveBody = closed && !widget.maintainState;

    final Widget result = Offstage(
      offstage: closed,
      child: TickerMode(enabled: !closed, child: widget.bodyBuilder(context, _animationController)),
    );

    return AnimatedBuilder(
      animation: _animationController.view,
      builder: (BuildContext context, Widget? child) {
        Widget header = widget.headerBuilder(context, _animationController);
        if (!widget.excludeHeaderGestures) {
          header = Semantics(
            button: true,
            child: GestureDetector(
              onTap: _toggleExpansion,
              excludeFromSemantics: true,
              child: header,
            ),
          );
        }
        final Widget body = ClipRect(child: Align(heightFactor: _heightFactor.value, child: child));
        if (widget.expansibleBuilder != null) {
          return widget.expansibleBuilder!(context, header, body, _animationController);
        }
        return _buildExpansible(context, header, body);
      },
      child: shouldRemoveBody ? null : result,
    );
  }
}
