import 'package:flutter/material.dart';

import 'common.dart';
import 'src/cull_opacity.dart';

const String kMacrobenchmarks ='Macrobenchmarks';

void main() => runApp(MacrobenchmarksApp());

class MacrobenchmarksApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kMacrobenchmarks,
      initialRoute: '/',
      routes: <String, WidgetBuilder>{
        '/': (BuildContext context) => HomePage(),
        kCullOpacityRouteName: (BuildContext context) => CullOpacityPage(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(kMacrobenchmarks)),
      body: ListView(
        children: <Widget>[
          RaisedButton(
            key: const Key(kCullOpacityRouteName),
            child: const Text('Cull opacity'),
            onPressed: (){
              Navigator.pushNamed(context, kCullOpacityRouteName);
            },
          )
        ],
      ),
    );
  }
}
