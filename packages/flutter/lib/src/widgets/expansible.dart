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

///
typedef ExpansibleComponentBuilder = Widget Function(BuildContext context, bool isExpanded);

///
typedef ExpansibleBuilder =
    Widget Function(BuildContext context, Widget header, Widget body, bool isExpanded);

/// A controller for managing the expansion state of an [Expansible].
///
/// This controller provides methods to programmatically expand or collapse the
/// widget, and it allows external components to query the current expansion
/// state.
///
/// The controller's [expand] and [collapse] methods cause the
/// the [Expansible] to rebuild, so they may not be called from
/// a build method.
class ExpansibleController {
  /// Creates a controller to be used with [Expansible.controller].
  ExpansibleController();

  ///
  ExpansibleState? _state;

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
  bool get isExpanded {
    assert(_state != null);
    return _state!._isExpanded;
  }

  /// Expands the expansible widget that was built with this controller.
  ///
  /// If the widget is already in the expanded state (see [isExpanded]), calling
  /// this method has no effect.
  ///
  /// Calling this method may cause the [Expansible] to rebuild, so it may
  /// not be called from a build method.
  ///
  /// Calling this method will trigger an [Expansible.onExpansionChanged]
  /// callback.
  ///
  /// See also:
  ///
  ///  * [collapse], which collapses the expansible widget.
  ///  * [isExpanded] to check whether the expansible widget is expanded.
  void expand() {
    assert(_state != null);
    if (!isExpanded) {
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
  /// Calling this method will trigger an [Expansible.onExpansionChanged]
  /// callback.
  ///
  /// See also:
  ///
  ///  * [expand], which expands the tile.
  ///  * [isExpanded] to check whether the tile is expanded.
  void collapse() {
    assert(_state != null);
    if (isExpanded) {
      _state!._toggleExpansion();
    }
  }

  ///
  Animation<U> drive<U>(Animatable<U> child) {
    assert(_state != null);
    return _state!._animationController.drive(child);
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
  /// {@tool dartpad}
  /// Typical usage of the [ExpansibleController.of] function is to call it from within the
  /// `build` method of a descendant of an [Expansible].
  ///
  /// When the [Expansible] is actually created in the same `build`
  /// function as the callback that refers to the controller, then the
  /// `context` argument to the `build` function can't be used to find
  /// the [ExpansibleController] (since it's "above" the widget
  /// being returned in the widget tree). In cases like that you can
  /// add a [Builder] widget, which provides a new scope with a
  /// [BuildContext] that is "under" the [Expansible]:
  ///
  /// ** See code in examples/api/lib/material/expansion_tile/expansion_tile.1.dart **
  /// {@end-tool}
  ///
  /// A more efficient solution is to split your build function into
  /// several widgets. This introduces a new context from which you
  /// can obtain the [ExpansibleController]. With this approach you
  /// would have an outer widget that creates the [Expansible]
  /// populated by instances of your new inner widgets, and then in
  /// these inner widgets you would use [ExpansibleController.of].
  static ExpansibleController of(BuildContext context) {
    final ExpansibleState? result = context.findAncestorStateOfType<ExpansibleState>();
    if (result != null) {
      return result.widget.controller;
    }
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
        'context that is "under" the Expansible. For an example of this, please see the '
        'documentation for ExpansibleController.of():\n'
        '  https://api.flutter.dev/flutter/widgets/Expansible/of.html',
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

  /// Finds the [Expansible] from the closest instance of this class that
  /// encloses the given context and returns its [ExpansibleController].
  ///
  /// If no [Expansible] encloses the given context then return null.
  /// To throw an exception instead, use [of] instead of this function.
  ///
  /// See also:
  ///
  ///  * [of], a similar function to this one that throws if no [Expansible]
  ///    encloses the given context. Also includes some sample code in its
  ///    documentation.
  static ExpansibleController? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<ExpansibleState>()?.widget.controller;
  }
}

///
class Expansible extends StatefulWidget {
  ///
  const Expansible({
    super.key,
    required this.headerBuilder,
    required this.bodyBuilder,
    required this.controller,
    this.expansibleBuilder,
    this.onExpansionChanged,
    this.duration = const Duration(milliseconds: 200),
    this.curve = Curves.ease,
    this.reverseCurve,
    this.initiallyExpanded = false,
    this.maintainState = false,
    this.addHeaderTap = true,
  });

  /// Called when this widget expands or collapses.
  ///
  /// When the widget starts expanding, this function is called with value
  /// true. When the widget starts collapsing, this function is called with
  /// value false.
  final ValueChanged<bool>? onExpansionChanged;

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

  /// True if the widget is initially expanded, and false otherwise.
  final bool initiallyExpanded;

  /// False if the header already coordinates its behavior on tap using the
  /// [controller].
  ///
  /// Defaults to true.
  final bool addHeaderTap;

  /// Specifies whether the state of the children is maintained when the widget
  /// expands and collapses.
  ///
  /// If true, the children are kept in the tree while the widget is
  /// collapsed. Otherwise, the children are removed from the tree when the
  /// widget is collapsed and recreated upon expansion.
  final bool maintainState;

  /// Used to programmatically expand and collapse the widget.
  final ExpansibleController controller;

  ///
  final ExpansibleComponentBuilder headerBuilder;

  ///
  final ExpansibleComponentBuilder bodyBuilder;

  ///
  final ExpansibleBuilder? expansibleBuilder;

  @override
  State<StatefulWidget> createState() => ExpansibleState();
}

///
class ExpansibleState extends State<Expansible> with TickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late CurvedAnimation _heightFactor;

  @override
  void initState() {
    super.initState();
    assert(widget.controller._state == null);
    widget.controller._state = this;
    _animationController = AnimationController(duration: widget.duration, vsync: this);
    _isExpanded =
        PageStorage.maybeOf(context)?.readState(context) as bool? ?? widget.initiallyExpanded;
    if (_isExpanded) {
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
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
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
      PageStorage.maybeOf(context)?.writeState(context, _isExpanded);
    });
    widget.onExpansionChanged?.call(_isExpanded);
  }

  Widget _buildExpansible(BuildContext context, Widget header, Widget body) {
    return Column(mainAxisSize: MainAxisSize.min, children: <Widget>[header, body]);
  }

  @override
  Widget build(BuildContext context) {
    final bool closed = !_isExpanded && _animationController.isDismissed;
    final bool shouldRemoveChildren = closed && !widget.maintainState;

    final Widget result = Offstage(
      offstage: closed,
      child: TickerMode(enabled: !closed, child: widget.bodyBuilder(context, _isExpanded)),
    );

    return AnimatedBuilder(
      animation: _animationController.view,
      builder: (BuildContext context, Widget? child) {
        Widget header = widget.headerBuilder(context, _isExpanded);
        if (widget.addHeaderTap) {
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
          return widget.expansibleBuilder!(context, header, body, _isExpanded);
        }
        return _buildExpansible(context, header, body);
      },
      child: shouldRemoveChildren ? null : result,
    );
  }
}
