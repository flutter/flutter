// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CupertinoProgressIndicatorDemo extends StatelessWidget {
  static const String routeName = '/cupertino/progress_indicator';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cupertino Activity Indicator'),
      ),
      body: const Center(
        child: CupertinoActivityIndicator(),
      ),
    );
  }
}
