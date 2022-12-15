#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterThreadSynchronizer.h"
#import "fml/synchronization/waitable_event.h"

#import <QuartzCore/QuartzCore.h>

#include <mutex>
#include <vector>

@interface FlutterThreadSynchronizer () {
  std::mutex _mutex;
  BOOL _shuttingDown;
  CGSize _contentSize;
  std::vector<dispatch_block_t> _scheduledBlocks;

  BOOL _beginResizeWaiting;

  // Used to block [beginResize:].
  std::condition_variable _condBlockBeginResize;
}

@end

@implementation FlutterThreadSynchronizer

- (void)drain {
  assert([NSThread isMainThread]);

  [CATransaction begin];
  [CATransaction setDisableActions:YES];
  for (dispatch_block_t block : _scheduledBlocks) {
    block();
  }
  [CATransaction commit];
  _scheduledBlocks.clear();
}

- (void)blockUntilFrameAvailable {
  std::unique_lock<std::mutex> lock(_mutex);

  _beginResizeWaiting = YES;

  while (CGSizeEqualToSize(_contentSize, CGSizeZero) && !_shuttingDown) {
    _condBlockBeginResize.wait(lock);
    [self drain];
  }

  _beginResizeWaiting = NO;
}

- (void)beginResize:(CGSize)size notify:(nonnull dispatch_block_t)notify {
  std::unique_lock<std::mutex> lock(_mutex);

  if (CGSizeEqualToSize(_contentSize, CGSizeZero) || _shuttingDown) {
    // No blocking until framework produces at least one frame
    notify();
    return;
  }

  [self drain];

  notify();

  _contentSize = CGSizeMake(-1, -1);

  _beginResizeWaiting = YES;

  while (!CGSizeEqualToSize(_contentSize, size) &&  //
         !CGSizeEqualToSize(_contentSize, CGSizeZero) && !_shuttingDown) {
    _condBlockBeginResize.wait(lock);
    [self drain];
  }

  _beginResizeWaiting = NO;
}

- (void)performCommit:(CGSize)size notify:(nonnull dispatch_block_t)notify {
  fml::AutoResetWaitableEvent event;
  {
    std::unique_lock<std::mutex> lock(_mutex);
    fml::AutoResetWaitableEvent& e = event;
    _scheduledBlocks.push_back(^{
      notify();
      _contentSize = size;
      e.Signal();
    });
    if (_beginResizeWaiting) {
      _condBlockBeginResize.notify_all();
    } else {
      dispatch_async(dispatch_get_main_queue(), ^{
        std::unique_lock<std::mutex> lock(_mutex);
        [self drain];
      });
    }
  }
  event.Wait();
}

- (void)shutdown {
  std::unique_lock<std::mutex> lock(_mutex);
  _shuttingDown = YES;
  _condBlockBeginResize.notify_all();
  [self drain];
}

@end
