// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

const String kPackagesFileName = '.packages';

String get globalPackagesPath => _globalPackagesPath ?? kPackagesFileName;

set globalPackagesPath(String value) {
  _globalPackagesPath = value;
}

bool get isUsingCustomPackagesPath => _globalPackagesPath != null;

String _globalPackagesPath;
