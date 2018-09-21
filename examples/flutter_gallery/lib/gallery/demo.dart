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
    this.demos,
    this.actions,
  });

  final List<ComponentDemoTabData> demos;
  final String title;
  final List<Widget> actions;

  void _showExampleCode(BuildContext context) {
    final String tag = demos[DefaultTabController.of(context).index].exampleCodeTag;
    if (tag != null) {
      Navigator.push(context, MaterialPageRoute<FullScreenCodeDialog>(
        builder: (BuildContext context) => FullScreenCodeDialog(exampleCodeTag: tag)
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: demos.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: (actions ?? <Widget>[])..addAll(
            <Widget>[
              Builder(
                builder: (BuildContext context) {
                  return IconButton(
                    icon: const Icon(Icons.code),
                    tooltip: 'Show example code',
                    onPressed: () {
                      _showExampleCode(context);
                    },
                  );
                },
              )
            ],
          ),
          bottom: TabBar(
            isScrollable: true,
            tabs: demos.map((ComponentDemoTabData data) => Tab(text: data.tabName)).toList(),
          ),
        ),
        body: TabBarView(
          children: demos.map((ComponentDemoTabData demo) {
            return SafeArea(
              top: false,
              bottom: false,
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(demo.description,
                      style: Theme.of(context).textTheme.subhead
                    )
                  ),
                  Expanded(child: demo.demoWidget)
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
  FullScreenCodeDialogState createState() => FullScreenCodeDialogState();
}

class FullScreenCodeDialogState extends State<FullScreenCodeDialog> {

  String _exampleCode;

  @override
  void didChangeDependencies() {
    getExampleCode(widget.exampleCodeTag, DefaultAssetBundle.of(context)).then<Null>((String code) {
      if (mounted) {
        setState(() {
          _exampleCode = code ?? 'Example code not found';
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
        child: CircularProgressIndicator()
      );
    } else {
      body = SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontFamily: 'monospace', fontSize: 10.0),
              children: <TextSpan>[
                DartSyntaxHighlighter(style).format(_exampleCode)
              ]
            )
          )
        )
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
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
