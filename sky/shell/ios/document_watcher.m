// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#ifndef NDEBUG
#import "document_watcher.h"

@interface DocumentWatcher ()

@property(nonatomic, readonly) NSDate* lastModifiedDate;
@property (copy) void (^callbackBlock)(void);

@end

@implementation DocumentWatcher {
  NSString* _documentPath;
  NSTimer* _timer;
  CFRunLoopRef _loop;
}

@synthesize lastModifiedDate = _lastModifiedDate;

- (instancetype)initWithDocumentPath:(NSString*)path callbackBlock:(void (^)(void))callbackBlock {
  self = [super init];

  if (self) {
    _documentPath = path;
    self.callbackBlock = callbackBlock;

    [self start];
  }

  return self;
}

- (void)main {
  [self onCheck:nil];
  _timer = [[NSTimer scheduledTimerWithTimeInterval:1.0
                                             target:self
                                           selector:@selector(onCheck:)
                                           userInfo:nil
                                            repeats:YES] retain];
  while (!self.isCancelled) {
    _loop = CFRunLoopGetCurrent();
    CFRunLoopRunInMode(kCFRunLoopDefaultMode,
                       [[NSDate distantFuture] timeIntervalSinceNow], YES);
  }
}

- (void)_setLastModifiedDate:(NSDate*)lastModifiedDate path:(NSString*)path {
  if ([_lastModifiedDate isEqualToDate:lastModifiedDate]) {
    return;
  }

  [_lastModifiedDate release];
  _lastModifiedDate = [lastModifiedDate retain];

  if (_lastModifiedDate == nil && lastModifiedDate == nil) {
    return;
  }

  dispatch_async(dispatch_get_main_queue(), self.callbackBlock);
}

- (void)onCheck:(id)sender {
  if (![[NSFileManager defaultManager] fileExistsAtPath:_documentPath]) {
    return;
  }

  NSError* error = nil;
  NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:_documentPath
                                                                              error:&error];
  if (error != nil) {
    NSLog(@"[DocumentWatcher onCheck]: error reading attributes for path %@: %@", _documentPath, error);
    return;
  }

  [self _setLastModifiedDate:attributes.fileModificationDate path:_documentPath];
}

- (void)cancel {
  [_timer invalidate];
  [_timer release];
  _timer = nil;

  if (_loop) {
    CFRunLoopWakeUp(_loop);
    _loop = NULL;
  }

  [super cancel];
}

- (void)dealloc {
  [_documentPath release];
  [_lastModifiedDate release];
  [super dealloc];
}

@end
#endif // !NDEBUG