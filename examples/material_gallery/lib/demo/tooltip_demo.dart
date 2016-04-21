// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

const String _introText =
  "Tooltips are short identifying messages that briefly appear in response to "
  "a long press. Tooltip messages are also used by services that make Flutter "
  "apps accessible, like screen readers.";

class TooltipDemo extends StatelessWidget {

  static const String routeName = '/tooltip';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Tooltip')
      ),
      body: new Builder(
        builder: (BuildContext context) {
          return new Block(
            children: <Widget>[
              new Text(_introText, style: theme.textTheme.subhead),
              new Row(
                children: <Widget>[
                  new Text('Long press the ', style: theme.textTheme.subhead),
                  new Tooltip(
                    message: 'call icon',
                    child: new Icon(
                      size: 18.0,
                      icon: Icons.call,
                      color: theme.primaryColor
                    )
                  ),
                  new Text(' icon.', style: theme.textTheme.subhead)
                ]
              ),
              new Center(
                child: new IconButton(
                  size: 48.0,
                  icon: Icons.call,
                  color: theme.primaryColor,
                  tooltip: 'place a phone call',
                  onPressed: () {
                    Scaffold.of(context).showSnackBar(new SnackBar(
                       content: new Text('That was an ordinary tap.')
                    ));
                  }
                )
              )
            ]
            .map((Widget widget) {
              return new Padding(
                padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
                child: widget
              );
            })
            .toList()
          );
        }
      )
    );
  }
}
