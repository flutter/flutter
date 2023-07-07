// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';

/// The type of the onClick callback for the (mobile) Sign In Button.
typedef HandleSignInFn = Future<void> Function();

/// Renders a SIGN IN button that (maybe) calls the `handleSignIn` onclick.
Widget buildSignInButton({HandleSignInFn? onPressed}) {
  return Container();
}
