// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../gallery/demo.dart';

class ModalBottomSheetDemo extends StatelessWidget {
  static const String routeName = '/material/modal-bottom-sheet';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modal bottom sheet'),
        actions: <Widget>[MaterialDemoDocumentationButton(routeName)],
      ),
      body: Center(
        child: RaisedButton(
          child: const Text('SHOW BOTTOM SHEET'),
          onPressed: () {
            showModalBottomSheet<void>(context: context, builder: (BuildContext context) {
              return Container(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text('This is the modal bottom sheet. Tap anywhere to dismiss.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
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
