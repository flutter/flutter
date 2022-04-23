// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for ErrorWidget

import 'package:flutter/material.dart';

void main() {
  // Set the ErrorWidget's builder before the app is started.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    // This is how to tell if you're in debug mode: Assertions are only executed in
    // debug mode.
    bool inDebug = false;
    assert(() {
      inDebug = true;
      return true;
    }());
    // If we're in debug mode, use the normal error widget which shows the error
    // message:
    if (inDebug) {
      return ErrorWidget(details.exception);
    }
    // In release builds, show a yellow-on-blue message instead:
    return Container(
      alignment: Alignment.center,
      child: Text(
        'Error!\n${details.exception}',
        style: const TextStyle(color: Colors.yellow),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      ),
    );
  };

  // Start the app.
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  static const String _title = 'ErrorWidget Sample';

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool throwError = false;

  @override
  Widget build(BuildContext context) {
    if (throwError) {
      // Since the error widget is only used during a build, in this contrived example,
      // we purposely throw an exception in a build function.
      return Builder(
        builder: (BuildContext context) {
          throw Exception('oh no, an error');
        },
      );
    } else {
      return MaterialApp(
        title: MyApp._title,
        home: Scaffold(
          appBar: AppBar(title: const Text(MyApp._title)),
          body: Center(
            child: TextButton(
                onPressed: () {
                  setState(() { throwError = true; });
                },
                child: const Text('Error Prone')),
          ),
        ),
      );
    }
  }
}
