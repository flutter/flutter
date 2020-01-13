import 'package:flutter/material.dart';

/// Defines the behavior of the labels of a [NavigationRail].
///
/// See also:
///   [NavigationRail]
enum NavigationRailLabelType {
  /// Only the icons of a navigation rail item are shown.
  NoLabels,

  /// Only the selected navigation rail item will show its label.
  ///
  /// The label will animate in and out as new items are selected.
  SelectedLabels,

  /// All navigation rail items will show their label.
  AllLabels,
}

class NavigationRail extends StatefulWidget {
  NavigationRail({
    this.leading,
    this.items,
    this.currentIndex,
    this.onItemSelected,
    this.labelType = NavigationRailLabelType.NoLabels,
    this.labelTextStyle,
    this.labelIconTheme,
    this.selectedLabelTextStyle,
    this.selectedLabelIconTheme,
  });

  final Widget leading;
  final List<BottomNavigationBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onItemSelected;
  final NavigationRailLabelType labelType;
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
        vsync: this,
      )..addListener(_rebuild);
    });
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
    final Widget leading = widget.leading;
    return DefaultTextStyle(
      style: TextStyle(color: Theme.of(context).colorScheme.primary),
      child: Container(
        width: _railWidth,
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _verticalSpacing,
            if (leading != null)
              ...<Widget>[
                SizedBox(
                  height: _railItemHeight,
                  width: _railItemWidth,
                  child: Align(
                    alignment: Alignment.center,
                    child: leading,
                  ),
                ),
                _verticalSpacing,
              ],
            for (int i = 0; i < widget.items.length; i++)
              _RailItem(
                animation: _animations[i],
                labelKind: widget.labelType,
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
                  widget.onItemSelected(i);
                },
              ),
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
  }) : assert(labelKind != null) {
    _positionAnimation = CurvedAnimation(
      parent: ReverseAnimation(animation),
      curve: Curves.easeInOut,
      reverseCurve: Curves.easeInOut.flipped,
    );
  }

  Animation<double> _positionAnimation;

  final Animation<double> animation;
  final NavigationRailLabelType labelKind;
  final bool selected;
  final Widget icon;
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
    print('_RailItem build');
    Widget content;
    switch (labelKind) {
      case NavigationRailLabelType.NoLabels:
        print('NoLabels');
        content = SizedBox(width: _railItemWidth, child: icon);
        break;
      case NavigationRailLabelType.SelectedLabels:
        print('SelectedLabels');
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
      case NavigationRailLabelType.AllLabels:
        print('AllLabels');
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

const double _railWidth = 72;
const double _railItemWidth = _railWidth;
const double _railItemHeight = _railItemWidth;
const double _spacing = 8;
const Widget _verticalSpacing = SizedBox(height: _spacing);