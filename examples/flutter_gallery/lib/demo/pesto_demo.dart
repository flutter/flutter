// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'pesto/pesto_home.dart' show PestoHome;

class PestoDemo extends StatelessWidget {
  PestoDemo({ Key key }) : super(key: key);

  static const String routeName = '/pesto';

  @override
  Widget build(BuildContext context) => new PestoHome();
}
