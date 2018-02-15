// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'example_code_parser.dart';
import 'syntax_highlighter.dart';

class ComponentDemoTabData {
  ComponentDemoTabData({
    this.demoWidget,
    this.exampleCodeTag,
    this.description,
    this.tabName
  });

  final Widget demoWidget;
  final String exampleCodeTag;
  final String description;
  final String tabName;

  @override
  bool operator==(Object other) {
    if (other.runtimeType != runtimeType)
      return false;
    final ComponentDemoTabData typedOther = other;
    return typedOther.tabName == tabName && typedOther.description == description;
  }

  @override
  int get hashCode => hashValues(tabName.hashCode, description.hashCode);
}

class TabbedComponentDemoScaffold extends StatelessWidget {
  const TabbedComponentDemoScaffold({
    this.title,
    this.demos
  });

  final List<ComponentDemoTabData> demos;
  final String title;

  void _showExampleCode(BuildContext context) {
    final String tag = demos[DefaultTabController.of(context).index].exampleCodeTag;
    if (tag != null) {
      Navigator.push(context, new MaterialPageRoute<FullScreenCodeDialog>(
        builder: (BuildContext context) => new FullScreenCodeDialog(exampleCodeTag: tag)
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return new DefaultTabController(
      length: demos.length,
      child: new Scaffold(
        appBar: new AppBar(
          title: new Text(title),
          actions: <Widget>[
            new Builder(
              builder: (BuildContext context) {
                return new IconButton(
                  icon: const Icon(Icons.description),
                  tooltip: 'Show example code',
                  onPressed: () {
                    _showExampleCode(context);
                  },
                );
              },
            ),
          ],
          bottom: new TabBar(
            isScrollable: true,
            tabs: demos.map((ComponentDemoTabData data) => new Tab(text: data.tabName)).toList(),
          ),
        ),
        body: new TabBarView(
          children: demos.map((ComponentDemoTabData demo) {
            return new SafeArea(
              top: false,
              bottom: false,
              child: new Column(
                children: <Widget>[
                  new Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: new Text(demo.description,
                      style: Theme.of(context).textTheme.subhead
                    )
                  ),
                  new Expanded(child: demo.demoWidget)
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class FullScreenCodeDialog extends StatefulWidget {
  const FullScreenCodeDialog({ this.exampleCodeTag });

  final String exampleCodeTag;

  @override
  FullScreenCodeDialogState createState() => new FullScreenCodeDialogState();
}

class FullScreenCodeDialogState extends State<FullScreenCodeDialog> {

  String _exampleCode;

  @override
  void didChangeDependencies() {
    getExampleCode(widget.exampleCodeTag, DefaultAssetBundle.of(context)).then<Null>((String code) {
      if (mounted) {
        setState(() {
          _exampleCode = code;
        });
      }
    });
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final SyntaxHighlighterStyle style = Theme.of(context).brightness == Brightness.dark
      ? SyntaxHighlighterStyle.darkThemeStyle()
      : SyntaxHighlighterStyle.lightThemeStyle();

    Widget body;
    if (_exampleCode == null) {
      body = const Center(
        child: const CircularProgressIndicator()
      );
    } else {
      body = new SingleChildScrollView(
        child: new Padding(
          padding: const EdgeInsets.all(16.0),
          child: new RichText(
            text: new TextSpan(
              style: const TextStyle(fontFamily: 'monospace', fontSize: 10.0),
              children: <TextSpan>[
                new DartSyntaxHighlighter(style).format(_exampleCode)
              ]
            )
          )
        )
      );
    }

    return new Scaffold(
      appBar: new AppBar(
        leading: new IconButton(
          icon: const Icon(
            Icons.clear,
            semanticLabel: 'Close',
          ),
          onPressed: () { Navigator.pop(context); }
        ),
        title: const Text('Example code')
      ),
      body: body
    );
  }
}
