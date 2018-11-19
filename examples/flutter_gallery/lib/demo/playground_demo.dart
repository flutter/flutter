import 'package:flutter/material.dart';

import 'playground/home.dart';
import 'playground/material/material.dart';

class MaterialPlaygroundDemo extends StatelessWidget {
  const MaterialPlaygroundDemo({Key key}) : super(key: key);

  static const String routeName = '/playground/material';

  static WidgetBuilder buildRoute() {
    return (BuildContext context) => MaterialPlaygroundDemo();
  }

  @override
  Widget build(BuildContext context) {
    return PlaygroundPage(
      title: 'Material Widget Playground',
      demos: <PlaygroundDemo>[
        PlaygroundDemo(
          tabName: 'RAISEDBUTTON',
          demoWidget: const MaterialRaisedButtonDemo(),
        ),
        PlaygroundDemo(
          tabName: 'FLATBUTTON',
          demoWidget: Center(child: Text('FlatButton')),
        ),
        PlaygroundDemo(
          tabName: 'ICONBUTTON',
          demoWidget: Center(child: Text('IconButton')),
        ),
        PlaygroundDemo(
          tabName: 'CHECKBOX',
          demoWidget: Center(child: Text('CheckBox')),
        ),
        PlaygroundDemo(
          tabName: 'SWITCH',
          demoWidget: Center(child: Text('Switch')),
        ),
        PlaygroundDemo(
          tabName: 'SLIDER',
          demoWidget: Center(child: Text('Slider')),
        ),
      ]
    );
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
      ]
    );
  }
}
