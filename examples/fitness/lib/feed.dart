// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of fitness;

class FitnessItemList extends StatelessComponent {
  FitnessItemList({ Key key, this.items, this.onDismissed }) : super(key: key) {
    assert(items != null);
    assert(onDismissed != null);
  }

  final List<FitnessItem> items;
  final FitnessItemHandler onDismissed;

  Widget build(BuildContext context) {
    return new ScrollableList<FitnessItem>(
      padding: const EdgeDims.all(4.0),
      items: items,
      itemExtent: kFitnessItemHeight,
      itemBuilder: (_, item) => item.toRow(onDismissed: onDismissed)
    );
  }
}

class DialogMenuItem extends StatelessComponent {
  DialogMenuItem(this.children, { Key key, this.onPressed }) : super(key: key);

  List<Widget> children;
  Function onPressed;

  Widget build(BuildContext context) {
    return new Container(
      height: 48.0,
      child: new InkWell(
        onTap: onPressed,
        child: new Padding(
          padding: const EdgeDims.symmetric(horizontal: 16.0),
          child: new Row(children)
        )
      )
    );
  }
}

class FeedFragment extends StatefulComponent {
  FeedFragment({ this.navigator, this.userData, this.onItemCreated, this.onItemDeleted });

  final NavigatorState navigator;
  final UserData userData;
  final FitnessItemHandler onItemCreated;
  final FitnessItemHandler onItemDeleted;

  FeedFragmentState createState() => new FeedFragmentState();
}

class FeedFragmentState extends State<FeedFragment> {
  final GlobalKey<PlaceholderState> _snackBarPlaceholderKey = new GlobalKey<PlaceholderState>();
  FitnessMode _fitnessMode = FitnessMode.feed;

  void _handleFitnessModeChange(FitnessMode value) {
    setState(() {
      _fitnessMode = value;
    });
    config.navigator.pop();
  }

  void _showDrawer() {
    showDrawer(
      context: context,
      child: new Block([
        new DrawerHeader(child: new Text('Fitness')),
        new DrawerItem(
          icon: 'action/view_list',
          onPressed: () => _handleFitnessModeChange(FitnessMode.feed),
          selected: _fitnessMode == FitnessMode.feed,
          child: new Text('Feed')),
        new DrawerItem(
          icon: 'action/assessment',
          onPressed: () => _handleFitnessModeChange(FitnessMode.chart),
          selected: _fitnessMode == FitnessMode.chart,
          child: new Text('Chart')),
        new DrawerDivider(),
        new DrawerItem(
          icon: 'action/settings',
          onPressed: _handleShowSettings,
          child: new Text('Settings')),
        new DrawerItem(
          icon: 'action/help',
          child: new Text('Help & Feedback'))
      ])
    );
  }

  void _handleShowSettings() {
    config.navigator.pop();
    config.navigator.pushNamed('/settings');
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
        onPressed: _showDrawer),
      center: new Text(fitnessModeTitle)
    );
  }

  void _handleItemDismissed(FitnessItem item) {
    config.onItemDeleted(item);
    showSnackBar(
      context: context,
      placeholderKey: _snackBarPlaceholderKey,
      content: new Text("Item deleted."),
      actions: [new SnackBarAction(label: "UNDO", onPressed: () {
        config.onItemCreated(item);
        config.navigator.pop();
      })]
    );
  }

  Widget buildChart() {
    double startX;
    double endX;
    double startY;
    double endY;
    List<Point> dataSet = new List<Point>();
    for (FitnessItem item in config.userData.items) {
      if (item is Measurement) {
          double x = item.when.millisecondsSinceEpoch.toDouble();
          double y = item.weight;
          if (startX == null || startX > x)
            startX = x;
          if (endX == null || endX < x)
          endX = x;
          if (startY == null || startY > y)
            startY = y;
          if (endY == null || endY < y)
            endY = y;
          dataSet.add(new Point(x, y));
      }
    }
    if (config.userData.goalWeight != null && config.userData.goalWeight > 0.0) {
      startY = math.min(startY, config.userData.goalWeight);
      endY = math.max(endY, config.userData.goalWeight);
    }
    playfair.ChartData data = new playfair.ChartData(
      startX: startX,
      startY: startY,
      endX: endX,
      endY: endY,
      dataSet: dataSet,
      numHorizontalGridlines: 5,
      roundToPlaces: 1,
      indicatorLine: config.userData.goalWeight,
      indicatorText: "GOAL WEIGHT"
    );
    return new playfair.Chart(data: data);
  }

  Widget buildBody() {
    TextStyle style = Theme.of(context).text.title;
    if (config.userData == null)
      return new Container();
    if (config.userData.items.length == 0) {
      return new Row(
        [new Text("No data yet.\nAdd some!", style: style)],
        justifyContent: FlexJustifyContent.center
      );
    }
    switch (_fitnessMode) {
      case FitnessMode.feed:
        return new FitnessItemList(
          items: config.userData.items.reversed.toList(),
          onDismissed: _handleItemDismissed
        );
      case FitnessMode.chart:
        return new Container(
          padding: const EdgeDims.all(20.0),
          child: buildChart()
        );
    }
  }

  void _handleActionButtonPressed() {
    showDialog(context: context, child: new AddItemDialog()).then((routeName) {
      if (routeName != null)
        config.navigator.pushNamed(routeName);
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

  Widget build(BuildContext context) {
    return new Scaffold(
      toolBar: buildToolBar(),
      body: buildBody(),
      snackBar: new Placeholder(key: _snackBarPlaceholderKey),
      floatingActionButton: buildFloatingActionButton()
    );
  }
}

class AddItemDialog extends StatefulComponent {
  AddItemDialogState createState() => new AddItemDialogState();
}

class AddItemDialogState extends State<AddItemDialog> {
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

  Widget build(BuildContext context) {
    List<Widget> menuItems = [];
    for(String routeName in _labels.keys) {
      menuItems.add(new DialogMenuItem([
        new Flexible(child: new Text(_labels[routeName])),
        new Radio(value: routeName, groupValue: _addItemRoute, onChanged: _handleAddItemRouteChanged),
      ], onPressed: () => _handleAddItemRouteChanged(routeName)));
    }
    return new Dialog(
      title: new Text("What are you doing?"),
      content: new Block(menuItems),
      onDismiss: () {
        Navigator.of(context).pop();
      },
      actions: [
        new FlatButton(
          child: new Text('CANCEL'),
          onPressed: () {
            Navigator.of(context).pop();
          }
        ),
        new FlatButton(
          child: new Text('ADD'),
          onPressed: () {
            Navigator.of(context).pop(_addItemRoute);
          }
        ),
      ]
    );
  }
}
