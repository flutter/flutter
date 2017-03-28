import 'package:flutter/widgets.dart';

/// A page route transition used for Android and Fuchsia to transition between pages.
class MountainViewPageTransition extends AnimatedWidget {
  static final FractionalOffsetTween _kTween = new FractionalOffsetTween(
    begin: FractionalOffset.bottomLeft,
    end: FractionalOffset.topLeft
  );

  MountainViewPageTransition({
    Key key,
    Animation<double> animation,
    this.child,
  }) : super(
    key: key,
    listenable: _kTween.animate(new CurvedAnimation(
      parent: animation, // The route's linear 0.0 - 1.0 animation.
      curve: Curves.fastOutSlowIn
    )
  ));

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // TODO(ianh): tell the transform to be un-transformed for hit testing
    return new SlideTransition(
      position: listenable,
      child: child
    );
  }
}
