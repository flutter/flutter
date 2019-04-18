// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'demos.dart';
import 'example_code_parser.dart';
import 'syntax_highlighter.dart';

class ComponentDemoTabData {
  ComponentDemoTabData({
    this.demoWidget,
    this.exampleCodeTag,
    this.description,
    this.tabName,
    this.documentationUrl,
  });

  final Widget demoWidget;
  final String exampleCodeTag;
  final String description;
  final String tabName;
  final String documentationUrl;

  @override
  bool operator==(Object other) {
    if (other.runtimeType != runtimeType)
      return false;
    final ComponentDemoTabData typedOther = other;
    return typedOther.tabName == tabName
        && typedOther.description == description
        && typedOther.documentationUrl == documentationUrl;
  }

  @override
  int get hashCode => hashValues(tabName, description, documentationUrl);
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

  Future<void> _showApiDocumentation(BuildContext context) async {
    final String url = demos[DefaultTabController.of(context).index].documentationUrl;
    if (url == null)
      return;

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: const Text('Couldn\'t display URL:'),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(url),
              ),
            ],
          );
        },
      );
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
                    icon: const Icon(Icons.library_books, semanticLabel: 'Show documentation'),
                    onPressed: () => _showApiDocumentation(context),
                  );
                },
              ),
              Builder(
                builder: (BuildContext context) {
                  return IconButton(
                    icon: const Icon(Icons.code),
                    tooltip: 'Show example code',
                    onPressed: () => _showExampleCode(context),
                  );
                },
              ),
            ],
          ),
          bottom: TabBar(
            isScrollable: true,
            tabs: demos.map<Widget>((ComponentDemoTabData data) => Tab(text: data.tabName)).toList(),
          ),
        ),
        body: TabBarView(
          children: demos.map<Widget>((ComponentDemoTabData demo) {
            return SafeArea(
              top: false,
              bottom: false,
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(demo.description,
                      style: Theme.of(context).textTheme.subhead,
                    ),
                  ),
                  Expanded(child: demo.demoWidget),
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
    getExampleCode(widget.exampleCodeTag, DefaultAssetBundle.of(context)).then<void>((String code) {
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
        child: CircularProgressIndicator(),
      );
    } else {
      body = SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontFamily: 'monospace', fontSize: 10.0),
              children: <TextSpan>[
                DartSyntaxHighlighter(style).format(_exampleCode),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.clear,
            semanticLabel: 'Close',
          ),
          onPressed: () { Navigator.pop(context); },
        ),
        title: const Text('Example code'),
      ),
      body: body,
    );
  }
}

class MaterialDemoDocumentationButton extends StatelessWidget {
  MaterialDemoDocumentationButton(String routeName, { Key key })
    : documentationUrl = kDemoDocumentationUrl[routeName],
      assert(
        kDemoDocumentationUrl[routeName] != null,
        'A documentation URL was not specified for demo route $routeName in kAllGalleryDemos',
      ),
      super(key: key);

  final String documentationUrl;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.library_books),
      tooltip: 'API documentation',
      onPressed: () => launch(documentationUrl, forceWebView: true),
    );
  }
}

class CupertinoDemoDocumentationButton extends StatelessWidget {
  CupertinoDemoDocumentationButton(String routeName, { Key key })
    : documentationUrl = kDemoDocumentationUrl[routeName],
      assert(
        kDemoDocumentationUrl[routeName] != null,
        'A documentation URL was not specified for demo route $routeName in kAllGalleryDemos',
      ),
      super(key: key);

  final String documentationUrl;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      child: Semantics(
        label: 'API documentation',
        child: const Icon(CupertinoIcons.book),
      ),
      onPressed: () => launch(documentationUrl, forceWebView: true),
    );
  }
}
