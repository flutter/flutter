// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../gallery/syntax_highlighter.dart';

class SingleComponentDemoData {
  SingleComponentDemoData({
    this.widget,
    this.exampleCode,
    this.description,
    this.onPressedDemo
  });

  final Widget widget;
  final String exampleCode;
  final String description;
  final VoidCallback onPressedDemo;
}

class ComponentDemoTabData extends SingleComponentDemoData {
  ComponentDemoTabData({
    Widget widget,
    String exampleCode,
    String description,
    VoidCallback onPressedDemo,
    this.tabName
  }) : super(
    widget: widget,
    exampleCode: exampleCode,
    description: description,
    onPressedDemo: onPressedDemo
  );

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

  @override
  Widget build(BuildContext context) {
    return new TabBarSelection<ComponentDemoTabData>(
      values: demos,
      child: new Scaffold(
        appBar: new AppBar(
          title: new Text(title),
          tabBar: new TabBar<ComponentDemoTabData>(
            isScrollable: true,
            labels: ComponentDemoTabData.buildTabLabels(demos)
          )
        ),
        body: new TabbedComponentDemo(demos)
      )
    );
  }
}

class TabbedComponentDemo extends StatelessWidget {
  TabbedComponentDemo(this.demos);

  final List<ComponentDemoTabData> demos;

  @override
  Widget build(BuildContext context) {
    return new TabBarView<ComponentDemoTabData>(
      children: demos.map(buildTabView).toList()
    );
  }

  Widget buildTabView(ComponentDemoTabData demo) {
    return new SingleComponentDemo(demo);
  }
}

class SingleComponentDemo extends StatelessWidget {
  SingleComponentDemo(this.demo);

  final SingleComponentDemoData demo;

  @override
  Widget build(BuildContext context) {
    return new Column(
      children: <Widget>[
        new Padding(
          padding: new EdgeInsets.all(16.0),
          child: new MarkdownBody(data: demo.description)
        ),
        new Flexible(
          child: demo.widget
        ),
        new DemoBottomBar(
          exampleCode: demo.exampleCode,
          onPressedDemo: demo.onPressedDemo
        )
      ]
    );
  }
}

class DemoBottomBar extends StatelessWidget {
  DemoBottomBar({ this.exampleCode, this.onPressedDemo });

  final String exampleCode;
  final VoidCallback onPressedDemo;

  @override
  Widget build(BuildContext context) {
    VoidCallback onPressedCode;
    if (exampleCode != null) {
      onPressedCode = () {
        Navigator.push(context, new MaterialPageRoute<FullScreenCodeDialog>(
          builder: (BuildContext context) => new FullScreenCodeDialog(code: exampleCode)
        ));
      };
    }

    return new Column(
      children: <Widget>[
        new Divider(
          height: 1.0
        ),
        new Container(
          height: 48.0,
          child: new Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              new FlatButton(
                child: new Row(
                  children: <Widget>[
                    new Padding(
                      padding: new EdgeInsets.only(right: 8.0),
                      child: new Icon(icon: Icons.code)
                    ),
                    new Text('VIEW CODE')
                  ]
                ),
                onPressed: onPressedCode
              ),
              new FlatButton(
                child: new Row(
                  children: <Widget>[
                    new Padding(
                      padding: new EdgeInsets.only(right: 8.0),
                      child: new Icon(icon: Icons.star)
                    ),
                    new Text('LIVE DEMO')
                  ]
                ),
                onPressed: onPressedDemo
              )
            ]
          )
        )
      ]
    );
  }
}

class FormattedCode extends StatefulWidget {
  FormattedCode(this.code);

  final String code;

  @override
  _FormattedCodeState createState() => new _FormattedCodeState();
}

class _FormattedCodeState extends State<FormattedCode> {
  @override
  void initState() {
    super.initState();
    _formatText();
  }

  TextSpan _formattedText;

  @override
  Widget build(BuildContext context) {
    return new RichText(text: _formattedText);
  }

  @override
  void didUpdateConfig(FormattedCode oldConfig) {
    super.didUpdateConfig(oldConfig);

    if (oldConfig.code != config.code)
      _formatText();
  }

  void _formatText() {
    _formattedText = new TextSpan(
      style: new TextStyle(fontFamily: 'monospace', fontSize: 10.0),
      children: <TextSpan>[new DartSyntaxHighlighter().format(config.code)]
    );
  }
}

class FullScreenCodeDialog extends StatelessWidget {
  FullScreenCodeDialog({ this.code });

  final String code;

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        leading: new IconButton(
          icon: Icons.clear,
          onPressed: () { Navigator.pop(context); }
        ),
        title: new Text('Example Code')
      ),
      body: new ScrollableViewport(
        child: new Padding(
          padding: new EdgeInsets.all(16.0),
          child: new FormattedCode(code)
        )
      )
    );
  }
}
