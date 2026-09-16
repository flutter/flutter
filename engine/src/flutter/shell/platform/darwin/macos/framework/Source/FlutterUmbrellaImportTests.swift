// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import FlutterMacOS

// This file is to ensure that Flutter.framework can be cleanly imported
// by Swift clients, and certain Symbols are visible to Swift clients.

public func verifyFlutterCodecSymbols() {
  _ = FlutterBinaryCodec.sharedInstance()
  _ = FlutterStringCodec.sharedInstance()
  _ = FlutterJSONMessageCodec.sharedInstance()
  _ = FlutterJSONMethodCodec.sharedInstance()
}
