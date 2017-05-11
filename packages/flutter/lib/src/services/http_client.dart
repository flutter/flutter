// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Create a new [http.Client] object.
///
/// This can be set to a new function to override the default logic for creating
/// HTTP clients, for example so that all logic in the framework that triggers
/// HTTP requests will use the same `UserAgent` header, or so that tests can
/// provide an [http.testing.MockClient].
// TODO(ianh): Fix the link to MockClient once dartdoc has a solution.
ValueGetter<http.Client> createHttpClient = () {
  return new http.Client();
};
