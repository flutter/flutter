// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'stub.dart';

/// Renders a SIGN IN button that calls `handleSignIn` onclick.
Widget buildSignInButton({HandleSignInFn? onPressed}) {
  return ElevatedButton(
    onPressed: onPressed,
    child: const Text('SIGN IN'),
  );
}
