// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

typedef Future<String> UpdateUrlFetcher();

class Updater extends StatefulWidget {
  const Updater({ @required this.updateUrlFetcher, this.child, Key key })
    : assert(updateUrlFetcher != null),
      super(key: key);

  final UpdateUrlFetcher updateUrlFetcher;
  final Widget child;

  @override
  State createState() => new UpdaterState();
}

class UpdaterState extends State<Updater> {
  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  static DateTime _lastUpdateCheck;
  Future<Null> _checkForUpdates() async {
    // Only prompt once a day
    if (_lastUpdateCheck != null &&
        new DateTime.now().difference(_lastUpdateCheck) < const Duration(days: 1)) {
      return; // We already checked for updates recently
    }
    _lastUpdateCheck = new DateTime.now();

    final String updateUrl = await widget.updateUrlFetcher();
    if (updateUrl != null) {
      final bool wantsUpdate = await showDialog(context: context, builder: _buildDialog);
      if (wantsUpdate != null && wantsUpdate)
        launch(updateUrl);
    }
  }

  Widget _buildDialog(BuildContext _) {
    final ThemeData theme = Theme.of(context);
    final TextStyle dialogTextStyle =
        theme.textTheme.subhead.copyWith(color: theme.textTheme.caption.color);
    return new AlertDialog(
      title: const Text('Update Flutter Gallery?'),
      content: new Text('A newer version is available.', style: dialogTextStyle),
      actions: <Widget>[
        new FlatButton(
            child: const Text('NO THANKS'),
            onPressed: () {
              Navigator.pop(context, false);
            }),
        new FlatButton(
            child: const Text('UPDATE'),
            onPressed: () {
              Navigator.pop(context, true);
            }),
      ]);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
