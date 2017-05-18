import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
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
  static const String _channel = "samples.flutter.io/full_screen";
  static const BasicMessageChannel<String> platform =
      const BasicMessageChannel<String>(_channel, const StringCodec());
  static const MethodChannel _methodChannel =
      const MethodChannel("samples.flutter.io/full");

  int _counter = 0;

  @override
  void initState() {
    super.initState();
    platform.setMessageHandler(_handlePlatformCount);
  }

  Future<String> _handlePlatformCount(String message) async {
    print("WE ARE BACK $message");
    setState(() {
      _counter += int.parse(message);
    });
    return "";
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  Future<Null> _launchPlatformCount() async {
  final int countDelta = await _methodChannel.invokeMethod("launch", _counter);
  setState((){
    _counter = countDelta;
  });
//    platform.send("launch full screen");
  }

  @override
  Widget build(BuildContext context) => new Scaffold(
        appBar: new AppBar(
          title: new Text(widget.title),
        ),
        body: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new Expanded(
              child: new Center(
                  child: new Text(
                      'Platform button tapped $_counter time${ _counter == 1 ? '' : 's' }.',
                      style: const TextStyle(fontSize: 17.0))),
            ),
            new Padding(
              padding: const EdgeInsets.all(18.0),
              child: new RaisedButton(
                  child: new Text('Launch full screen platform view'),
                  onPressed: _launchPlatformCount),
            ),
          ],
        ),
        floatingActionButton: new FloatingActionButton(
          onPressed: _incrementCounter,
          tooltip: 'Increment',
          child: new Icon(Icons.add),
        ),
      );
}
