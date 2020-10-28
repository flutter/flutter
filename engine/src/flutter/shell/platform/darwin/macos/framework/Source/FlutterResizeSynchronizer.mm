#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterResizeSynchronizer.h"

#import <mutex>

@interface FlutterResizeSynchronizer () {
  uint32_t cookie;  // counter to detect stale callbacks

  std::mutex mutex;
  std::condition_variable condBlockBeginResize;    // used to block [beginResize:]
  std::condition_variable condBlockRequestCommit;  // used to block [requestCommit]

  bool acceptingCommit;  // if false, requestCommit calls are ignored until
                         // shouldEnsureSurfaceForSize is called with proper size
  bool waiting;          // waiting for resize to finish
  bool pendingCommit;    // requestCommit was called and [delegate commit:] must be performed on
                         // platform thread
  CGSize newSize;        // target size for resizing

  __weak id<FlutterResizeSynchronizerDelegate> delegate;
}
@end

@implementation FlutterResizeSynchronizer

- (instancetype)initWithDelegate:(id<FlutterResizeSynchronizerDelegate>)delegate_ {
  if (self = [super init]) {
    acceptingCommit = true;
    delegate = delegate_;
  }
  return self;
}

- (void)beginResize:(CGSize)size notify:(dispatch_block_t)notify {
  std::unique_lock<std::mutex> lock(mutex);
  if (!delegate) {
    return;
  }

  ++cookie;

  // from now on, ignore all incoming commits until the block below gets
  // scheduled on raster thread
  acceptingCommit = false;

  // let pending commits finish to unblock the raster thread
  pendingCommit = false;
  condBlockBeginResize.notify_all();

  // let the engine send resize notification
  notify();

  newSize = size;

  waiting = true;

  condBlockRequestCommit.wait(lock, [&] { return pendingCommit; });

  [delegate resizeSynchronizerFlush:self];
  [delegate resizeSynchronizerCommit:self];
  pendingCommit = false;
  condBlockBeginResize.notify_all();

  waiting = false;
}

- (bool)shouldEnsureSurfaceForSize:(CGSize)size {
  std::unique_lock<std::mutex> lock(mutex);
  if (!acceptingCommit) {
    if (CGSizeEqualToSize(newSize, size)) {
      acceptingCommit = true;
    }
  }
  return acceptingCommit;
}

- (void)requestCommit {
  std::unique_lock<std::mutex> lock(mutex);
  if (!acceptingCommit) {
    return;
  }

  pendingCommit = true;
  if (waiting) {  // BeginResize is in progress, interrupt it and schedule commit call
    condBlockRequestCommit.notify_all();
    condBlockBeginResize.wait(lock, [&]() { return !pendingCommit; });
  } else {
    // No resize, schedule commit on platform thread and wait until either done
    // or interrupted by incoming BeginResize
    [delegate resizeSynchronizerFlush:self];
    dispatch_async(dispatch_get_main_queue(), [self, cookie_ = cookie] {
      std::unique_lock<std::mutex> lock(mutex);
      if (cookie_ == cookie) {
        if (delegate) {
          [delegate resizeSynchronizerCommit:self];
        }
        pendingCommit = false;
        condBlockBeginResize.notify_all();
      }
    });
    condBlockBeginResize.wait(lock, [&]() { return !pendingCommit; });
  }
}

@end
