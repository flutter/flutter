// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:record_use_test_package/record_use_test_package.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // For simulating translations, just load the localization before `runApp`
  // without a splash screen. It's pointless to present untranslated strings to
  // the user, and for a test app a splash screen is overkill.
  final String hello = await translate('hello');
  final String friend = await translate('friend');
  // ignore: invalid_use_of_visible_for_testing_member
  final int count = await loadedTranslationsCount();
  // Print for integration test.
  print('HELLO: $hello');
  print('FRIEND: $friend');
  print('COUNT: $count');
  runApp(MyApp(hello: hello, friend: friend, count: count));
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.hello,
    required this.friend,
    required this.count,
  });

  final String hello;
  final String friend;
  final int count;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.deepOrange),
      home: Scaffold(
        appBar: AppBar(title: const Text('Pirate Translator')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('English: hello -> Pirate: $hello', style: const TextStyle(fontSize: 20)),
              Text('English: friend -> Pirate: $friend', style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 20),
              Text('Loaded translations count: $count',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
