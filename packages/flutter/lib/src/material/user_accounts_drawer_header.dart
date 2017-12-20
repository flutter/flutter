// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'debug.dart';
import 'drawer_header.dart';
import 'icons.dart';
import 'ink_well.dart';
import 'material_localizations.dart';
import 'theme.dart';

class _AccountPictures extends StatelessWidget {
  const _AccountPictures({
    Key key,
    this.currentAccountPicture,
    this.otherAccountsPictures,
  }) : super(key: key);

  final Widget currentAccountPicture;
  final List<Widget> otherAccountsPictures;

  @override
  Widget build(BuildContext context) {
    return new Stack(
      children: <Widget>[
        new PositionedDirectional(
          top: 0.0,
          end: 0.0,
          child: new Row(
            children: (otherAccountsPictures ?? <Widget>[]).take(3).map((Widget picture) {
              return new Container(
                margin: const EdgeInsetsDirectional.only(start: 16.0),
                width: 40.0,
                height: 40.0,
                child: new Semantics(
                  container: true,
                  child: picture,
                ),
              );
            }).toList(),
          ),
        ),
        new Positioned(
          top: 0.0,
          child: new SizedBox(
            width: 72.0,
            height: 72.0,
            child: currentAccountPicture,
          ),
        ),
      ],
    );
  }
}

class _AccountDetails extends StatelessWidget {
  const _AccountDetails({
    Key key,
    @required this.accountName,
    @required this.accountEmail,
    this.onTap,
    this.isOpen,
  }) : super(key: key);

  final Widget accountName;
  final Widget accountEmail;
  final VoidCallback onTap;
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    final Widget accountNameLine = accountName == null ? null : new DefaultTextStyle(
      style: theme.primaryTextTheme.body2,
      overflow: TextOverflow.ellipsis,
      child: accountName,
    );
    final Widget accountEmailLine = accountEmail == null ? null : new DefaultTextStyle(
      style: theme.primaryTextTheme.body1,
      overflow: TextOverflow.ellipsis,
      child: accountEmail,
    );

    final List<Widget> rowChildren = <Widget>[];

    if (accountEmailLine != null || accountNameLine != null) {
      rowChildren.add(
        new Expanded(
          flex: 1,
          child: new Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 0.0, 8.0),
            child: new Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: (accountEmailLine != null && accountNameLine != null)
                  ? <Widget>[accountNameLine, accountEmailLine]
                  : <Widget>[accountNameLine ?? accountEmailLine],
            ),
          ),
        ),
      );
    }

    const double kAccountDetailsHeight = 56.0;

    if (onTap != null) {
      rowChildren.add(
        new InkWell(
          onTap: onTap,
          child: new Semantics(
            button: true,
            child: new SizedBox(
              height: kAccountDetailsHeight,
              width: kAccountDetailsHeight,  // make it a square
              child: new Center(
                child: new Icon(
                  isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: Colors.white,
                  semanticLabel: isOpen
                    ? localizations.hideAccountsLabel
                    : localizations.showAccountsLabel,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return new SizedBox(
      height: kAccountDetailsHeight,
      child: new Row(
        children: rowChildren,
      ),
    );
  }
}

/// A material design [Drawer] header that identifies the app's user.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// See also:
///
///  * [DrawerHeader], for a drawer header that doesn't show user accounts
///  * <https://material.google.com/patterns/navigation-drawer.html>
class UserAccountsDrawerHeader extends StatefulWidget {
  /// Creates a material design drawer header.
  ///
  /// Requires one of its ancestors to be a [Material] widget.
  const UserAccountsDrawerHeader({
    Key key,
    this.decoration,
    this.margin: const EdgeInsets.only(bottom: 8.0),
    this.currentAccountPicture,
    this.otherAccountsPictures,
    @required this.accountName,
    @required this.accountEmail,
    this.onDetailsPressed,
  }) : super(key: key);

  /// The header's background. If decoration is null then a [BoxDecoration]
  /// with its background color set to the current theme's primaryColor is used.
  final Decoration decoration;

  /// The margin around the drawer header.
  final EdgeInsetsGeometry margin;

  /// A widget placed in the upper-left corner that represents the current
  /// user's account. Normally a [CircleAvatar].
  final Widget currentAccountPicture;

  /// A list of widgets that represent the current user's other accounts.
  /// Up to three of these widgets will be arranged in a row in the header's
  /// upper-right corner. Normally a list of [CircleAvatar] widgets.
  final List<Widget> otherAccountsPictures;

  /// A widget that represents the user's current account name. It is
  /// displayed on the left, below the [currentAccountPicture].
  final Widget accountName;

  /// A widget that represents the email address of the user's current account.
  /// It is displayed on the left, below the [accountName].
  final Widget accountEmail;

  /// A callback that is called when the horizontal area which contains the
  /// [accountName] and [accountEmail] is tapped.
  final VoidCallback onDetailsPressed;

  @override
  _UserAccountsDrawerHeaderState createState() => new _UserAccountsDrawerHeaderState();
}

class _UserAccountsDrawerHeaderState extends State<UserAccountsDrawerHeader> {
  bool _isOpen = false;

  void _handleDetailsPressed() {
    setState(() {
      _isOpen = !_isOpen;
    });
    widget.onDetailsPressed();
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    return new DrawerHeader(
      decoration: widget.decoration ?? new BoxDecoration(
        color: Theme.of(context).primaryColor,
      ),
      margin: widget.margin,
      padding: EdgeInsets.zero,
      child: new SafeArea(
        bottom: false,
        child: new Semantics(
          container: true,
          label: 'Signed in',
          child: new Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              new Expanded(
                child: new Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
                  child: new _AccountPictures(
                    currentAccountPicture: widget.currentAccountPicture,
                    otherAccountsPictures: widget.otherAccountsPictures,
                  ),
                ),
              ),
              new _AccountDetails(
                accountName: widget.accountName,
                accountEmail: widget.accountEmail,
                isOpen: _isOpen,
                onTap: widget.onDetailsPressed == null ? null : _handleDetailsPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
