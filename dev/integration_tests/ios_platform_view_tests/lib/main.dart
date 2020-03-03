import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';

void main() {
  enableFlutterDriverExtension();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: FlatButton(
          key: const ValueKey('platform_view_button'),
          child: Text('platform view'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PlatformViewPage()),
            );
          },
        ),
      ),
    );
  }
}

class PlatformViewPage extends StatefulWidget {
  @override
  _PlatformViewPageState createState() => _PlatformViewPageState();
}

class _PlatformViewPageState extends State<PlatformViewPage> {
  int numberOfTaps = 0;
  String text = 'xxx';
  final Key button = ValueKey('plus_button');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Platform View'),
      ),
      body: Column(
        children: <Widget>[
          Container(
            child: UiKitView(viewType: 'platform_view'),
            width: 300,
            height: 300,
          ),
          Text('$numberOfTaps'),
          RaisedButton(
            key: button,
            child: Text('button'),
            onPressed: () {
              setState(() {
                ++numberOfTaps;
              });
            },
          )
        ],
      ),
    );
  }
}
