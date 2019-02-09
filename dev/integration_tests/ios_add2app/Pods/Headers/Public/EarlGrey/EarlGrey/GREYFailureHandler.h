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

@class GREYFrameworkException;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Protocol for handling failures (such as failure of actions and assertions) raised by EarlGrey.
 */
@protocol GREYFailureHandler<NSObject>

/**
 *  Called by the framework to raise an exception.
 *
 *  @param exception The exception to be handled.
 *  @param details   Extra information about the failure.
 */
- (void)handleException:(GREYFrameworkException *)exception details:(NSString *)details;

@optional

/**
 *  Sets the file name and line number of operation that caused the failure.
 *
 *  @param fileName   The name of the file where the error happened.
 *  @param lineNumber The line number in the file that caused the error.
 */
- (void)setInvocationFile:(NSString *)fileName andInvocationLine:(NSUInteger)lineNumber;

@end

NS_ASSUME_NONNULL_END
