import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final String _CHANNEL = "increment";
final String _EMPTY_MESSAGE = "";

void main() {
  runApp(new FlutterView());
}

class FlutterView extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter View',
      theme: new ThemeData(
        primarySwatch: Colors.grey,
      ),
      home: new MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  Future<String> handleAndroidIncrement(String message) async {
    _incrementCounter();
    return _EMPTY_MESSAGE;
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _sendFlutterIncrement() {
    PlatformMessages.sendString(_CHANNEL, _EMPTY_MESSAGE);
  }

  @override
  Widget build(BuildContext context) {
    PlatformMessages.setStringMessageHandler(_CHANNEL,
                                             handleAndroidIncrement);
    return new Scaffold(
      body: new Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          new Expanded(
            child: new Center(
              child: new Text(
                  'Platform button tapped $_counter time${ _counter == 1 ? '' : 's' }.',
                  style: new TextStyle(fontSize: 17.0))
            ),
          ),
          new Container(
            padding: const EdgeInsets.only(bottom: 15.0, left: 5.0),
            child: new Row(
              children: [
                new Image.asset('assets/flutter-mark-square-64.png', scale: 1.5),
                new Text('Flutter', style: new TextStyle(fontSize: 30.0)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _sendFlutterIncrement,
        child: new Icon(Icons.add),
      ),
    );
  }
}
