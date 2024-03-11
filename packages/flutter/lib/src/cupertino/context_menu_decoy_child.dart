import 'package:flutter/src/cupertino/context_menu.dart';
import 'package:flutter/widgets.dart';

// The duration of the transition used when a modal popup is shown. Eyeballed
// from a physical device running iOS 13.1.2.
const Duration _kModalPopupTransitionDuration = Duration(milliseconds: 335);

// The duration it takes for the CupertinoContextMenu to open.
// This value was eyeballed from the XCode simulator running iOS 16.0.
const Duration _previewLongPressTimeout = Duration(milliseconds: 800);

// The total length of the combined animations until the menu is fully open.
final int _animationDuration =
  _previewLongPressTimeout.inMilliseconds + _kModalPopupTransitionDuration.inMilliseconds;

// The final box shadow for the opening child widget.
// This value was eyeballed from the XCode simulator running iOS 16.0.
const List<BoxShadow> _endBoxShadow = <BoxShadow>[
  BoxShadow(
    color: Color(0x40000000),
    blurRadius: 10.0,
    spreadRadius: 0.5,
  ),
];

/// A floating copy of the CupertinoContextMenu's child.
///
/// When the child is pressed, but before the CupertinoContextMenu opens, it does
/// an animation where it slowly grows. This is implemented by hiding the
/// original child and placing DecoyChild on top of it in an Overlay. The use of
/// an Overlay allows the DecoyChild to appear on top of siblings of the
/// original child.
class DecoyChild extends StatefulWidget {

  /// Create a DecoyChild.
  const DecoyChild({
    super.key,
    this.beginRect,
    required this.controller,
    this.endRect,
    this.child,
    this.builder,
  });

  /// The rect of the child at the moment that the CupertinoContextMenu opens.
  final Rect? beginRect;

  /// The controller that drives the animation of the decoy child.
  final AnimationController controller;

  /// The rect of the child at the moment that the CupertinoContextMenu opens.
  final Rect? endRect;

  /// The child widget that is being previewed.
  final Widget? child;

  /// A function that builds the child and handles the transition between the
  /// default child and the preview when the CupertinoContextMenu is open.
  final CupertinoContextMenuBuilder? builder;

  @override
  DecoyChildState createState() => DecoyChildState();
}



/// The state of the [DecoyChild]
///
/// This class is responsible for animating the child widget when the
/// CupertinoContextMenu is about to open.
class DecoyChildState extends State<DecoyChild> with TickerProviderStateMixin {
  /// The point at which the CupertinoContextMenu begins to animate
  /// into the open position.
  ///
  /// A value between 0.0 and 1.0 corresponding to a point in [builder]'s
  /// animation. When passing in an animation to [builder] the range before
  /// [animationOpensAt] will correspond to the animation when the widget is
  /// pressed and held, and the range after is the animation as the menu is
  /// fully opening. For an example, see the documentation for [builder].
  static final double animationOpensAt =
      _previewLongPressTimeout.inMilliseconds / _animationDuration;
  late Animation<Rect?> _rect;
  late Animation<Decoration> _boxDecoration;

  /// External state validation.
  ///
  /// used to validate current color of the decoy child
  /// against the expected [BoxDecoration]
  bool validateDecoyColor(Color? color) {
    final BoxDecoration? boxDecoration = _boxDecoration.value as BoxDecoration?;
    return boxDecoration?.color == color;
  }

  @override
  void initState() {
    super.initState();

    const double beginPause = 1.0;
    const double openAnimationLength = 5.0;
    const double totalOpenAnimationLength = beginPause + openAnimationLength;
    final double endPause =
      ((totalOpenAnimationLength * _animationDuration) / _previewLongPressTimeout.inMilliseconds) - totalOpenAnimationLength;

    // The timing on the animation was eyeballed from the XCode iOS simulator
    // running iOS 16.0.
    // Because the animation no longer goes from 0.0 to 1.0, but to a number
    // depending on the ratio between the press animation time and the opening
    // animation time, a pause needs to be added to the end of the tween
    // sequence that completes that ratio. This is to allow the animation to
    // fully complete as expected without doing crazy math to the _kOpenScale
    // value. This change was necessary from the inclusion of the builder and
    // the complete animation value that it passes along.
    _rect = TweenSequence<Rect?>(<TweenSequenceItem<Rect?>>[
      TweenSequenceItem<Rect?>(
        tween: RectTween(
          begin: widget.beginRect,
          end: widget.beginRect,
        ).chain(CurveTween(curve: Curves.linear)),
        weight: beginPause,
      ),
      TweenSequenceItem<Rect?>(
        tween: RectTween(
          begin: widget.beginRect,
          end: widget.endRect,
        ).chain(CurveTween(curve: Curves.easeOutSine)),
        weight: openAnimationLength,
      ),
      TweenSequenceItem<Rect?>(
        tween: RectTween(
          begin: widget.endRect,
          end: widget.endRect,
        ).chain(CurveTween(curve: Curves.linear)),
        weight: endPause,
      ),
    ]).animate(widget.controller);

    _boxDecoration = DecorationTween(
      begin: const BoxDecoration(
        boxShadow: <BoxShadow>[],
      ),
      end: const BoxDecoration(
        boxShadow: _endBoxShadow,
      ),
    ).animate(CurvedAnimation(
        parent: widget.controller,
        curve: Interval(0.0, CupertinoContextMenu.animationOpensAt),
      ),
    );
  }

  Widget _buildAnimation(BuildContext context, Widget? child) {
    return Positioned.fromRect(
      rect: _rect.value!,
      child: Container(
        decoration: _boxDecoration.value,
        child: widget.child,
      ),
    );
  }

  Widget _buildBuilder(BuildContext context, Widget? child) {
    return Positioned.fromRect(
      rect: _rect.value!,
      child: widget.builder!(context, widget.controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AnimatedBuilder(
          builder: widget.child != null ? _buildAnimation : _buildBuilder,
          animation: widget.controller,
        ),
      ],
    );
  }
}
