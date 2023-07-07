// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "QueueUtils.h"

const char *FLTCaptureSessionQueueSpecific = "capture_session_queue";

void FLTEnsureToRunOnMainQueue(dispatch_block_t block) {
  if (!NSThread.isMainThread) {
    dispatch_async(dispatch_get_main_queue(), block);
  } else {
    block();
  }
}
