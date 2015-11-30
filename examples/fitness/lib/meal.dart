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

  Widget buildContent(BuildContext context) {
    Meal meal = item;
    List<Widget> children = <Widget>[
      new Flexible(
        child: new Text(
          meal.description,
          style: const TextStyle(textAlign: TextAlign.right)
        )
      ),
      new Flexible(
        child: new Text(
          meal.displayDate,
          style: Theme.of(context).text.caption.copyWith(textAlign: TextAlign.right)
        )
      )
    ];
    return new Row(
      children,
      alignItems: FlexAlignItems.baseline,
      textBaseline: DefaultTextStyle.of(context).textBaseline
    );
  }
}

class MealFragment extends StatefulComponent {
  MealFragment({ this.onCreated });

  FitnessItemHandler onCreated;

  MealFragmentState createState() => new MealFragmentState();
}

class MealFragmentState extends State<MealFragment> {
  String _description = "";

  void _handleSave() {
    config.onCreated(new Meal(when: new DateTime.now(), description: _description));
    Navigator.pop(context);
  }

  Widget buildToolBar() {
    return new ToolBar(
      left: new IconButton(
        icon: "navigation/close",
        onPressed: () => Navigator.pop(context)
      ),
      center: new Text('New Meal'),
      right: <Widget>[
        // TODO(abarth): Should this be a FlatButton?
        new InkWell(
          onTap: _handleSave,
          child: new Text('SAVE')
        )
      ]
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
    return new Block(<Widget>[
        new Text(meal.displayDate),
        new Input(
          key: descriptionKey,
          placeholder: 'Describe meal',
          onChanged: _handleDescriptionChanged
        ),
      ],
      padding: const EdgeDims.all(20.0)
    );
  }

  Widget build(BuildContext context) {
    return new Scaffold(
      toolBar: buildToolBar(),
      body: buildBody()
    );
  }
}
