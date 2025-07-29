// Copyright 2019 the Dart project authors. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blue),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  final String title;

  const MyHomePage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          key: const Key('show_alert_button'),
          onPressed: () {
            showDialog<void>(
              barrierDismissible: false,
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  scrollable: true,
                  title: const Text('Alert Dialog'),
                  content: Wrap(
                    children: [
                      SizedBox(
                        width: 300,
                        child: DropdownButtonFormField<String>(
                          key: const Key('dropdown_button'),
                          items: const [
                            DropdownMenuItem(value: 'test', child: Text('test')),
                            DropdownMenuItem(value: 'option2', child: Text('Option 2')),
                            DropdownMenuItem(value: 'option3', child: Text('Option 3')),
                          ],
                          onChanged: (value) {},
                          decoration: const InputDecoration(labelText: 'Select an option'),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      key: const Key('ok_button'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            );
          },
          child: const Text('Show Alert'),
        ),
      ),
    );
  }
}
