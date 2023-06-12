import 'dart:math' show pow;

import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class Button extends StatefulWidget {
  const Button({
    Key? key,
    this.icon,
    this.iconSize,
    this.leading,
    this.iconActiveColor,
    this.iconColor,
    this.text,
    this.gap,
    this.color,
    this.rippleColor,
    this.hoverColor,
    required this.onPressed,
    this.duration,
    this.curve,
    this.padding,
    this.margin,
    required this.active,
    this.debug,
    this.gradient,
    this.borderRadius,
    this.border,
    this.activeBorder,
    this.shadow,
    this.style = GnavStyle.google,
    this.textSize,
  }) : super(key: key);

  final IconData? icon;
  final double? iconSize;
  final Text? text;
  final Widget? leading;
  final Color? iconActiveColor;
  final Color? iconColor;
  final Color? color;
  final Color? rippleColor;
  final Color? hoverColor;
  final double? gap;
  final bool? active;
  final bool? debug;
  final VoidCallback onPressed;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Duration? duration;
  final Curve? curve;
  final Gradient? gradient;
  final BorderRadius? borderRadius;
  final Border? border;
  final Border? activeBorder;
  final List<BoxShadow>? shadow;
  final GnavStyle? style;
  final double? textSize;

  @override
  _ButtonState createState() => _ButtonState();
}

class _ButtonState extends State<Button> with TickerProviderStateMixin {
  late bool _expanded;
  late final AnimationController expandController;

  @override
  void initState() {
    super.initState();
    _expanded = widget.active!;

    expandController =
        AnimationController(vsync: this, duration: widget.duration)
          ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    expandController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var curveValue = expandController
        .drive(CurveTween(
            curve: _expanded ? widget.curve! : widget.curve!.flipped))
        .value;
    var _colorTween =
        ColorTween(begin: widget.iconColor, end: widget.iconActiveColor);
    var _colorTweenAnimation = _colorTween.animate(CurvedAnimation(
        parent: expandController,
        curve: _expanded ? Curves.easeInExpo : Curves.easeOutCirc));

    _expanded = !widget.active!;
    if (_expanded)
      expandController.reverse();
    else
      expandController.forward();

    Widget icon = widget.leading ??
        Icon(widget.icon,
            color: _colorTweenAnimation.value, size: widget.iconSize);

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        highlightColor: widget.hoverColor,
        splashColor: widget.rippleColor,
        borderRadius: widget.borderRadius,
        onTap: widget.onPressed,
        child: Container(
          padding: widget.margin,
          child: AnimatedContainer(
            curve: Curves.easeOut,
            padding: widget.padding,
            duration: widget.duration!,
            decoration: BoxDecoration(
              boxShadow: widget.shadow,
              border: widget.active!
                  ? (widget.activeBorder ?? widget.border)
                  : widget.border,
              gradient: widget.gradient,
              color: _expanded
                  ? widget.color!.withOpacity(0)
                  : widget.debug!
                      ? Colors.red
                      : widget.gradient != null
                          ? Colors.white
                          : widget.color,
              borderRadius: widget.borderRadius,
            ),
            child: FittedBox(
              fit: BoxFit.fitHeight,
              child: Builder(
                builder: (_) {
                  if (widget.style == GnavStyle.google) {
                    return Stack(
                      children: [
                        if (widget.text!.data != '')
                          Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Opacity(
                                  opacity: 0,
                                  child: icon,
                                ),
                                Container(
                                  child: Container(
                                    child: Align(
                                        alignment: Alignment.centerRight,
                                        widthFactor: curveValue,
                                        child: Container(
                                          child: Opacity(
                                              opacity: _expanded
                                                  ? pow(expandController.value,
                                                      13) as double
                                                  : expandController
                                                      .drive(CurveTween(
                                                          curve: Curves.easeIn))
                                                      .value,
                                              child: Padding(
                                                padding: EdgeInsets.only(
                                                    left: widget.gap! +
                                                        8 -
                                                        (8 *
                                                            expandController
                                                                .drive(CurveTween(
                                                                    curve: Curves
                                                                        .easeOutSine))
                                                                .value),
                                                    right: 8 *
                                                        expandController
                                                            .drive(CurveTween(
                                                                curve: Curves
                                                                    .easeOutSine))
                                                            .value),
                                                child: widget.text,
                                              )),
                                        )),
                                  ),
                                ),
                              ]),
                        Align(alignment: Alignment.centerLeft, child: icon),
                      ],
                    );
                  } else if (widget.style == GnavStyle.oldSchool) {
                    return Column(
                      children: [
                        icon,
                        Container(
                          padding: EdgeInsets.only(top: widget.gap!),
                          child: Text(
                            widget.text!.data!,
                            style: TextStyle(
                              color: _colorTweenAnimation.value,
                              fontSize: widget.textSize ?? 16,
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Container();
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
