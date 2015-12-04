// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class Field extends StatelessComponent {
  Field({
    Key key,
    this.inputKey,
    this.icon,
    this.placeholder
  }) : super(key: key);

  final GlobalKey inputKey;
  final String icon;
  final String placeholder;

  Widget build(BuildContext context) {
    return new Row(<Widget>[
        new Padding(
          padding: const EdgeDims.symmetric(horizontal: 16.0),
          child: new Icon(icon: icon)
        ),
        new Flexible(
          child: new Input(
            key: inputKey,
            placeholder: placeholder
          )
        )
      ]
    );
  }
}

class AddressBookHome extends StatelessComponent {
  Widget buildToolBar(BuildContext context) {
    return new ToolBar(
      right: <Widget>[new IconButton(icon: "navigation/check")]
    );
  }

  Widget buildFloatingActionButton(BuildContext context) {
    return new FloatingActionButton(
      child: new Icon(icon: 'image/photo_camera'),
      backgroundColor: Theme.of(context).accentColor
    );
  }

  static final GlobalKey nameKey = new GlobalKey(debugLabel: 'name field');
  static final GlobalKey phoneKey = new GlobalKey(debugLabel: 'phone field');
  static final GlobalKey emailKey = new GlobalKey(debugLabel: 'email field');
  static final GlobalKey addressKey = new GlobalKey(debugLabel: 'address field');
  static final GlobalKey ringtoneKey = new GlobalKey(debugLabel: 'ringtone field');
  static final GlobalKey noteKey = new GlobalKey(debugLabel: 'note field');

  Widget buildBody(BuildContext context) {
    return new Block(<Widget>[
      new AspectRatio(
        aspectRatio: 16.0 / 9.0,
        child: new Container(
          decoration: new BoxDecoration(backgroundColor: Colors.purple[300])
        )
      ),
      new Field(inputKey: nameKey, icon: "social/person", placeholder: "Name"),
      new Field(inputKey: phoneKey, icon: "communication/phone", placeholder: "Phone"),
      new Field(inputKey: emailKey, icon: "communication/email", placeholder: "Email"),
      new Field(inputKey: addressKey, icon: "maps/place", placeholder: "Address"),
      new Field(inputKey: ringtoneKey, icon: "av/volume_up", placeholder: "Ringtone"),
      new Field(inputKey: noteKey, icon: "content/add", placeholder: "Add note"),
    ]);
  }

  Widget build(BuildContext context) {
    return new Scaffold(
      toolBar: buildToolBar(context),
      body: buildBody(context),
      floatingActionButton: buildFloatingActionButton(context)
    );
  }
}

final ThemeData theme = new ThemeData(
  brightness: ThemeBrightness.light,
  primarySwatch: Colors.teal,
  accentColor: Colors.pinkAccent[100]
);

void main() {
  runApp(new MaterialApp(
    title: 'Address Book',
    theme: theme,
    routes: <String, RouteBuilder>{
      '/': (RouteArguments args) => new AddressBookHome()
    }
  ));
}
