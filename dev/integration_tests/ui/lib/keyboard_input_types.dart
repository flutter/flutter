// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
      title: 'Keyboard Input Types',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController textController;
  TextEditingController datetimeController;
  TextEditingController emailAddressController;
  TextEditingController multilineController;
  TextEditingController numberController;
  TextEditingController phoneController;
  TextEditingController urlController;
  String lastEnteredText = '';

  @override
  void initState() {
    super.initState();

    textController = TextEditingController();
    datetimeController = TextEditingController();
    emailAddressController = TextEditingController();
    multilineController = TextEditingController();
    numberController = TextEditingController();
    phoneController = TextEditingController();
    urlController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keyboard Input Types'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Text(
            '$lastEnteredText',
            key: const ValueKey<String>('mirrorValue'),
          ),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.6,
              minWidth: MediaQuery.of(context).size.width * 0.6,
            ),
            margin: const EdgeInsets.only(left:15),
            child: TextField(
              key: const ValueKey<String>('text'),
              keyboardType: TextInputType.text,
              controller: textController,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                labelText: 'text',
              ),
            ),
          ),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.6,
              minWidth: MediaQuery.of(context).size.width * 0.6,
            ),
            margin: const EdgeInsets.only(left:15),
            child: TextField(
              key: const ValueKey<String>('datetime'),
              keyboardType: TextInputType.datetime,
              controller: datetimeController,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                labelText: 'datetime',
              ),
            ),
          ),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.6,
              minWidth: MediaQuery.of(context).size.width * 0.6,
            ),
            margin: const EdgeInsets.only(left:15),
            child: TextField(
              key: const ValueKey<String>('emailAddress'),
              keyboardType: TextInputType.emailAddress,
              controller: emailAddressController,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                labelText: 'emailAddress',
              ),
            ),
          ),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.6,
              minWidth: MediaQuery.of(context).size.width * 0.6,
            ),
            margin: const EdgeInsets.only(left:15),
            child: TextField(
              key: const ValueKey<String>('multiline'),
              keyboardType: TextInputType.multiline,
              controller: multilineController,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                labelText: 'multiline',
              ),
            ),
          ),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.6,
              minWidth: MediaQuery.of(context).size.width * 0.6,
            ),
            margin: const EdgeInsets.only(left:15),
            child: TextField(
              key: const ValueKey<String>('number'),
              keyboardType: TextInputType.number,
              controller: numberController,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                labelText: 'number',
              ),
            ),
          ),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.6,
              minWidth: MediaQuery.of(context).size.width * 0.6,
            ),
            margin: const EdgeInsets.only(left:15),
            child: TextField(
              key: const ValueKey<String>('phone'),
              keyboardType: TextInputType.phone,
              controller: phoneController,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                labelText: 'phone',
              ),
            ),
          ),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.6,
              minWidth: MediaQuery.of(context).size.width * 0.6,
            ),
            margin: const EdgeInsets.only(left:15),
            child: TextField(
              key: const ValueKey<String>('url'),
              keyboardType: TextInputType.url,
              controller: urlController,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                labelText: 'url',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
