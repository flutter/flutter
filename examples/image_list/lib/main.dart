// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/services.dart';

/// An example that sets up local http server for serving single
/// image, creates single flutter widget with five copies of requested
/// image and prints how long the loading took.
///
/// This is used in [$FH/flutter/devicelab/bin/tasks/image_list_reported_duration.dart] test.
Future<void> main() async {
  final HttpServer httpServer =
      await HttpServer.bind(InternetAddress.anyIPv6, 0);
  final int port = httpServer.port;
  print('Listening on port $port.');

  httpServer.listen((HttpRequest request) async {
    final ByteData byteData = await rootBundle.load('images/coast.jpg');
    request.response.add(byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    request.response.close();
  });

  runApp(MyApp(port));
}

@immutable
class MyApp extends StatelessWidget {
  const MyApp(this.port);

  final int port;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page', port: port),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key key, this.title, this.port}) : super(key: key);
  final String title;
  final int port;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  Widget createImage(final int index, final Completer<bool> completer) {
    return Flexible(
      fit: FlexFit.tight,
      flex: index,
      child: Image.network(
        'http://localhost:${widget.port}/${_counter * 5 + index}',
        frameBuilder: (
          BuildContext context,
          Widget child,
          int frame,
          bool wasSynchronouslyLoaded,
        ) {
          if (frame == 0 && !completer.isCompleted) {
            completer.complete(true);
          }
          return child;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Completer<bool> completer1 = Completer<bool>();
    final Completer<bool> completer2 = Completer<bool>();
    final Completer<bool> completer3 = Completer<bool>();
    final Completer<bool> completer4 = Completer<bool>();
    final Completer<bool> completer5 = Completer<bool>();
    final DateTime started = DateTime.now();
    Future.wait(<Future<bool>>[
      completer1.future,
      completer2.future,
      completer3.future,
      completer4.future,
      completer5.future
    ]).then((_) {
      print(
          '===image_list=== all loaded in ${DateTime.now().difference(started).inMilliseconds}ms.');
    });
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(children: <Widget>[
              createImage(1, completer1),
              createImage(2, completer2),
              createImage(3, completer3),
              createImage(4, completer4),
              createImage(5, completer5),
            ]),
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.display1,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}
