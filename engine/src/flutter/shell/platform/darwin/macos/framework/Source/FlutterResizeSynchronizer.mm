// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterResizeSynchronizer.h"

#include <mutex>

@interface FlutterResizeSynchronizer () {
  // Counter to detect stale callbacks.
  uint32_t _cookie;

  std::mutex _mutex;

  // Used to block [beginResize:].
  std::condition_variable _condBlockBeginResize;
  // Used to block [requestCommit].
  std::condition_variable _condBlockRequestCommit;

  // Whether a frame was received; the synchronizer doesn't block platform thread during resize
  // until it knows that framework is running and producing frames
  BOOL _receivedFirstFrame;

  // If NO, requestCommit calls are ignored until shouldEnsureSurfaceForSize is called with
  // proper size.
  BOOL _acceptingCommit;

  // Waiting for resize to finish.
  BOOL _waiting;

  // RequestCommit was called and [delegate commit:] must be performed on platform thread.
  BOOL _pendingCommit;

  // Target size for resizing.
  CGSize _newSize;

  // if YES prevents all synchronization
  BOOL _shuttingDown;

  __weak id<FlutterResizeSynchronizerDelegate> _delegate;
}
@end

@implementation FlutterResizeSynchronizer

- (instancetype)initWithDelegate:(id<FlutterResizeSynchronizerDelegate>)delegate {
  if (self = [super init]) {
    _acceptingCommit = YES;
    _delegate = delegate;
  }
  return self;
}

- (void)beginResize:(CGSize)size notify:(dispatch_block_t)notify {
  std::unique_lock<std::mutex> lock(_mutex);
  if (!_delegate) {
    return;
  }

  if (!_receivedFirstFrame || _shuttingDown) {
    // No blocking until framework produces at least one frame
    notify();
    return;
  }

  ++_cookie;

  // from now on, ignore all incoming commits until the block below gets
  // scheduled on raster thread
  _acceptingCommit = NO;

  // let pending commits finish to unblock the raster thread
  _pendingCommit = NO;
  _condBlockBeginResize.notify_all();

  // let the engine send resize notification
  notify();

  _newSize = size;

  _waiting = YES;

  _condBlockRequestCommit.wait(lock, [&] { return _pendingCommit || _shuttingDown; });

  [_delegate resizeSynchronizerFlush:self];
  [_delegate resizeSynchronizerCommit:self];
  _pendingCommit = NO;
  _condBlockBeginResize.notify_all();

  _waiting = NO;
}

- (BOOL)shouldEnsureSurfaceForSize:(CGSize)size {
  std::unique_lock<std::mutex> lock(_mutex);

  if (!_receivedFirstFrame) {
    return YES;
  }

  if (!_acceptingCommit) {
    if (CGSizeEqualToSize(_newSize, size)) {
      _acceptingCommit = YES;
    }
  }
  return _acceptingCommit;
}

- (void)requestCommit {
  std::unique_lock<std::mutex> lock(_mutex);
  if (!_acceptingCommit || _shuttingDown) {
    return;
  }

  _receivedFirstFrame = YES;

  _pendingCommit = YES;
  if (_waiting) {  // BeginResize is in progress, interrupt it and schedule commit call
    _condBlockRequestCommit.notify_all();
    _condBlockBeginResize.wait(lock, [&]() { return !_pendingCommit || _shuttingDown; });
  } else {
    // No resize, schedule commit on platform thread and wait until either done
    // or interrupted by incoming BeginResize
    [_delegate resizeSynchronizerFlush:self];
    dispatch_async(dispatch_get_main_queue(), [self, cookie = _cookie] {
      std::unique_lock<std::mutex> lock(_mutex);
      if (cookie == _cookie) {
        if (_delegate) {
          [_delegate resizeSynchronizerCommit:self];
        }
        _pendingCommit = NO;
        _condBlockBeginResize.notify_all();
      }
    });
    _condBlockBeginResize.wait(lock, [&]() { return !_pendingCommit || _shuttingDown; });
  }
}

- (void)shutdown {
  std::unique_lock<std::mutex> lock(_mutex);
  _shuttingDown = YES;
  _condBlockBeginResize.notify_all();
  _condBlockRequestCommit.notify_all();
}

@end
