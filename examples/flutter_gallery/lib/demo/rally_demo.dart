// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_gallery/demo/rally/app.dart';

class RallyDemo extends StatelessWidget {
  const RallyDemo({ Key key }) : super(key: key);

  static const String routeName = '/rally'; // Used by the Gallery app.

  @override
  Widget build(BuildContext context) => RallyApp();
}
