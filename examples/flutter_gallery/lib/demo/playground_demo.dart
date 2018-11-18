import 'package:flutter/material.dart';

import 'playground/home.dart';

class MaterialPlaygroundDemo extends StatelessWidget {
  const MaterialPlaygroundDemo({Key key}) : super(key: key);

  static const String routeName = '/playground/material';

  static WidgetBuilder buildRoute() {
    return (BuildContext context) => const MaterialPlaygroundDemo();
  }

  @override
  Widget build(BuildContext context) => const PlaygroundPage(
      title: 'Material Widget Playground', type: 'material');
}

class CupertinoPlaygroundDemo extends StatelessWidget {
  const CupertinoPlaygroundDemo({Key key}) : super(key: key);

  static const String routeName = '/playground/cupertino';

  static WidgetBuilder buildRoute() {
    return (BuildContext context) => const CupertinoPlaygroundDemo();
  }

  @override
  Widget build(BuildContext context) => const PlaygroundPage(
      title: 'Cupertino Widget Playground', type: 'cupertino');
}
