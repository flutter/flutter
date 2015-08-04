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
      onStatusChanged: _handleDrawerStatusChange,
      navigator: navigator,
      children: [
        new DrawerHeader(children: [new Text('Fitness')]),
        new DrawerItem(
          icon: 'action/list',
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

  void _handleDrawerStatusChange(AnimationStatus status) {
    setState(() {
      _drawerStatus = status;
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

  Widget buildSnackBar() {
    if (!_isShowingSnackBar)
      return null;
    return new SnackBar(
      showing: _isShowingSnackBar,
      content: new Text("Item deleted."),
      actions: [new SnackBarAction(label: "UNDO", onPressed: _handleUndo)]
    );
  }

  void _handleActionButtonPressed() {
    showDialog(navigator, (navigator) => new AddItemDialog(navigator)).then((route) {
      navigator.pushNamed(route);
    });
  }

  Widget buildFloatingActionButton() {
    switch (_fitnessMode) {
      case FitnessMode.feed:
        return new FloatingActionButton(
          child: new Icon(type: 'content/add', size: 24),
          onPressed: _handleActionButtonPressed
        );
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

  String _addItemRoute;

  void _handleAddItemRouteChanged(String routeName) {
    setState(() {
        _addItemRoute = routeName;
    });
  }

  Widget build() {
    // TODO(jackson): Internationalize
    Map<String, String> labels = {
      '/meals/new': 'Eat',
      '/measurements/new': 'Measure',
    };
    List<Widget> menuItems = [];
    for(String routeName in labels.keys) {
      menuItems.add(new DialogMenuItem([
        new Flexible(child: new Text(labels[routeName])),
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
