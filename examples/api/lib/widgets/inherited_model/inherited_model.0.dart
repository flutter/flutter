// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for InheritedModel

import 'package:flutter/material.dart';

enum Logo { backgroundColor, size }

void main() => runApp(const InheritedModelApp());

class InheritedModelApp extends StatelessWidget {
  const InheritedModelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: InheritedModelExample(),
    );
  }
}

class LogoModel extends InheritedModel<Logo> {
  const LogoModel({
    super.key,
    this.backgroundColor,
    this.logoSize,
    required super.child,
  });

  final Color? backgroundColor;
  final double? logoSize;

  static LogoModel? of(BuildContext context, Logo aspect) {
    return InheritedModel.inheritFrom<LogoModel>(context, aspect: aspect);
  }

  @override
  bool updateShouldNotify(LogoModel oldWidget) {
    return backgroundColor != oldWidget.backgroundColor ||
      logoSize != oldWidget.logoSize;
  }

  @override
  bool updateShouldNotifyDependent(LogoModel oldWidget, Set<Logo> dependencies) {
    if (backgroundColor != oldWidget.backgroundColor && dependencies.contains(Logo.backgroundColor)) {
      return true;
    }
    if (logoSize != oldWidget.logoSize && dependencies.contains(Logo.size)) {
      return true;
    }
    return false;
  }
}

class InheritedModelExample extends StatefulWidget {
  const InheritedModelExample({super.key});

  @override
  State<InheritedModelExample> createState() => _InheritedModelExampleState();
}

class _InheritedModelExampleState extends State<InheritedModelExample> {
  double size = 100.0;
  Color color = Colors.blue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('InheritedModel Sample')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Center(
            child: LogoModel(
              backgroundColor: color,
              logoSize: size,
              child: const BackgroundWidget(
                child: LogoWidget(),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Rebuilt Background'),
                      duration: Duration(milliseconds: 500),
                    ),
                  );
                  setState(() {
                    color = color == Colors.blue ? Colors.red : Colors.blue;
                  });
                },
                child: const Text('Update background'),
              ),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Rebuilt LogoWidget'),
                      duration: Duration(milliseconds: 500),
                    ),
                  );
                  setState(() {
                    size = size == 100.0 ? 200.0 : 100.0;
                  });
                },
                child: const Text('Resize Logo'),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class BackgroundWidget extends StatelessWidget {
  const BackgroundWidget({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Color color = LogoModel.of(context, Logo.backgroundColor)!.backgroundColor!;

    return AnimatedContainer(
      padding: const EdgeInsets.all(12.0),
      color: color,
      duration: const Duration(seconds: 2),
      curve: Curves.fastOutSlowIn,
      child: child,
    );
  }
}

class LogoWidget extends StatelessWidget {
  const LogoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final double size = LogoModel.of(context, Logo.size)!.logoSize!;

    return AnimatedContainer(
      padding: const EdgeInsets.all(20.0),
      duration: const Duration(seconds: 2),
      curve: Curves.fastLinearToSlowEaseIn,
      alignment: Alignment.center,
      child: FlutterLogo(size: size),
    );
  }
}
