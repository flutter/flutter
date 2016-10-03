// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'example_code_parser.dart';
import 'syntax_highlighter.dart';

class ComponentDemoTabData {
  ComponentDemoTabData({
    this.widget,
    this.exampleCodeTag,
    this.description,
    this.tabName
  });

  final Widget widget;
  final String exampleCodeTag;
  final String description;
  final String tabName;

  static Map<ComponentDemoTabData, TabLabel> buildTabLabels(List<ComponentDemoTabData> demos) {
    return new Map<ComponentDemoTabData, TabLabel>.fromIterable(
      demos,
      value: (ComponentDemoTabData demo) => new TabLabel(text: demo.tabName)
    );
  }

  @override
  bool operator==(Object other) {
    if (other.runtimeType != runtimeType)
      return false;
    ComponentDemoTabData typedOther = other;
    return typedOther.tabName == tabName && typedOther.description == description;
  }

  @override
  int get hashCode => hashValues(tabName.hashCode, description.hashCode);
}

class TabbedComponentDemoScaffold extends StatelessWidget {
  TabbedComponentDemoScaffold({
    this.title,
    this.demos
  });

  final List<ComponentDemoTabData> demos;
  final String title;

  void _showExampleCode(BuildContext context) {
    TabBarSelectionState<ComponentDemoTabData> selection = TabBarSelection.of(context);
    String tag = selection.value?.exampleCodeTag;
    if (tag != null) {
      Navigator.push(context, new MaterialPageRoute<FullScreenCodeDialog>(
        builder: (BuildContext context) => new FullScreenCodeDialog(exampleCodeTag: tag)
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return new TabBarSelection<ComponentDemoTabData>(
      values: demos,
      child: new Scaffold(
        appBar: new AppBar(
          title: new Text(title),
          actions: <Widget>[
            new Builder(
              builder: (BuildContext context) {
                return new IconButton(
                  icon: new Icon(Icons.description),
                  tooltip: 'Show example code',
                  onPressed: () { _showExampleCode(context); }
                );
              }
            )
          ],
          bottom: new TabBar<ComponentDemoTabData>(
            isScrollable: true,
            labels: ComponentDemoTabData.buildTabLabels(demos)
          )
        ),
        body: new TabBarView<ComponentDemoTabData>(
          children: demos.map((ComponentDemoTabData demo) {
            return new Column(
              children: <Widget>[
                new Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: new Text(demo.description,
                    style: Theme.of(context).textTheme.subhead
                  )
                ),
                new Flexible(child: demo.widget)
              ]
            );
          }).toList()
        )
      )
    );
  }
}

class FullScreenCodeDialog extends StatefulWidget {
  FullScreenCodeDialog({ this.exampleCodeTag });

  final String exampleCodeTag;

  @override
  FullScreenCodeDialogState createState() => new FullScreenCodeDialogState();
}

class FullScreenCodeDialogState extends State<FullScreenCodeDialog> {

  String _exampleCode;

  @override
  void dependenciesChanged() {
    getExampleCode(config.exampleCodeTag, DefaultAssetBundle.of(context)).then((String code) {
      setState(() {
        _exampleCode = code;
      });
    });
    super.dependenciesChanged();
  }

  @override
  Widget build(BuildContext context) {
    final SyntaxHighlighterStyle style = Theme.of(context).brightness == Brightness.dark
      ? SyntaxHighlighterStyle.darkThemeStyle()
      : SyntaxHighlighterStyle.lightThemeStyle();

    Widget body;
    if (_exampleCode == null) {
      body = new Center(
        child: new CircularProgressIndicator()
      );
    } else {
      body = new ScrollableViewport(
        child: new Padding(
          padding: new EdgeInsets.all(16.0),
          child: new RichText(
            text: new TextSpan(
              style: new TextStyle(fontFamily: 'monospace', fontSize: 10.0),
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
          icon: new Icon(Icons.clear),
          onPressed: () { Navigator.pop(context); }
        ),
        title: new Text('Example code')
      ),
      body: body
    );
  }
}
