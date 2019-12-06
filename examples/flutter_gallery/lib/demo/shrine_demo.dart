// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_gallery/demo/shrine/app.dart';

class ShrineDemo extends StatelessWidget {
  const ShrineDemo({ Key key }) : super(key: key);

  static const String routeName = '/shrine'; // Used by the Gallery app.

  @override
  Widget build(BuildContext context) => ShrineApp();
}
