import 'package:flutter/material.dart';

import 'playground/cupertino/cupertino.dart';
import 'playground/material/material.dart';
import 'playground/playground.dart';

class MaterialPlaygroundDemo extends StatelessWidget {
  const MaterialPlaygroundDemo({Key key}) : super(key: key);

  static const String routeName = '/playground/material';

  static WidgetBuilder buildRoute() {
    return (BuildContext context) => const MaterialPlaygroundDemo();
  }

  @override
  Widget build(BuildContext context) {
    return PlaygroundPage(
        title: 'Material Widget Playground',
        demos: <PlaygroundDemo>[
          RaisedButtonDemo(),
          RaisedButtonDemo(),
        ]);
  }
}

class CupertinoPlaygroundDemo extends StatelessWidget {
  const CupertinoPlaygroundDemo({Key key}) : super(key: key);

  static const String routeName = '/playground/cupertino';

  static WidgetBuilder buildRoute() {
    return (BuildContext context) => const CupertinoPlaygroundDemo();
  }

  @override
  Widget build(BuildContext context) {
    return PlaygroundPage(
        title: 'Cupertino Widget Playground',
        demos: <PlaygroundDemo>[
          PlaygroundDemo(
            tabName: 'CUPERTINOBUTTON',
            demoWidget: Center(child: Text('CupertinoButton')),
          ),
          PlaygroundDemo(
            tabName: 'CUPERTINOSEGMENTCONTROL',
            demoWidget: Center(child: Text('CupetinoSegmentControl')),
          ),
          PlaygroundDemo(
            tabName: 'CUPERTINOSLIDER',
            demoWidget: Center(child: Text('CupertinoSlider')),
          ),
          PlaygroundDemo(
            tabName: 'CUPERTINOSWITCH',
            demoWidget: Center(child: Text('CupertinoSwitch')),
          ),
        ]);
  }
}
