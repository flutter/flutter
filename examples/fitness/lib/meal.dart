// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of fitness;

class Meal extends FitnessItem {
  Meal({ DateTime when, this.description }) : super(when: when);

  final String description;

  FitnessItemRow toRow({ FitnessItemHandler onDismissed }) {
    return new MealRow(meal: this, onDismissed: onDismissed);
  }
}

class MealRow extends FitnessItemRow {
  MealRow({ Meal meal, FitnessItemHandler onDismissed })
    : super(item: meal, onDismissed: onDismissed);

  Widget buildContent() {
    Meal meal = item;
    List<Widget> children = [
      new Flexible(
        child: new Text(
          meal.description,
          style: const TextStyle(textAlign: TextAlign.right)
        )
      ),
      new Flexible(
        child: new Text(
          meal.displayDate,
          style: Theme.of(this).text.caption.copyWith(textAlign: TextAlign.right)
        )
      )
    ];
    return new Flex(
      children,
      alignItems: FlexAlignItems.baseline,
      textBaseline: DefaultTextStyle.of(this).textBaseline
    );
  }
}

class MealFragment extends StatefulComponent {

  MealFragment({ this.navigator, this.onCreated });

  Navigator navigator;
  FitnessItemHandler onCreated;

  void syncFields(MealFragment source) {
    navigator = source.navigator;
    onCreated = source.onCreated;
  }

  String _description = "";

  EventDisposition _handleSave() {
    onCreated(new Meal(when: new DateTime.now(), description: _description));
    navigator.pop();
    return EventDisposition.processed;
  }

  Widget buildToolBar() {
    return new ToolBar(
      left: new IconButton(
        icon: "navigation/close",
        onPressed: navigator.pop),
      center: new Text('New Meal'),
      right: [new InkWell(
        child: new Listener(
          onGestureTap: (_) => _handleSave(),
          child: new Text('SAVE')
        )
      )]
    );
  }

  void _handleDescriptionChanged(String description) {
    setState(() {
      _description = description;
    });
  }

  static final GlobalKey descriptionKey = new GlobalKey();

  Widget buildBody() {
    Meal meal = new Meal(when: new DateTime.now());
    return new Material(
      type: MaterialType.canvas,
      child: new ScrollableViewport(
        child: new Container(
          padding: const EdgeDims.all(20.0),
          child: new Block([
            new Text(meal.displayDate),
            new Input(
              key: descriptionKey,
              placeholder: 'Describe meal',
              onChanged: _handleDescriptionChanged
            ),
          ])
        )
      )
    );
  }

  Widget build() {
    return new Scaffold(
      toolbar: buildToolBar(),
      body: buildBody()
    );
  }
}
