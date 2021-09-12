import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PartialRepaintPage extends StatelessWidget {
  const PartialRepaintPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      theme: const CupertinoThemeData(brightness: Brightness.light),
      home: CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Partial Repaint'),
        ),
        child: CupertinoTabScaffold(
          tabBar: CupertinoTabBar(items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.power)),
            BottomNavigationBarItem(icon: Icon(Icons.disabled_by_default))
          ]),
          tabBuilder: (BuildContext context, int index) {
            return index == 0 ? const Body() : const SizedBox();
          },
        ),
      ),
    );
  }
}

class Body extends StatelessWidget {
  const Body({
    Key? key,
  }) : super(key: key);

  Widget buildChild(int i) {
    final BoxDecoration decoration = BoxDecoration(
      color: Colors.red,
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 10.0,
        ),
      ],
      borderRadius: BorderRadius.circular(10.0),
    );

    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        padding: const EdgeInsets.all(4),
        child: Text(
          'Item $i',
          style: const TextStyle(fontSize: 11.0),
        ),
        decoration: decoration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: SingleChildScrollView(
            child: Wrap(
              children:
                  List<Widget>.generate(200, (int index) => buildChild(index)),
            ),
          ),
        ),
        const Positioned.fill(
          child: IgnorePointer(
            child: Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
