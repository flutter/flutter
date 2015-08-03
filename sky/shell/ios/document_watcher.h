// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NDEBUG
#import <Foundation/Foundation.h>

@interface DocumentWatcher : NSThread
- (instancetype)initWithDocumentPath:(NSString*)path callbackBlock:(void (^)(void))callbackBlock;
- (void)cancel;
@end

#endif // !NDEBUG