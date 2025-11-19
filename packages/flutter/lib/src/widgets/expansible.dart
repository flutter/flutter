// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/material.dart';
library;

import 'basic.dart';
import 'framework.dart';
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
/// The `header` property is the header returned by [Expansible.headerBuilder].
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
/// [Expansible] to rebuild, so they may not be called from
/// a build method.
///
/// Remember to [dispose] of the [ExpansibleController] when it is no longer
/// needed. This will ensure all resources used by the object are discarded.
class ExpansibleController extends ChangeNotifier {
  /// Creates a controller to be used with [Expansible.controller].
  ExpansibleController();

  bool _isExpanded = false;

  void _setExpansionState(bool newValue) {
    if (newValue != _isExpanded) {
      _isExpanded = newValue;
      notifyListeners();
    }
  }

  /// Whether the expansible widget built with this controller is in expanded
  /// state.
  ///
  /// This property doesn't take the animation into account. It reports `true`
  /// even if the expansion animation is not completed.
  ///
  /// To be notified when this property changes, add a listener to the
  /// controller using [ExpansibleController.addListener].
  ///
  /// See also:
  ///
  ///  * [expand], which expands the expansible widget.
  ///  * [collapse], which collapses the expansible widget.
  bool get isExpanded => _isExpanded;

  /// Expands the [Expansible] that was built with this controller.
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
    _setExpansionState(true);
  }

  /// Collapses the [Expansible] that was built with this controller.
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
    _setExpansionState(false);
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
/// The [Expansible] does not inherently toggle the expansion state. To toggle
/// the expansion state, call [ExpansibleController.expand] and
/// [ExpansibleController.collapse] as needed, most typically when the header
/// returned in [headerBuilder] is tapped.
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
    this.expansibleBuilder = _defaultExpansibleBuilder,
    this.animationStyle,
    @Deprecated(
      'Use animationStyle instead. '
      'This feature was deprecated after v3.38.0-0.2.pre.',
    )
    this.duration = const Duration(milliseconds: 200),
    @Deprecated(
      'Use animationStyle instead. '
      'This feature was deprecated after v3.38.0-0.2.pre.',
    )
    this.curve = Curves.ease,
    @Deprecated(
      'Use animationStyle instead. '
      'This feature was deprecated after v3.38.0-0.2.pre.',
    )
    this.reverseCurve,
    this.maintainState = true,
  });

  /// Expands and collapses the widget.
  ///
  /// The controller manages the expansion state and toggles the expansion.
  final ExpansibleController controller;

  /// Builds the always-displayed header.
  ///
  /// Many use cases involve toggling the expansion state when this header is
  /// tapped. To toggle the expansion state, call [ExpansibleController.expand]
  /// or [ExpansibleController.collapse].
  final ExpansibleComponentBuilder headerBuilder;

  /// Builds the collapsible body.
  ///
  /// When this widget is expanded, the height of its body animates from 0 to
  /// its fully extended height.
  final ExpansibleComponentBuilder bodyBuilder;

  /// Used to override the expansion animation curve and duration.
  ///
  /// If [AnimationStyle.duration] is provided, it will be used instead of
  /// [duration]. If not provided, [duration] is used, which defaults to
  /// 200ms.
  ///
  /// If [AnimationStyle.curve] is provided, it will be used to override
  /// [curve]. If it is null, then [curve] will be used. Otherwise, defaults
  /// to [Curves.ease].
  ///
  /// If [AnimationStyle.reverseCurve] is provided, it will be used to
  /// override [reverseCurve]. If it is null, then [reverseCurve] will be
  /// used.
  ///
  /// To disable the theme animation, use [AnimationStyle.noAnimation].
  final AnimationStyle? animationStyle;

  /// The duration of the expansion animation.
  ///
  /// Defaults to a duration of 200ms.
  ///
  /// This property is deprecated, use [animationStyle] instead.
  @Deprecated(
    'Use animationStyle instead. '
    'This feature was deprecated after v3.38.0-0.2.pre.',
  )
  final Duration duration;

  /// The curve of the expansion animation.
  ///
  /// Defaults to [Curves.ease].
  ///
  /// This property is deprecated, use [animationStyle] instead.
  @Deprecated(
    'Use animationStyle instead. '
    'This feature was deprecated after v3.38.0-0.2.pre.',
  )
  final Curve curve;

  /// The reverse curve of the expansion animation.
  ///
  /// If null, uses [curve] in both directions.
  ///
  /// This property is deprecated, use [animationStyle] instead.
  @Deprecated(
    'Use animationStyle instead. '
    'This feature was deprecated after v3.38.0-0.2.pre.',
  )
  final Curve? reverseCurve;

  /// Whether the state of the body is maintained when the widget expands or
  /// collapses.
  ///
  /// If true, the body is kept in the tree while the widget is
  /// collapsed. Otherwise, the body is removed from the tree when the
  /// widget is collapsed and recreated upon expansion.
  ///
  /// Defaults to true.
  final bool maintainState;

  /// Builds the widget with the results of [headerBuilder] and [bodyBuilder].
  ///
  /// Defaults to placing the header and body in a [Column].
  final ExpansibleBuilder expansibleBuilder;

  static Widget _defaultExpansibleBuilder(
    BuildContext context,
    Widget header,
    Widget body,
    Animation<double> animation,
  ) {
    return Column(mainAxisSize: MainAxisSize.min, children: <Widget>[header, body]);
  }

  @override
  State<StatefulWidget> createState() => _ExpansibleState();
}

class _ExpansibleState extends State<Expansible> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late CurvedAnimation _heightFactor;

  Duration get _duration {
    return widget.animationStyle?.duration ?? widget.duration;
  }

  Curve get _curve {
    return widget.animationStyle?.curve ?? widget.curve;
  }

  Curve? get _reverseCurve {
    return widget.animationStyle?.reverseCurve ?? widget.reverseCurve;
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: _duration, vsync: this);
    final bool initiallyExpanded =
        PageStorage.maybeOf(context)?.readState(context) as bool? ?? widget.controller.isExpanded;
    if (initiallyExpanded) {
      _animationController.value = 1.0;
      widget.controller.expand();
    } else {
      widget.controller.collapse();
    }
    final Tween<double> heightFactorTween = Tween<double>(begin: 0.0, end: 1.0);
    _heightFactor = CurvedAnimation(
      parent: _animationController.drive(heightFactorTween),
      curve: _curve,
      reverseCurve: _reverseCurve,
    );
    widget.controller.addListener(_toggleExpansion);
  }

  @override
  void didUpdateWidget(covariant Expansible oldWidget) {
    super.didUpdateWidget(oldWidget);
    final Duration oldDuration = oldWidget.animationStyle?.duration ?? oldWidget.duration;
    final Curve oldCurve = oldWidget.animationStyle?.curve ?? oldWidget.curve;
    final Curve? oldReverseCurve = oldWidget.animationStyle?.reverseCurve ?? oldWidget.reverseCurve;

    if (_curve != oldCurve) {
      _heightFactor.curve = _curve;
    }
    if (_reverseCurve != oldReverseCurve) {
      _heightFactor.reverseCurve = _reverseCurve;
    }
    if (_duration != oldDuration) {
      _animationController.duration = _duration;
    }
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_toggleExpansion);
      widget.controller.addListener(_toggleExpansion);
      if (oldWidget.controller.isExpanded != widget.controller.isExpanded) {
        _toggleExpansion();
      }
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_toggleExpansion);
    _animationController.dispose();
    _heightFactor.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      // Rebuild with the header and the animating body.
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

  @override
  Widget build(BuildContext context) {
    assert(!_animationController.isDismissed || !widget.controller.isExpanded);
    final bool closed = !widget.controller.isExpanded && _animationController.isDismissed;
    final bool shouldRemoveBody = closed && !widget.maintainState;

    final Widget result = Offstage(
      offstage: closed,
      child: TickerMode(enabled: !closed, child: widget.bodyBuilder(context, _animationController)),
    );

    return AnimatedBuilder(
      animation: _animationController.view,
      builder: (BuildContext context, Widget? child) {
        final Widget header = widget.headerBuilder(context, _animationController);
        final Widget body = ClipRect(
          child: Align(heightFactor: _heightFactor.value, child: child),
        );
        return widget.expansibleBuilder(context, header, body, _animationController);
      },
      child: shouldRemoveBody ? null : result,
    );
  }
}
