// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of fitness;

class FitnessItemList extends Component {
  FitnessItemList({ Key key, this.items, this.onDismissed }) : super(key: key) {
    assert(items != null);
    assert(onDismissed != null);
  }

  final List<FitnessItem> items;
  final FitnessItemHandler onDismissed;

  Widget build() {
    return new Material(
      type: MaterialType.canvas,
      child: new ScrollableList<FitnessItem>(
        padding: const EdgeDims.all(4.0),
        items: items,
        itemHeight: kFitnessItemHeight,
        itemBuilder: (item) => item.toRow(onDismissed: onDismissed)
      )
    );
  }
}

class DialogMenuItem extends ButtonBase {
  DialogMenuItem(this.children, { Key key, this.onPressed }) : super(key: key);

  List<Widget> children;
  Function onPressed;

  void syncFields(DialogMenuItem source) {
    children = source.children;
    onPressed = source.onPressed;
    super.syncFields(source);
  }

  Widget buildContent() {
    return new Listener(
      onGestureTap: (_) {
        if (onPressed != null)
          onPressed();
      },
      child: new Container(
        height: 48.0,
        child: new InkWell(
          child: new Padding(
            padding: const EdgeDims.symmetric(horizontal: 16.0),
            child: new Flex(children)
          )
        )
      )
    );
  }
}

class FeedFragment extends StatefulComponent {
  FeedFragment({ this.navigator, this.userData, this.onItemCreated, this.onItemDeleted });

  Navigator navigator;
  List<FitnessItem> userData;
  FitnessItemHandler onItemCreated;
  FitnessItemHandler onItemDeleted;

  FitnessMode _fitnessMode = FitnessMode.feed;

  void initState() {
    // if (debug)
    //   new Timer(new Duration(seconds: 1), dumpState);
    super.initState();
  }

  void syncFields(FeedFragment source) {
    navigator = source.navigator;
    userData = source.userData;
    onItemCreated = source.onItemCreated;
    onItemDeleted = source.onItemDeleted;
  }

  AnimationStatus _snackBarStatus = AnimationStatus.dismissed;
  bool _isShowingSnackBar = false;

  EventDisposition _handleFitnessModeChange(FitnessMode value) {
    setState(() {
      _fitnessMode = value;
      _drawerShowing = false;
    });
    return EventDisposition.processed;
  }

  Drawer buildDrawer() {
    if (_drawerStatus == AnimationStatus.dismissed)
      return null;
    return new Drawer(
      showing: _drawerShowing,
      level: 3,
      onDismissed: _handleDrawerDismissed,
      navigator: navigator,
      children: [
        new DrawerHeader(children: [new Text('Fitness')]),
        new DrawerItem(
          icon: 'action/view_list',
          onPressed: () => _handleFitnessModeChange(FitnessMode.feed),
          selected: _fitnessMode == FitnessMode.feed,
          children: [new Text('Feed')]),
        new DrawerItem(
          icon: 'action/assessment',
          onPressed: () => _handleFitnessModeChange(FitnessMode.chart),
          selected: _fitnessMode == FitnessMode.chart,
          children: [new Text('Chart')]),
        new DrawerDivider(),
        new DrawerItem(
          icon: 'action/settings',
          onPressed: _handleShowSettings,
          children: [new Text('Settings')]),
        new DrawerItem(
          icon: 'action/help',
          children: [new Text('Help & Feedback')])
     ]
    );
  }

  bool _drawerShowing = false;
  AnimationStatus _drawerStatus = AnimationStatus.dismissed;

  void _handleOpenDrawer() {
    setState(() {
      _drawerShowing = true;
      _drawerStatus = AnimationStatus.forward;
    });
  }

  void _handleDrawerDismissed() {
    setState(() {
      _drawerStatus = AnimationStatus.dismissed;
    });
  }

  EventDisposition _handleShowSettings() {
    navigator.pop();
    navigator.pushNamed('/settings');
    return EventDisposition.processed;
  }

  // TODO(jackson): We should be localizing
  String get fitnessModeTitle {
    switch(_fitnessMode) {
      case FitnessMode.feed: return "Feed";
      case FitnessMode.chart: return "Chart";
    }
  }

  Widget buildToolBar() {
    return new ToolBar(
      left: new IconButton(
        icon: "navigation/menu",
        onPressed: _handleOpenDrawer),
      center: new Text(fitnessModeTitle)
    );
  }

  FitnessItem _undoItem;

  void _handleItemDismissed(FitnessItem item) {
    onItemDeleted(item);
    setState(() {
      _undoItem = item;
      _isShowingSnackBar = true;
      _snackBarStatus = AnimationStatus.forward;
    });
  }

  Widget buildBody() {
    TextStyle style = Theme.of(this).text.title;
    switch (_fitnessMode) {
      case FitnessMode.feed:
        if (userData.length > 0)
          return new FitnessItemList(
            items: userData,
            onDismissed: _handleItemDismissed
          );
        return new Material(
          type: MaterialType.canvas,
          child: new Flex(
            [new Text("No data yet.\nAdd some!", style: style)],
            justifyContent: FlexJustifyContent.center
          )
        );
      case FitnessMode.chart:
        return new Material(
          type: MaterialType.canvas,
          child: new Flex([
            new Text("Charts are coming soon!", style: style)
          ], justifyContent: FlexJustifyContent.center)
        );
    }
  }

  void _handleUndo() {
    onItemCreated(_undoItem);
    setState(() {
      _undoItem = null;
      _isShowingSnackBar = false;
    });
  }

  Anchor _snackBarAnchor = new Anchor();
  Widget buildSnackBar() {
    if (_snackBarStatus == AnimationStatus.dismissed)
      return null;
    return new SnackBar(
      showing: _isShowingSnackBar,
      anchor: _snackBarAnchor,
      content: new Text("Item deleted."),
      actions: [new SnackBarAction(label: "UNDO", onPressed: _handleUndo)],
      onDismissed: () { setState(() { _snackBarStatus = AnimationStatus.dismissed; }); }
    );
  }

  void _handleActionButtonPressed() {
    showDialog(navigator, (navigator) => new AddItemDialog(navigator)).then((routeName) {
      if (routeName != null)
        navigator.pushNamed(routeName);
    });
  }

  Widget buildFloatingActionButton() {
    switch (_fitnessMode) {
      case FitnessMode.feed:
        return _snackBarAnchor.build(
          new FloatingActionButton(
            child: new Icon(type: 'content/add', size: 24),
            onPressed: _handleActionButtonPressed
          ));
      case FitnessMode.chart:
        return null;
    }
  }

  Widget build() {
    return new Scaffold(
      toolbar: buildToolBar(),
      body: buildBody(),
      snackBar: buildSnackBar(),
      floatingActionButton: buildFloatingActionButton(),
      drawer: buildDrawer()
    );
  }
}

class AddItemDialog extends StatefulComponent {
  AddItemDialog(this.navigator);

  Navigator navigator;

  void syncFields(AddItemDialog source) {
    this.navigator = source.navigator;
  }

  // TODO(jackson): Internationalize
  static final Map<String, String> _labels = {
    '/measurements/new': 'Measure',
    '/meals/new': 'Eat',
  };

  String _addItemRoute = _labels.keys.first;

  void _handleAddItemRouteChanged(String routeName) {
    setState(() {
        _addItemRoute = routeName;
    });
  }

  Widget build() {
    List<Widget> menuItems = [];
    for(String routeName in _labels.keys) {
      menuItems.add(new DialogMenuItem([
        new Flexible(child: new Text(_labels[routeName])),
        new Radio(value: routeName, groupValue: _addItemRoute, onChanged: _handleAddItemRouteChanged),
      ], onPressed: () => _handleAddItemRouteChanged(routeName)));
    }
    return new Dialog(
      title: new Text("What are you doing?"),
      content: new ScrollableBlock(menuItems),
      onDismiss: navigator.pop,
      actions: [
        new FlatButton(
          child: new Text('CANCEL'),
          onPressed: navigator.pop
        ),
        new FlatButton(
          child: new Text('ADD'),
          onPressed: () {
            navigator.pop(_addItemRoute);
          }
        ),
      ]
    );
  }
}
