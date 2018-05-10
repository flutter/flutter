// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

// This demo displays one Category at a time. The backdrop show a list
// of all of the categories and the selected category is displayed
// (CategoryView) on top of the backdrop.

class Category {
  const Category({ this.title, this.assets });
  final String title;
  final List<String> assets;
  @override
  String toString() => '$runtimeType("$title")';
}

const List<Category> allCategories = const <Category>[
  const Category(
    title: 'Home',
    assets: const <String>[
      'shrine/products/clock.png',
      'shrine/products/teapot.png',
      'shrine/products/radio.png',
      'shrine/products/lawn_chair.png',
      'shrine/products/chair.png',
    ],
  ),
  const Category(
    title: 'Red',
    assets: const <String>[
      'shrine/products/popsicle.png',
      'shrine/products/brush.png',
      'shrine/products/lipstick.png',
      'shrine/products/backpack.png',
    ],
  ),
  const Category(
    title: 'Sport',
    assets: const <String>[
      'shrine/products/helmet.png',
      'shrine/products/beachball.png',
      'shrine/products/flippers.png',
      'shrine/products/surfboard.png',
    ],
  ),
  const Category(
    title: 'Shoes',
    assets: const <String>[
      'shrine/products/chucks.png',
      'shrine/products/green-shoes.png',
      'shrine/products/heels.png',
      'shrine/products/flippers.png',
    ],
  ),
  const Category(
    title: 'Vision',
    assets: const <String>[
      'shrine/products/sunnies.png',
      'shrine/products/binoculars.png',
      'shrine/products/fish_bowl.png',
    ],
  ),
  const Category(
    title: 'Everything',
    assets: const <String>[
      'shrine/products/radio.png',
      'shrine/products/sunnies.png',
      'shrine/products/clock.png',
      'shrine/products/popsicle.png',
      'shrine/products/lawn_chair.png',
      'shrine/products/chair.png',
      'shrine/products/heels.png',
      'shrine/products/green-shoes.png',
      'shrine/products/teapot.png',
      'shrine/products/chucks.png',
      'shrine/products/brush.png',
      'shrine/products/fish_bowl.png',
      'shrine/products/lipstick.png',
      'shrine/products/backpack.png',
      'shrine/products/helmet.png',
      'shrine/products/beachball.png',
      'shrine/products/binoculars.png',
      'shrine/products/flippers.png',
      'shrine/products/surfboard.png',
    ],
  ),
];

class CategoryView extends StatelessWidget {
  const CategoryView({ Key key, this.category }) : super(key: key);

  final Category category;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return new ListView(
      key: new PageStorageKey<Category>(category),
      padding: const EdgeInsets.symmetric(
        vertical: 16.0,
        horizontal: 64.0,
      ),
      children: category.assets.map<Widget>((String asset) {
        return new Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            new Card(
              child: new Container(
                width: 144.0,
                alignment: Alignment.center,
                child: new Column(
                  children: <Widget>[
                    new Image.asset(
                      asset,
                      package: 'flutter_gallery_assets',
                      fit: BoxFit.contain,
                    ),
                    new Container(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      alignment: AlignmentDirectional.center,
                      child: new Text(
                        asset,
                        style: theme.textTheme.caption,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24.0),
          ],
        );
      }).toList(),
    );
  }
}

// One BackdropPanel is visible at a time. It's stacked on top of the
// the BackdropDemo.
class BackdropPanel extends StatelessWidget {
  const BackdropPanel({
    Key key,
    this.onTap,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
    this.title,
    this.child,
  }) : super(key: key);

  final VoidCallback onTap;
  final GestureDragUpdateCallback onVerticalDragUpdate;
  final GestureDragEndCallback onVerticalDragEnd;
  final Widget title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return new Material(
      elevation: 2.0,
      borderRadius: const BorderRadius.only(
        topLeft: const Radius.circular(16.0),
        topRight: const Radius.circular(16.0),
      ),
      child: new Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          new GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: onVerticalDragUpdate,
            onVerticalDragEnd: onVerticalDragEnd,
            onTap: onTap,
            child: new Container(
              height: 48.0,
              padding: const EdgeInsetsDirectional.only(start: 16.0),
              alignment: AlignmentDirectional.centerStart,
              child: new DefaultTextStyle(
                style: theme.textTheme.subhead,
                child: new Tooltip(
                  message: 'Tap to dismiss',
                  child: title,
                ),
              ),
            ),
          ),
          const Divider(height: 1.0),
          new Expanded(child: child),
        ],
      ),
    );
  }
}

// Cross fades between 'Select a Category' and 'Asset Viewer'.
class BackdropTitle extends AnimatedWidget {
  const BackdropTitle({
    Key key,
    Listenable listenable,
  }) : super(key: key, listenable: listenable);

  @override
  Widget build(BuildContext context) {
    final Animation<double> animation = listenable;
    return new DefaultTextStyle(
      style: Theme.of(context).primaryTextTheme.title,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      child: new Stack(
        children: <Widget>[
          new Opacity(
            opacity: new CurvedAnimation(
              parent: new ReverseAnimation(animation),
              curve: const Interval(0.5, 1.0),
            ).value,
            child: const Text('Select a Category'),
          ),
          new Opacity(
            opacity: new CurvedAnimation(
              parent: animation,
              curve: const Interval(0.5, 1.0),
            ).value,
            child: const Text('Asset Viewer'),
          ),
        ],
      ),
    );
  }
}

// This widget is essentially the backdrop itself.
class BackdropDemo extends StatefulWidget {
  static const String routeName = '/material/backdrop';

  @override
  _BackdropDemoState createState() => new _BackdropDemoState();
}

class _BackdropDemoState extends State<BackdropDemo> with SingleTickerProviderStateMixin {
  final GlobalKey _backdropKey = new GlobalKey(debugLabel: 'Backdrop');
  AnimationController _controller;
  Category _category = allCategories[0];

  @override
  void initState() {
    super.initState();
    _controller = new AnimationController(
      duration: const Duration(milliseconds: 300),
      value: 1.0,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _changeCategory(Category category) {
    setState(() {
      _category = category;
      _controller.fling(velocity: 2.0);
    });
  }

  bool get _backdropPanelVisible {
    final AnimationStatus status = _controller.status;
    return status == AnimationStatus.completed || status == AnimationStatus.forward;
  }

  void _toggleBackdropPanelVisibility() {
    _controller.fling(velocity: _backdropPanelVisible ? -2.0 : 2.0);
  }

  double get _backdropHeight {
    final RenderBox renderBox = _backdropKey.currentContext.findRenderObject();
    return renderBox.size.height;
  }

  // By design: the panel can only be opened with a swipe. To close the panel
  // the user must either tap its heading or the backdrop's menu icon.

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_controller.isAnimating || _controller.status == AnimationStatus.completed)
      return;

    _controller.value -= details.primaryDelta / (_backdropHeight ?? details.primaryDelta);
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_controller.isAnimating || _controller.status == AnimationStatus.completed)
      return;

    final double flingVelocity = details.velocity.pixelsPerSecond.dy / _backdropHeight;
    if (flingVelocity < 0.0)
      _controller.fling(velocity: math.max(2.0, -flingVelocity));
    else if (flingVelocity > 0.0)
      _controller.fling(velocity: math.min(-2.0, -flingVelocity));
    else
      _controller.fling(velocity: _controller.value < 0.5 ? -2.0 : 2.0);
  }

  // Stacks a BackdropPanel, which displays the selected category, on top
  // of the backdrop. The categories are displayed with ListTiles. Just one
  // can be selected at a time. This is a LayoutWidgetBuild function because
  // we need to know how big the BackdropPanel will be to set up its
  // animation.
  Widget _buildStack(BuildContext context, BoxConstraints constraints) {
    const double panelTitleHeight = 48.0;
    final Size panelSize = constraints.biggest;
    final double panelTop = panelSize.height - panelTitleHeight;

    final Animation<RelativeRect> panelAnimation = new RelativeRectTween(
      begin: new RelativeRect.fromLTRB(
        0.0,
        panelTop - MediaQuery.of(context).padding.bottom,
        0.0,
        panelTop - panelSize.height,
      ),
      end: const RelativeRect.fromLTRB(0.0, 0.0, 0.0, 0.0),
    ).animate(
      new CurvedAnimation(
        parent: _controller,
        curve: Curves.linear,
      ),
    );

    final ThemeData theme = Theme.of(context);
    final List<Widget> backdropItems = allCategories.map<Widget>((Category category) {
      final bool selected = category == _category;
      return new Material(
        shape: const RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(const Radius.circular(4.0)),
        ),
        color: selected
          ? Colors.white.withOpacity(0.25)
          : Colors.transparent,
        child: new ListTile(
          title: new Text(category.title),
          selected: selected,
          onTap: () {
            _changeCategory(category);
          },
        ),
      );
    }).toList();

    return new Container(
      key: _backdropKey,
      color: theme.primaryColor,
      child: new Stack(
        children: <Widget>[
          new ListTileTheme(
            iconColor: theme.primaryIconTheme.color,
            textColor: theme.primaryTextTheme.title.color.withOpacity(0.6),
            selectedColor: theme.primaryTextTheme.title.color,
            child: new Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: new Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: backdropItems,
              ),
            ),
          ),
          new PositionedTransition(
            rect: panelAnimation,
            child: new BackdropPanel(
              onTap: _toggleBackdropPanelVisibility,
              onVerticalDragUpdate: _handleDragUpdate,
              onVerticalDragEnd: _handleDragEnd,
              title: new Text(_category.title),
              child: new CategoryView(category: _category),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        elevation: 0.0,
        title: new BackdropTitle(
          listenable: _controller.view,
        ),
        actions: <Widget>[
          new IconButton(
            onPressed: _toggleBackdropPanelVisibility,
            icon: new AnimatedIcon(
              icon: AnimatedIcons.close_menu,
              progress: _controller.view,
            ),
          ),
        ],
      ),
      body: new LayoutBuilder(
        builder: _buildStack,
      ),
    );
  }
}
