// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import 'src/shim/dart_ui.dart' as ui;

const String _htmlElementViewType = '_htmlElementViewType';
const double _videoWidth = 640;
const double _videoHeight = 480;

/// The html.Element that will be rendered underneath the flutter UI.
html.Element htmlElement = html.DivElement()
  ..style.width = '100%'
  ..style.height = '100%'
  ..style.backgroundColor = '#fabada'
  ..style.cursor = 'auto'
  ..id = 'background-html-view';

// See other examples commented out below...

// html.Element htmlElement = html.VideoElement()
//   ..style.width = '100%'
//   ..style.height = '100%'
//   ..style.cursor = 'auto'
//   ..style.backgroundColor = 'black'
//   ..id = 'background-html-view'
//   ..src = 'https://archive.org/download/BigBuckBunny_124/Content/big_buck_bunny_720p_surround.mp4'
//   ..poster = 'https://peach.blender.org/wp-content/uploads/title_anouncement.jpg?x11217'
//   ..controls = true;

// html.Element htmlElement = html.IFrameElement()
//       ..width = '100%'
//       ..height = '100%'
//       ..id = 'background-html-view'
//       ..src = 'https://www.youtube.com/embed/IyFZznAk69U'
//       ..style.border = 'none';

void main() {
  ui.platformViewRegistry.registerViewFactory(
    _htmlElementViewType,
    (int viewId) => htmlElement,
  );

  runApp(const MyApp());
}

/// Main app
class MyApp extends StatelessWidget {
  /// Creates main app.
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Stopping Clicks with some DOM',
      home: MyHomePage(),
    );
  }
}

/// First page
class MyHomePage extends StatefulWidget {
  /// Creates first page.
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _lastClick = 'none';

  void _clickedOn(String key) {
    setState(() {
      _lastClick = key;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PointerInterceptor demo'),
        actions: <Widget>[
          PointerInterceptor(
            // debug: true,
            child: IconButton(
              icon: const Icon(Icons.add_alert),
              tooltip: 'AppBar Icon',
              onPressed: () {
                _clickedOn('appbar-icon');
              },
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Last click on: $_lastClick',
              key: const Key('last-clicked'),
            ),
            Container(
              color: Colors.black,
              width: _videoWidth,
              height: _videoHeight,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  HtmlElement(
                    key: const ValueKey<String>('background-widget'),
                    onClick: () {
                      _clickedOn('html-element');
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      ElevatedButton(
                        key: const Key('transparent-button'),
                        child: const Text('Never calls onPressed'),
                        onPressed: () {
                          _clickedOn('transparent-button');
                        },
                      ),
                      PointerInterceptor(
                        intercepting: false,
                        child: ElevatedButton(
                          key: const Key('wrapped-transparent-button'),
                          child:
                              const Text('Never calls onPressed transparent'),
                          onPressed: () {
                            _clickedOn('wrapped-transparent-button');
                          },
                        ),
                      ),
                      PointerInterceptor(
                        child: ElevatedButton(
                          key: const Key('clickable-button'),
                          child: const Text('Works As Expected'),
                          onPressed: () {
                            _clickedOn('clickable-button');
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          PointerInterceptor(
            // debug: true,
            child: FloatingActionButton(
              child: const Icon(Icons.navigation),
              onPressed: () {
                _clickedOn('fab-1');
              },
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: PointerInterceptor(
          // debug: true, // Enable this to "see" the interceptor covering the column.
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ListTile(
                title: const Text('Item 1'),
                onTap: () {
                  _clickedOn('drawer-item-1');
                },
              ),
              ListTile(
                title: const Text('Item 2'),
                onTap: () {
                  _clickedOn('drawer-item-2');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Initialize the videoPlayer, then render the corresponding view...
class HtmlElement extends StatelessWidget {
  /// Constructor
  const HtmlElement({Key? key, required this.onClick}) : super(key: key);

  /// A function to run when the element is clicked
  final VoidCallback onClick;

  @override
  Widget build(BuildContext context) {
    htmlElement.onClick.listen((_) {
      onClick();
    });

    return const HtmlElementView(
      viewType: _htmlElementViewType,
    );
  }
}
