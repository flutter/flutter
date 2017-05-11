// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class ModalBottomSheetDemo extends StatelessWidget {
  static const String routeName = '/material/modal-bottom-sheet';

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: const Text('Modal bottom sheet')),
      body: new Center(
        child: new RaisedButton(
          child: const Text('SHOW BOTTOM SHEET'),
          onPressed: () {
            showModalBottomSheet<Null>(context: context, builder: (BuildContext context) {
              return new Container(
                child: new Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: new Text('This is the modal bottom sheet. Click anywhere to dismiss.',
                    textAlign: TextAlign.center,
                    style: new TextStyle(
                      color: Theme.of(context).accentColor,
                      fontSize: 24.0
                    )
                  )
                )
              );
            });
          }
        )
      )
    );
  }
}
