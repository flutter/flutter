// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [ListTile].

void main() => runApp(const ListTileApp());

class ListTileApp extends StatelessWidget {
  const ListTileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(listTileTheme: const ListTileThemeData(textColor: Colors.white)),
      home: const ListTileExample(),
    );
  }
}

class ListTileExample extends StatelessWidget {
  const ListTileExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ListTile Samples')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Hero(
            tag: 'ListTile-Hero',
            // Wrap the ListTile in a Material widget so the ListTile has someplace
            // to draw the animated colors during the hero transition.
            child: Material(
              child: ListTile(
                title: const Text('ListTile with Hero'),
                subtitle: const Text('Tap here for Hero transition'),
                tileColor: Colors.cyan,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<Widget>(
                      builder: (BuildContext context) {
                        return Scaffold(
                          appBar: AppBar(title: const Text('ListTile Hero')),
                          body: Center(
                            child: Hero(
                              tag: 'ListTile-Hero',
                              child: Material(
                                child: ListTile(
                                  title: const Text('ListTile with Hero'),
                                  subtitle: const Text('Tap here to go back'),
                                  tileColor: Colors.blue[700],
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          RepeatingTweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(seconds: 1),
            reverse: true,
            curve: Curves.easeInOut,
            builder: (BuildContext context, Animation<double> animation, Widget? child) {
              return FadeTransition(
                opacity: animation,
                // Wrap the ListTile in a Material widget so the ListTile has someplace
                // to draw the animated colors during the fade transition.
                child: const Material(
                  child: ListTile(
                    title: Text('ListTile with FadeTransition'),
                    selectedTileColor: Colors.green,
                    selectedColor: Colors.white,
                    selected: true,
                  ),
                ),
              );
            },
          ),
          SizedBox(
            height: 100,
            child: Center(
              child: RepeatingTweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 850),
                reverse: true,
                curve: Curves.easeOut,
                builder: (BuildContext context, Animation<double> animation, Widget? child) {
                  return SizeTransition(
                    sizeFactor: animation,
                    axisAlignment: -1.0,
                    // Wrap the ListTile in a Material widget so the ListTile has someplace
                    // to draw the animated colors during the size transition.
                    child: const Material(
                      child: ListTile(
                        title: Text('ListTile with SizeTransition'),
                        tileColor: Colors.red,
                        minVerticalPadding: 25.0,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
