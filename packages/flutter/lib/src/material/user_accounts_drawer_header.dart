// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'debug.dart';

/// A material design [Drawer] header that identifies the app's user.
///
/// The top-most region of a material design drawer with user accounts. The
/// header's [decoration] is used to provide a background.
/// [currentAccountPicture] is the main account picture on the left, while
/// [otherAccountsPictures] are the smaller account pictures on the right.
/// [accountName] and [accountEmail] provide access to the top and bottom rows
/// of the account details in the lower part of the header. When touched, this
/// area triggers [onDetailsPressed] and toggles the dropdown icon on the right.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// See also:
///
///  * [Drawer]
///  * [DrawerItem]
///  * <https://www.google.com/design/spec/patterns/navigation-drawer.html>

class UserAccountsDrawerHeader extends StatefulWidget {
  /// Creates a material design drawer header.
  ///
  /// Requires one of its ancestors to be a [Material] widget.
  UserAccountsDrawerHeader({
    Key key,
    this.decoration,
    this.currentAccountPicture,
    this.otherAccountsPictures,
    this.accountName,
    this.accountEmail,
    this.onDetailsPressed
  }) : super(key: key);

  /// A callback that gets called when the account name/email/dropdown
  /// section is pressed.
  final VoidCallback onDetailsPressed;

  /// Decoration for the main drawer header container useful for applying
  /// backgrounds.
  final BoxDecoration decoration;

  /// A widget placed in the upper-left corner representing the current
  /// account picture. Normally a [CircleAvatar].
  final Widget currentAccountPicture;

  /// A list of widgets that represent the user's accounts. Up to three of them
  /// are arranged in a row in the header's upper-right corner. Normally a list
  /// of [CircleAvatar] widgets.
  final List<Widget> otherAccountsPictures;

  /// A widget placed on the top row of the account details representing
  /// account name.
  final Widget accountName;

  /// A widget placed on the bottom row of the account details representing
  /// account email.
  final Widget accountEmail;

  @override
  _UserAccountsDrawerHeaderState createState() =>
      new _UserAccountsDrawerHeaderState();
}

class _UserAccountsDrawerHeaderState extends State<UserAccountsDrawerHeader> {
  /// Saves whether the account dropdown is open or not.
  bool isOpen = false;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    final List<Widget> otherAccountsPictures = config.otherAccountsPictures ??
        <Widget>[];
    return new DrawerHeader(
      decoration: config.decoration,
      child: new Column(
        children: <Widget>[
          new Flexible(
            child: new Stack(
              children: <Widget>[
                new Positioned(
                  top: 0.0,
                  right: 0.0,
                  child: new Row(
                    children: otherAccountsPictures.take(3).map(
                      (Widget picture) {
                        return new Container(
                          margin: const EdgeInsets.only(left: 16.0),
                          width: 40.0,
                          height: 40.0,
                          child: picture
                        );
                      }
                    ).toList()
                  )
                ),
                new Positioned(
                  top: 0.0,
                  child: new Container(
                    width: 72.0,
                    height: 72.0,
                    child: config.currentAccountPicture
                  )
                )
              ]
            )
          ),
          new Container(
            height: 56.0,
            child: new InkWell(
              onTap: () {
                setState(() {
                  isOpen = !isOpen;
                });
                if (config.onDetailsPressed != null)
                  config.onDetailsPressed();
              },
              child: new Container(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: new Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    new DefaultTextStyle(
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.white
                      ),
                      child: config.accountName
                    ),
                    new Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        new DefaultTextStyle(
                          style: const TextStyle(color: Colors.white),
                          child: config.accountEmail
                        ),
                        new Flexible(
                          child: new Align(
                            alignment: FractionalOffset.centerRight,
                            child: new Icon(
                              isOpen ? Icons.arrow_drop_up :
                                  Icons.arrow_drop_down,
                              color: Colors.white
                            )
                          )
                        )
                      ]
                    )
                  ]
                )
              )
            )
          )
        ]
      )
    );
  }
}
