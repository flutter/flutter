// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show patch;

@patch
bool isBrowserObject(dynamic o) => false;

@patch
Object convertFromBrowserObject(dynamic o) => o;
