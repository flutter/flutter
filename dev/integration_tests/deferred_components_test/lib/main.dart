import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_driver/driver_extension.dart';

import 'component1.dart' deferred as component1;

void main() {
  enableFlutterDriverExtension();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Deferred Components Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Deferred Component'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);

  String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<void>? _libraryFuture;
  Future<void>? _autoLoadFuture;

  Widget postLoadDisplayWidget = Text(
      'placeholder',
      key: Key('PlaceholderText'),
    );

  @override
  void initState() {
    // Automatically trigger load for release test without driver.
    _autoLoadFuture = Future.delayed(Duration(milliseconds: 3000), () {
      _pressHandler();
    });
    super.initState();
  }

  void _pressHandler() {
    if (_libraryFuture == null) {
      setState(() {
        _libraryFuture = component1.loadLibrary().then((_) {
          // Delay to give debug runs more than one frame to capture
          // the placeholder text.
          Future.delayed(Duration(milliseconds: 1000), () {
            setState(() {
              postLoadDisplayWidget = component1.LogoScreen();
            });
          });
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title!),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _libraryFuture == null ? Text('preload', key: Key('PreloadText')) : FutureBuilder<void>(
              future: _libraryFuture,
              builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  return postLoadDisplayWidget;
                }
                return postLoadDisplayWidget;
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        key: Key('FloatingActionButton'),
        onPressed: _pressHandler,
        tooltip: 'Load',
        child: Icon(Icons.add),
      ),
    );
  }
}
