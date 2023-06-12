// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/src/summary2/package_bundle_format.dart';

class PackageBundle extends PackageBundleReader {
  PackageBundle.fromBuffer(Uint8List bytes) : super(bytes);
}
