// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_driver/driver_extension.dart';

void main() {
  // enableFlutterDriverExtension() will disable keyboard,
  // which is required for flutter_driver tests
  // But breaks the XCUITests
  if (const bool.fromEnvironment('ENABLE_DRIVER_EXTENSION')) {
    enableFlutterDriverExtension();
  }
  runApp(const MyApp());
}

/// The main app entrance of the test
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

/// A page with several buttons in the center.
///
/// On press the button, a page with platform view should be pushed into the scene.
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, this.title});
  final String? title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? '')),
      body: Column(
        children: <Widget>[
          TextButton(
            key: const ValueKey<String>('platform_view_button'),
            child: const Text('show platform view'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<MergeThreadTestPage>(
                  builder: (BuildContext context) => const MergeThreadTestPage(),
                ),
              );
            },
          ),
          // Push this button to perform an animation, which ensure the threads are unmerged after the animation.
          ElevatedButton(
            key: const ValueKey<String>('unmerge_button'),
            child: const Text('Tap to unmerge threads'),
            onPressed: () {},
          ),
          TextButton(
            key: const ValueKey<String>('platform_view_focus_test'),
            child: const Text('platform view focus test'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<FocusTestPage>(
                  builder: (BuildContext context) => const FocusTestPage(),
                ),
              );
            },
          ),
          TextButton(
            key: const ValueKey<String>('platform_view_z_order_test'),
            child: const Text('platform view z order test'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<ZOrderTestPage>(
                  builder: (BuildContext context) => const ZOrderTestPage(),
                ),
              );
            },
          ),
          TextButton(
            key: const ValueKey<String>('web_view_behind_context_menu_test'),
            child: const Text('web view behind context menu test'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<WebViewBehindContextMenuTestPage>(
                  builder: (BuildContext context) => const WebViewBehindContextMenuTestPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// A page to test thread merge for platform view.
class MergeThreadTestPage extends StatelessWidget {
  const MergeThreadTestPage({super.key});

  static Key button = const ValueKey<String>('plus_button');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Platform View Thread Merge Tests')),
      body: Column(
        children: <Widget>[
          const Expanded(
            child: SizedBox(width: 300, child: UiKitView(viewType: 'platform_view')),
          ),
          ElevatedButton(key: button, child: const Text('button'), onPressed: () {}),
        ],
      ),
    );
  }
}

/// A page to test platform view focus.
class FocusTestPage extends StatefulWidget {
  const FocusTestPage({super.key});

  @override
  State<FocusTestPage> createState() => _FocusTestPageState();
}

class _FocusTestPageState extends State<FocusTestPage> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.text = 'Flutter Text Field';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Platform View Focus Tests')),
      body: Column(
        children: <Widget>[
          const SizedBox(width: 300, height: 50, child: UiKitView(viewType: 'platform_text_field')),
          TextField(controller: _controller),
        ],
      ),
    );
  }
}

/// A page to test a platform view in an alert dialog prompt is still tappable.
/// See [this issue](https://github.com/flutter/flutter/issues/118366).
class ZOrderTestPage extends StatefulWidget {
  const ZOrderTestPage({super.key});

  @override
  State<ZOrderTestPage> createState() => _ZOrderTestPageState();
}

class _ZOrderTestPageState extends State<ZOrderTestPage> {
  bool _showBackground = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Platform view z order test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Visibility(
              visible: _showBackground,
              child: const SizedBox.square(
                dimension: 500.0,
                child: UiKitView(
                  viewType: 'platform_view',
                  creationParamsCodec: StandardMessageCodec(),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (BuildContext context) {
                    return const SizedBox.square(
                      dimension: 250.0,
                      child: UiKitView(
                        viewType: 'platform_button',
                        creationParamsCodec: StandardMessageCodec(),
                      ),
                    );
                  },
                );

                // XCUITest fails to query the background platform view,
                // Since it is covered by the dialog prompt, which removes
                // semantic nodes underneath.
                // As a workaround, we show the background with a delay.
                Future<void>.delayed(const Duration(seconds: 1)).then((void value) {
                  setState(() {
                    _showBackground = true;
                  });
                });
              },
              child: const Text('Show Alert'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A page to test a web view link is still tappable after dismissing a context menu.
/// See [this issue](https://github.com/flutter/flutter/issues/175099).
class WebViewBehindContextMenuTestPage extends StatefulWidget {
  const WebViewBehindContextMenuTestPage({super.key});

  @override
  State<WebViewBehindContextMenuTestPage> createState() => _WebViewBehindContextMenuTestPageState();
}

class _WebViewBehindContextMenuTestPageState extends State<WebViewBehindContextMenuTestPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Web view behind context menu test'),
        actions: <Widget>[
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (String value) {},
            itemBuilder: (BuildContext context) {
              return <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(value: 'button 1', child: Text('menu button 1')),
                const PopupMenuItem<String>(value: 'button 2', child: Text('menu button 2')),
                const PopupMenuItem<String>(value: 'button 3', child: Text('menu button 3')),
                const PopupMenuItem<String>(value: 'button 4', child: Text('menu button 4')),
                const PopupMenuItem<String>(value: 'button 5', child: Text('menu button 5')),
              ];
            },
          ),
        ],
      ),
      body: const Center(
        child: SizedBox.square(
          dimension: 500.0,
          child: UiKitView(
            viewType: 'platform_web_view',
            creationParamsCodec: StandardMessageCodec(),
          ),
        ),
      ),
    );
  }
}
