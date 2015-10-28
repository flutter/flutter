import 'package:flutter/material.dart';

void main() {
  runApp(
    new MaterialApp(
      title: "Media Query Example",
      routes: <String, RouteBuilder>{
        '/': (RouteArguments args) => new MediaQueryExample()
      }
    )
  );
}

class AdaptiveItem {
  AdaptiveItem(this.name);
  String name;

  Widget toListItem() {
    return new Row(
      <Widget>[
        new Container(
          width: 32.0,
          height: 32.0,
          margin: const EdgeDims.all(8.0),
          decoration: new BoxDecoration(
            backgroundColor: Colors.lightBlueAccent[100]
          )
        ),
        new Text(name)
      ]
    );
  }

  Widget toCard() {
    return new Card(
      child: new Column(
        <Widget>[
          new Flexible(
            child: new Container(
              decoration: new BoxDecoration(
                backgroundColor: Colors.lightBlueAccent[100]
              )
            )
          ),
          new Container(
            margin: const EdgeDims.only(left: 8.0),
            child: new Row(
              <Widget>[
                new Flexible(
                  child: new Text(name)
                ),
                new IconButton(
                  icon: "navigation/more_vert"
                )
              ]
            )
          )
        ]
      )
    );
  }
}

class MediaQueryExample extends StatelessComponent {
  static const double _maxChildExtent = 150.0;
  static const double _gridViewBreakpoint = 450.0;

  Widget _buildBody(BuildContext context) {
    List<AdaptiveItem> items = <AdaptiveItem>[];

    for (int i = 0; i < 30; i++)
      items.add(new AdaptiveItem("Item $i"));

    if (MediaQuery.of(context).size.width < _gridViewBreakpoint) {
      return new Block(
        items.map((AdaptiveItem item) => item.toListItem()).toList()
      );
    } else {
      return new Block(
        <Widget>[
          new Grid(
            items.map((AdaptiveItem item) => item.toCard()).toList(),
            maxChildExtent: _maxChildExtent
          )
        ]
      );
    }
  }

  Widget build(BuildContext context)  {
    return new Scaffold(
      toolBar: new ToolBar(
        center: new Text("Media Query Example")
      ),
      body: new Material(
        child: _buildBody(context)
      )
    );
  }
}
