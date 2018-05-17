// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
              return new Semantics(
                explicitChildNodes: true,
                child: new Container(
                  margin: const EdgeInsetsDirectional.only(start: 16.0),
                  width: 40.0,
                  height: 40.0,
                  child: picture
                ),
              );
            }).toList(),
          ),
        ),
        new Positioned(
          top: 0.0,
          child: new Semantics(
            explicitChildNodes: true,
            child: new SizedBox(
              width: 72.0,
              height: 72.0,
              child: currentAccountPicture
            ),
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
    assert(debugCheckHasDirectionality(context));

    final ThemeData theme = Theme.of(context);
    final List<Widget> children = <Widget>[];

    if (accountName != null) {
      final Widget accountNameLine = new LayoutId(
        id: _AccountDetailsLayout.accountName,
        child: new Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: new DefaultTextStyle(
            style: theme.primaryTextTheme.body2,
            overflow: TextOverflow.ellipsis,
            child: accountName,
          ),
        ),
      );
      children.add(accountNameLine);
    }

    if (accountEmail != null) {
      final Widget accountEmailLine = new LayoutId(
        id: _AccountDetailsLayout.accountEmail,
        child: new Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: new DefaultTextStyle(
            style: theme.primaryTextTheme.body1,
            overflow: TextOverflow.ellipsis,
            child: accountEmail,
          ),
        ),
      );
      children.add(accountEmailLine);
    }

    if (onTap != null) {
      final MaterialLocalizations localizations = MaterialLocalizations.of(context);
      final Widget dropDownIcon = new LayoutId(
        id: _AccountDetailsLayout.dropdownIcon,
        child: new Semantics(
          container: true,
          button: true,
          onTap: onTap,
          child: new SizedBox(
            height: _kAccountDetailsHeight,
            width: _kAccountDetailsHeight,
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
      );
      children.add(dropDownIcon);
    }

    Widget accountDetails = new CustomMultiChildLayout(
      delegate: new _AccountDetailsLayout(
        textDirection: Directionality.of(context),
      ),
      children: children,
    );

    if (onTap != null) {
      accountDetails = new InkWell(
        onTap: onTap,
        child: accountDetails,
        excludeFromSemantics: true,
      );
    }

    return new SizedBox(
      height: _kAccountDetailsHeight,
      child: accountDetails,
    );
  }
}

const double _kAccountDetailsHeight = 56.0;

class _AccountDetailsLayout extends MultiChildLayoutDelegate {

  _AccountDetailsLayout({ @required this.textDirection });

  static const String accountName = 'accountName';
  static const String accountEmail = 'accountEmail';
  static const String dropdownIcon = 'dropdownIcon';

  final TextDirection textDirection;

  @override
  void performLayout(Size size) {
    Size iconSize;
    if (hasChild(dropdownIcon)) {
      // place the dropdown icon in bottom right (LTR) or bottom left (RTL)
      iconSize = layoutChild(dropdownIcon, new BoxConstraints.loose(size));
      positionChild(dropdownIcon, _offsetForIcon(size, iconSize));
    }

    final String bottomLine = hasChild(accountEmail) ? accountEmail : (hasChild(accountName) ? accountName : null);

    if (bottomLine != null) {
      final Size constraintSize = iconSize == null ? size : size - new Offset(iconSize.width, 0.0);
      iconSize ??= const Size(_kAccountDetailsHeight, _kAccountDetailsHeight);

      // place bottom line center at same height as icon center
      final Size bottomLineSize = layoutChild(bottomLine, new BoxConstraints.loose(constraintSize));
      final Offset bottomLineOffset = _offsetForBottomLine(size, iconSize, bottomLineSize);
      positionChild(bottomLine, bottomLineOffset);

      // place account name above account email
      if (bottomLine == accountEmail && hasChild(accountName)) {
        final Size nameSize = layoutChild(accountName, new BoxConstraints.loose(constraintSize));
        positionChild(accountName, _offsetForName(size, nameSize, bottomLineOffset));
      }
    }
  }

  @override
  bool shouldRelayout(MultiChildLayoutDelegate oldDelegate) => true;

  Offset _offsetForIcon(Size size, Size iconSize) {
    switch (textDirection) {
      case TextDirection.ltr:
        return new Offset(size.width - iconSize.width, size.height - iconSize.height);
      case TextDirection.rtl:
        return new Offset(0.0, size.height - iconSize.height);
    }
    assert(false, 'Unreachable');
    return null;
  }

  Offset _offsetForBottomLine(Size size, Size iconSize, Size bottomLineSize) {
    final double y = size.height - 0.5 * iconSize.height - 0.5 * bottomLineSize.height;
    switch (textDirection) {
      case TextDirection.ltr:
        return new Offset(0.0, y);
      case TextDirection.rtl:
        return new Offset(size.width - bottomLineSize.width, y);
    }
    assert(false, 'Unreachable');
    return null;
  }

  Offset _offsetForName(Size size, Size nameSize, Offset bottomLineOffset) {
    final double y = bottomLineOffset.dy - nameSize.height;
    switch (textDirection) {
      case TextDirection.ltr:
        return new Offset(0.0, y);
      case TextDirection.rtl:
        return new Offset(size.width - nameSize.width, y);
    }
    assert(false, 'Unreachable');
    return null;
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
    this.onDetailsPressed
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
    return new Semantics(
      container: true,
      label: MaterialLocalizations.of(context).signedInLabel,
      child: new DrawerHeader(
        decoration: widget.decoration ?? new BoxDecoration(
          color: Theme.of(context).primaryColor,
        ),
        margin: widget.margin,
        padding: const EdgeInsetsDirectional.only(top: 16.0, start: 16.0),
        child: new SafeArea(
          bottom: false,
          child: new Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              new Expanded(
                child: new Padding(
                  padding: const EdgeInsetsDirectional.only(end: 16.0),
                  child: new _AccountPictures(
                    currentAccountPicture: widget.currentAccountPicture,
                    otherAccountsPictures: widget.otherAccountsPictures,
                  ),
                )
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
