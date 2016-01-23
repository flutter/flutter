// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

final GlobalKey _kNameKey = new GlobalKey(debugLabel: 'name field');
final GlobalKey _kPhoneKey = new GlobalKey(debugLabel: 'phone field');
final GlobalKey _kEmailKey = new GlobalKey(debugLabel: 'email field');
final GlobalKey _kAddressKey = new GlobalKey(debugLabel: 'address field');
final GlobalKey _kRingtoneKey = new GlobalKey(debugLabel: 'ringtone field');
final GlobalKey _kNoteKey = new GlobalKey(debugLabel: 'note field');

class AddressBookHome extends StatelessComponent {
  Widget build(BuildContext context) {
    return new Scaffold(
      toolBar: new ToolBar(
        center: new Text('Edit contact'),
        right: <Widget>[
          new IconButton(icon: 'navigation/check')
        ]
      ),
      body: new Block(
        children: <Widget>[
          new AspectRatio(
            aspectRatio: 16.0 / 9.0,
            child: new Container(
              decoration: new BoxDecoration(backgroundColor: Colors.purple[300])
            )
          ),
          new Input(key: _kNameKey, icon: 'social/person', labelText: 'Name', style: Typography.black.display1),
          new Input(key: _kPhoneKey, icon: 'communication/phone', hintText: 'Phone'),
          new Input(key: _kEmailKey, icon: 'communication/email', hintText: 'Email'),
          new Input(key: _kAddressKey, icon: 'maps/place', hintText: 'Address'),
          new Input(key: _kRingtoneKey, icon: 'av/volume_up', hintText: 'Ringtone'),
          new Input(key: _kNoteKey, icon: 'content/add', hintText: 'Add note'),
        ]
      ),
      floatingActionButton: new FloatingActionButton(
        child: new Icon(icon: 'image/photo_camera')
      )
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
