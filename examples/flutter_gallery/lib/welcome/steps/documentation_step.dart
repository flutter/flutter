import 'package:flutter/material.dart';
import 'package:flutter_gallery/welcome/step.dart';

class DocumentationWelcomeStep extends WelcomeStep {
  DocumentationWelcomeStep({TickerProvider tickerProvider})
      : super(tickerProvider: tickerProvider);

  AnimationController _animationController;
  AnimationController _quickAnimationController;
  Animation<double> _barScaleAnimation;
  Animation<double> _barOpacityAnimation;
  Animation<double> _focusScaleAnimation;
  Animation<double> _focusOpacityAnimation;
  Animation<double> _iconOpacityAnimation;

  @override
  String title() => 'Complete, flexible APIs';
  @override
  String subtitle() => 'View full API documentation, when you need it, with a quick tap. Look for the documentation icon in the app bar.';

  @override
  Widget imageWidget() {
    _animationController = AnimationController(
      vsync: tickerProvider,
      duration: Duration(milliseconds: 300),
    );
    _quickAnimationController = AnimationController(
      vsync: tickerProvider,
      duration: Duration(milliseconds: 120),
    );
    _barScaleAnimation =
        Tween<double>(begin: 1.0, end: 0.95).animate(_animationController);
    _barOpacityAnimation =
        Tween<double>(begin: 1.0, end: 0.8).animate(_quickAnimationController);
    _focusScaleAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _focusOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _iconOpacityAnimation =
        Tween<double>(begin: 1.0, end: 0.0).animate(_quickAnimationController);

    final Image barImage = Image.asset(
      'assets/images/welcome/welcome_documentation.png',
    );
    return Stack(
      children: <Widget>[
        Center(
          child: FadeTransition(
            opacity: _barOpacityAnimation,
            child: ScaleTransition(
              scale: _barScaleAnimation,
              child: barImage,
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: FadeTransition(
            opacity: _iconOpacityAnimation,
            child: Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: Image.asset(
                'assets/images/welcome/ic_documentation.png',
                width: 20.0,
                height: 20.0,
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: ScaleTransition(
            scale: _focusScaleAnimation,
            child: FadeTransition(
              opacity: _focusOpacityAnimation,
              child: Image.asset(
                'assets/images/welcome/welcome_documentation_focus.png',
                width: 85.0,
                height: 85.0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void animate({bool restart = false}) {
    if (restart) {
      _animationController.reset();
      _quickAnimationController.reset();
    }
    Future<void>.delayed(Duration(milliseconds: 500), () {
      _animationController.forward();
      _quickAnimationController.forward();
    });
  }
}
