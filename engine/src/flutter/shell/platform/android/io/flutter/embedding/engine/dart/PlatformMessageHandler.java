// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.dart;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

/** Handler that receives messages from Dart code. */
public interface PlatformMessageHandler {
  void handleMessageFromDart(
      @NonNull final String channel, @Nullable byte[] message, final int replyId);

  void handlePlatformMessageResponse(int replyId, @Nullable byte[] reply);
}
