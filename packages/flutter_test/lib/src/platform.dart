// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

/// Whether the test is running in a Travis CI environment.
bool get runningOnTravis => Platform.environment['TRAVIS'] == 'true';
