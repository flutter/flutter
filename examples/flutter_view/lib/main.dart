// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const FlutterView());
}

class FlutterView extends StatelessWidget {
  const FlutterView({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter View',
      theme: ThemeData(
        primarySwatch: Colors.grey,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}
class Item {
  Item({
    required this.expandedValue,
    required this.headerValue,
    this.isExpanded = false,
  });

  final String expandedValue;
  final String headerValue;
  bool isExpanded;
}

List<Item> expandedList = <Item>[
  Item(expandedValue: 'expandedValue', headerValue: 'headerValue'),
  Item(expandedValue: 'expandedValue2', headerValue: 'headerValue2'),
  Item(expandedValue: 'expandedValue3', headerValue: 'headerValue3'),
];

ExpansionPanel cellExpanded(
    bool isExpanded, String headerValue, String expandedValue) {
  return ExpansionPanel(
    headerBuilder: (BuildContext context, _) {
      return ListTile(
        title: Text(
          headerValue,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      );
    },
    body: ListTile(
      title: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Text(expandedValue, style: const TextStyle(fontSize: 16)),
      ),
    ),
    canTapOnHeader: true,
    isExpanded: isExpanded,
  );
}

class _MyHomePageState extends State<MyHomePage> {
  static const String _channel = 'increment';
  static const String _pong = 'pong';
  static const String _emptyMessage = '';
  static const BasicMessageChannel<String?> platform =
      BasicMessageChannel<String?>(_channel, StringCodec());

  int _counter = 0;

  @override
  void initState() {
    super.initState();
    platform.setMessageHandler(_handlePlatformIncrement);
  }

  Future<String> _handlePlatformIncrement(String? message) async {
    setState(() {
      _counter++;
    });
    return _emptyMessage;
  }

  void _sendFlutterIncrement() {
    platform.send(_pong);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Center(
              child: Text(
                'Platform button tapped $_counter time${ _counter == 1 ? '' : 's' }.',
                style: const TextStyle(fontSize: 17.0),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.only(bottom: 15.0, left: 5.0),
            child: Row(
              children: <Widget>[
                Image.asset('assets/flutter-mark-square-64.png', scale: 1.5),
                const Text('Flutter', style: TextStyle(fontSize: 30.0)),
              ],
            ),
          ),
          SizedBox(
            width: 300,
            child: ExpansionPanelList(
              expandIconColor: Colors.red,
              expansionCallback: (int index, _) {
                setState(
                  () {
                    expandedList[index].isExpanded = !expandedList[index].isExpanded;
                  },
                );
              },
              children: expandedList.map<ExpansionPanel>((Item item) {
                return cellExpanded(
                    item.isExpanded, item.headerValue, item.expandedValue);
              }).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _sendFlutterIncrement,
        child: const Icon(Icons.add),
      ),
    );
  }
}
