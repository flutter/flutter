import 'package:flutter/material.dart';

enum NavigationRailLabelKind {
  Regular,
  Impersistent,
  Persistent,
//  Extended,
}

class NavigationRail extends StatefulWidget {
  NavigationRail({
    this.leading,
    this.extendedLeading, // TODO: leading could also be a function that takes in whether its extended or not
    this.items,
    this.actions,
    this.currentIndex,
    this.onNavigationIndexChange,
    this.labelKind = NavigationRailLabelKind.Regular,
    this.labelTextStyle,
    this.labelIconTheme,
    this.selectedLabelTextStyle,
    this.selectedLabelIconTheme,
  });

  final Widget leading;
  final Widget extendedLeading;
  final List<BottomNavigationBarItem> items;
  final List<Widget> actions;
  final int currentIndex;
  final ValueChanged<int> onNavigationIndexChange;

  final NavigationRailLabelKind labelKind;
  final TextStyle labelTextStyle;
  final IconTheme labelIconTheme;
  final TextStyle selectedLabelTextStyle;
  final IconTheme selectedLabelIconTheme;

  @override
  _NavigationRailState createState() => _NavigationRailState();
}

class _NavigationRailState extends State<NavigationRail> with TickerProviderStateMixin {
  List<AnimationController> _controllers = <AnimationController>[];
  List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _resetState();
  }

  void _resetState() {
    for (AnimationController controller in _controllers)
      controller.dispose();

    _controllers = List<AnimationController>.generate(widget.items.length, (int index) {
      return AnimationController(
        duration: kThemeAnimationDuration,
//        duration: Duration(milliseconds: 2000),
        vsync: this,
      )..addListener(_rebuild);
    });
//    _animations = List<CurvedAnimation>.generate(widget.items.length, (int index) {
//      return CurvedAnimation(
//        parent: _controllers[index],
//        curve: Curves.fastOutSlowIn,
//        reverseCurve: Curves.fastOutSlowIn.flipped,
//      );
//    });
    _animations = _controllers.map((AnimationController controller) => controller.view).toList();
    _controllers[widget.currentIndex].value = 1.0;
  }

  void _rebuild() {
    setState(() {
      // Rebuilding when any of the controllers tick, i.e. when the items are
      // animated.
    });
  }

  @override
  void dispose() {
    for (AnimationController controller in _controllers)
      controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(NavigationRail oldWidget) {
    super.didUpdateWidget(oldWidget);

    // No animated segue if the length of the items list changes.
    if (widget.items.length != oldWidget.items.length) {
      _resetState();
      return;
    }

    if (widget.currentIndex != oldWidget.currentIndex) {
      _controllers[oldWidget.currentIndex].reverse();
      _controllers[widget.currentIndex].forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final leading = widget.leading;
    return DefaultTextStyle(
      style: TextStyle(color: Theme.of(context).colorScheme.primary),
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (leading != null)
              SizedBox(
                height: 96,
                width: 72,
                child: Align(
                  alignment: Alignment.center,
                  child: leading,
                ),
              ),
            for (int i = 0; i < widget.items.length; i++)
              _RailItem(
                animation: _animations[i],
                labelKind: widget.labelKind,
                selected: widget.currentIndex == i,
                icon: widget.currentIndex == i
                    ? widget.items[i].activeIcon
                    : widget.items[i].icon,
                title: DefaultTextStyle(
                  style: TextStyle(
                      color: widget.currentIndex == i
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.64)),
                  child: widget.items[i].title,
                ),
                onTap: () {
                  widget.onNavigationIndexChange(i);
                },
              ),
            Spacer(),
            ...widget.actions,
          ],
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  _RailItem({
    this.animation,
    this.labelKind,
    this.selected,
    this.icon,
    this.title,
    this.onTap,
  }) {
    _positionAnimation = CurvedAnimation(
      parent: ReverseAnimation(animation),
      curve: Curves.easeInOut,
      reverseCurve: Curves.easeInOut.flipped,
    );
  }

  Animation _positionAnimation;

  final Animation<double> animation;
  final NavigationRailLabelKind labelKind;
  final bool selected;
  final Icon icon;
  final Widget title;
  final VoidCallback onTap;

  double fadeInValue() {
    if (animation.value < 0.25) {
      return 0;
    } else if (animation.value < 0.75) {
      return (animation.value - 0.25) * 2;
    } else {
      return 1;
    }
  }

  double fadeOutValue() {
    if (animation.value > 0.75) {
      return (animation.value - 0.75) * 4;
    } else {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    switch (labelKind) {
      case NavigationRailLabelKind.Regular:
        content = SizedBox(width: 72, child: icon);
        break;
      case NavigationRailLabelKind.Impersistent:
        content = SizedBox(
          width: 72,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: _positionAnimation.value * 18),
              icon,
              Opacity(
                alwaysIncludeSemantics: true,
                opacity: selected ? fadeInValue() : fadeOutValue(),
                child: title,
              ),
            ],
          ),
        );
        break;
      case NavigationRailLabelKind.Persistent:
        content = SizedBox(
          width: 72,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              icon,
              title,
            ],
          ),
        );
        break;
    }

    final colors = Theme
        .of(context)
        .colorScheme;

    return IconTheme(
      data: IconThemeData(
        color: selected ? colors.primary : colors.onSurface.withOpacity(0.64),
      ),
      child: SizedBox(
        height: 72,
        child: Material(
          type: MaterialType.transparency,
          clipBehavior: Clip.none,
          child: InkResponse(
            onTap: onTap,
            onHover: (_) {},
            splashColor: Theme
                .of(context)
                .colorScheme
                .primary
                .withOpacity(0.12),
            hoverColor: Theme
                .of(context)
                .colorScheme
                .primary
                .withOpacity(0.04),
            child: content,
          ),
        ),
      ),
    );
  }
}