// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel = MethodChannel('com.example.abstract_method_smoke_test');
  await channel.invokeMethod<void>('show_keyboard');
  runApp(const MyApp());
  print('Test succeeded');
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  @override
  void initState() {
    super.initState();

    // Trigger the second route.
    // https://github.com/flutter/flutter/issues/40126
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const SecondPage()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}

class SecondPage extends StatelessWidget {
  const SecondPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: const <Widget>[
          Expanded(
            child: AndroidView(viewType: 'simple')
          ),
        ],
      ),
    );
  }
}
