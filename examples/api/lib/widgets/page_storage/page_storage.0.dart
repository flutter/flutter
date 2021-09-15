// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Template: dev/snippets/config/templates/freeform.tmpl
//
// Comment lines marked with "▼▼▼" and "▲▲▲" are used for authoring
// of samples, and may be ignored if you are just exploring the sample.

// Flutter code sample for PageStorage
//
//***************************************************************************
//* ▼▼▼▼▼▼▼▼ description ▼▼▼▼▼▼▼▼ (do not modify or remove section marker)

// This sample shows how to explicitly use a [PageStorage] to
// store the states of its children pages. Each page includes a scrollable
// list, whose position is preserved when switching between the tabs thanks to
// the help of [PageStorageKey].

//* ▲▲▲▲▲▲▲▲ description ▲▲▲▲▲▲▲▲ (do not modify or remove section marker)
//***************************************************************************

//****************************************************************************
//* ▼▼▼▼▼▼▼▼ code-imports ▼▼▼▼▼▼▼▼ (do not modify or remove section marker)

import 'package:flutter/material.dart';

//* ▲▲▲▲▲▲▲▲ code-imports ▲▲▲▲▲▲▲▲ (do not modify or remove section marker)
//****************************************************************************

//*************************************************************************
//* ▼▼▼▼▼▼▼▼ code-main ▼▼▼▼▼▼▼▼ (do not modify or remove section marker)

void main() => runApp(const MyApp());

//* ▲▲▲▲▲▲▲▲ code-main ▲▲▲▲▲▲▲▲ (do not modify or remove section marker)
//*************************************************************************

//********************************************************************
//* ▼▼▼▼▼▼▼▼ code ▼▼▼▼▼▼▼▼ (do not modify or remove section marker)

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<Widget> pages = const <Widget>[
    ColorBoxPage(
      key: PageStorageKey<String>('pageOne'),
    ),
    ColorBoxPage(
      key: PageStorageKey<String>('pageTwo'),
    )
  ];
  int currentTab = 0;
  final PageStorageBucket _bucket = PageStorageBucket();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Persistence Example'),
      ),
      body: PageStorage(
        child: pages[currentTab],
        bucket: _bucket,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentTab,
        onTap: (int index) {
          setState(() {
            currentTab = index;
          });
        },
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'page 1',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'page2',
          ),
        ],
      ),
    );
  }
}

class ColorBoxPage extends StatelessWidget {
  const ColorBoxPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemExtent: 250.0,
      itemBuilder: (BuildContext context, int index) => Container(
        padding: const EdgeInsets.all(10.0),
        child: Material(
          color: index.isEven ? Colors.cyan : Colors.deepOrange,
          child: Center(
            child: Text(index.toString()),
          ),
        ),
      ),
    );
  }
}

//* ▲▲▲▲▲▲▲▲ code ▲▲▲▲▲▲▲▲ (do not modify or remove section marker)
//********************************************************************
