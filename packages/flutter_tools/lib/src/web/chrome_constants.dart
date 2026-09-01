// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Flags passed to Chrome to disable GCM (Google Cloud Messaging) and MCS
/// (Mobile Connection Server) background network registration calls and
/// prevent deprecation error logs.
const kGcmDisabledFlags = <String>[
  '--disable-features=GCM',
  '--gcm-checkin-url=http://127.0.0.1',
  '--gcm-registration-url=http://127.0.0.1',
  '--gcm-mcs-endpoint=127.0.0.1:0',
];
