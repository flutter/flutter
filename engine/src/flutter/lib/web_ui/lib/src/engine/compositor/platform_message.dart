// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
part of engine;

class PlatformMessage {
  final String channel;
  final ByteData data;
  final PlatformMessageResponse response;

  PlatformMessage(this.channel, this.data, this.response);
}

class PlatformMessageResponse {
  void complete(Uint8List data) {}
  void completeEmpty() {}
}
