//
// Copyright 2016 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <Foundation/Foundation.h>

#import "Delegate/GREYSurrogateDelegate.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  This is a proxy delegate for NSURLConnectionDelegate which allows us track status of
 *  the connection.
 *
 *  @todo Support NSURLConnectionDownloadDelegate.
 */
@interface GREYNSURLConnectionDelegate : GREYSurrogateDelegate
    <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

/**
 *  @remark init is not an available initializer. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 *  Creates an instance of GREYNSURLConnectionDelegate backed by the provided delegate.
 *
 *  @param originalDelegate The original delegate being proxied.
 *  @return an instance of GREYNSURLConnectionDelegate backed by the original delegate.
 */
- (instancetype)initWithOriginalNSURLConnectionDelegate:(id)originalDelegate;

@end

NS_ASSUME_NONNULL_END
