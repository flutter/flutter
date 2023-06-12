// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

export '../utils.dart';

/// The test server's echo URL.
Uri get echoUrl =>
    Uri.parse('${window.location.protocol}//${window.location.host}/echo');
