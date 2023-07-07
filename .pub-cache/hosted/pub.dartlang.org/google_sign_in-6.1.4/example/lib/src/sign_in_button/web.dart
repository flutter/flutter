// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart' as web;

import 'stub.dart';

/// Renders a web-only SIGN IN button.
Widget buildSignInButton({HandleSignInFn? onPressed}) {
  return (GoogleSignInPlatform.instance as web.GoogleSignInPlugin)
      .renderButton();
}
