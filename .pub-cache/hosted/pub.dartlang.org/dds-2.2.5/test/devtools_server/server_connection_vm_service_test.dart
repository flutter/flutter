// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'server_connection_common.dart';

// This test reuses much of the same logic as server_connection_api_test but
// running both in the same process will result in a timeout.
void main() => runTest(useVmService: true);
